//
//  NowPlayingController.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

import Combine
import AppKit
import Foundation

class NowPlayingController: ObservableObject, MediaControllerProtocol {
    
    // MARK: - Properties
    @Published private(set) var playbackState: PlaybackState = .init( bundleIdentifier: "com.apple.Music" )
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { $playbackState.eraseToAnyPublisher() }
    
    var supportsVolumeControls: Bool {
        let bundleId = playbackState.bundleIdentifier
        return bundleId == "com.apple.Music" || bundleId == "com.spotify.client"
    }
    
    var supportsFavorite: Bool {
        let bundleId = playbackState.bundleIdentifier
        return bundleId == "com.apple.Music"
    }
    
    private var lastMusicItem: (title: String, artist: String, album: String, duration: TimeInterval, artworkData: Data?)?
    
    // MARK: - MediaRemote Functions
    private let mediaRemoteBundle: CFBundle
    private let MRMediaRemoteSendCommandFunction: @convention(c) (Int, AnyObject?) -> Void
    private let MRMediaRemoteSetElapsedTimeFunction: @convention(c) (Double) -> Void
    private let MRMediaRemoteSetShuffleModeFunction: @convention(c) (Int) -> Void
    private let MRMediaRemoteSetRepeatModeFunction: @convention(c) (Int) -> Void
    
    private var process: Process?
    private var pipeHandler: JSONLinesPipeHandler?
    private var streamTask: Task<Void, Never>?
    
    // MARK: - Init
    init?() {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
              let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString),
              let MRMediaRemoteSetElapsedTimePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetElapsedTime" as CFString),
              let MRMediaRemoteSetShuffleModePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetShuffleMode" as CFString),
              let MRMediaRemoteSetRepeatModePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetRepeatMode" as CFString)
        else { return nil }
        
        mediaRemoteBundle = bundle
        
        MRMediaRemoteSendCommandFunction = unsafeBitCast(
            MRMediaRemoteSendCommandPointer, to: (@convention(c) (Int, AnyObject?) -> Void).self)
        MRMediaRemoteSetElapsedTimeFunction = unsafeBitCast(
            MRMediaRemoteSetElapsedTimePointer, to: (@convention(c) (Double) -> Void).self)
        MRMediaRemoteSetShuffleModeFunction = unsafeBitCast(
            MRMediaRemoteSetShuffleModePointer, to: (@convention(c) (Int) -> Void).self)
        MRMediaRemoteSetRepeatModeFunction = unsafeBitCast(
            MRMediaRemoteSetRepeatModePointer, to: (@convention(c) (Int) -> Void).self)
        
        Task { await setupNowPlayingObserver() }
    }
    
    deinit {
        streamTask?.cancel()
        
        if let pipeHandler = self.pipeHandler {
            Task { await pipeHandler.close() }
        }
        
        if let process = self.process {
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
        }
        
        self.process = nil
        self.pipeHandler = nil
    }
    
    // MARK: - Protocol Implementation
    
    func play() async {
        MRMediaRemoteSendCommandFunction(0, nil)
    }
    
    func pause() async {
        MRMediaRemoteSendCommandFunction(1, nil)
    }
    
    func togglePlay() async {
        MRMediaRemoteSendCommandFunction(2, nil)
    }
    
    func next() async {
        MRMediaRemoteSendCommandFunction(4, nil)
    }
    
    func previous() async {
        MRMediaRemoteSendCommandFunction(5, nil)
    }
    
    func seek(to time: TimeInterval) async {
        MRMediaRemoteSetElapsedTimeFunction(time)
    }
    
    func isActive() -> Bool {
        return true
    }
    
    func toggleShuffle() async {
        MRMediaRemoteSetShuffleModeFunction(playbackState.isShuffled ? 1 : 3)
        playbackState.isShuffled.toggle()
    }
    
    func toggleRepeat() async {
        let newRepeatMode = (playbackState.repeatMode == .off) ? 3 : (playbackState.repeatMode.rawValue - 1)
        playbackState.repeatMode = RepeatMode(rawValue: newRepeatMode) ?? .off
        MRMediaRemoteSetRepeatModeFunction(newRepeatMode)
    }
    
    func setVolume(to level: Double) async {
        let clampedLevel = max(0, min(1, level))
        let volumePercentage = Int(clampedLevel * 100)
        
        let bundleId = playbackState.bundleIdentifier
        if !bundleId.isEmpty {
            if bundleId == "com.apple.Music" {
                let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
                if !runningApps.isEmpty {
                    let script = "tell application \"Music\" to set sound volume to \(volumePercentage)"
                    try? await AppleScriptHelper.executeVoid(script)
                }
            } else if bundleId == "com.spotify.client" {
                let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
                if !runningApps.isEmpty {
                    let script = "tell application \"Spotify\" to set sound volume to \(volumePercentage)"
                    try? await AppleScriptHelper.executeVoid(script)
                }
            }
        }
        
        playbackState.volume = clampedLevel
    }
    
    func setFavorite(_ favorite: Bool) async {
        let bundleId = playbackState.bundleIdentifier
        
        if bundleId == "com.apple.Music" {
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")
            if !runningApps.isEmpty {
                let script = """
                        tell application "Music"
                            try
                                set favorited of current track to \(favorite ? "true" : "false")
                            end try
                        end tell
                        """
                try? await AppleScriptHelper.executeVoid(script)
            }
        }
        
        try? await Task.sleep(for: .milliseconds(150))
        await updatePlaybackInfo()
    }
    
    func updatePlaybackInfo() async {
        await fetchFavoriteStateIfSupported()
    }
    
    // MARK: - Setup Methods
    private func setupNowPlayingObserver() async {
        let process = Process()
        guard
            let scriptURL = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "pl"),
            let frameworkPath = Bundle.main.privateFrameworksPath?.appending("/MediaRemoteAdapter.framework")
        else {
            assertionFailure("Could not find mediaremote-adapter.pl script or MediaRemoteAdapter.framework in the app bundle.")
            return
        }
        
        Logger.log("Launching mediaremote-adapter.pl script at path: \(scriptURL.path) - \(frameworkPath)", type: .media)
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [scriptURL.path, frameworkPath, "stream"]
        
        let pipeHandler = JSONLinesPipeHandler()
        process.standardOutput = await pipeHandler.getPipe()
        
        self.process = process
        self.pipeHandler = pipeHandler
        
        do {
            try process.run()
            streamTask = Task { [weak self] in
                await self?.processJSONStream()
            }
        } catch {
            assertionFailure("Failed to launch mediaremote-adapter.pl script: \(error)")
        }
    }
    
    private func processJSONStream() async {
        guard let pipeHandler = self.pipeHandler else { return }
        
        await pipeHandler.readJSONLines(as: NowPlayingUpdate.self) { [weak self] update in
            await self?.handleAdapterUpdate(update)
        }
        
    }
    
    // MARK: - Update Methods
    private func handleAdapterUpdate(_ update: NowPlayingUpdate) async {
        let payload = update.payload
        let diff = update.diff ?? false
        
        var newPlaybackState = PlaybackState(bundleIdentifier: playbackState.bundleIdentifier)
        
        newPlaybackState.title = payload.title ?? (diff ? self.playbackState.title : "")
        newPlaybackState.artist = payload.artist ?? (diff ? self.playbackState.artist : "")
        newPlaybackState.album = payload.album ?? (diff ? self.playbackState.album : "")
        newPlaybackState.duration = payload.duration ?? (diff ? self.playbackState.duration : 0)
        
        if let elapsedTime = payload.elapsedTime {
            newPlaybackState.currentTime = elapsedTime
        } else if diff {
            if payload.playing == false {
                let timeSinceLastUpdate = Date().timeIntervalSince(self.playbackState.lastUpdate)
                newPlaybackState.currentTime = self.playbackState.currentTime + (timeSinceLastUpdate * self.playbackState.playbackRate)
            } else {
                newPlaybackState.currentTime = self.playbackState.currentTime
            }
        } else {
            newPlaybackState.currentTime = 0
        }
        
        if let shuffleMode = payload.shuffleMode {
            newPlaybackState.isShuffled = shuffleMode != 1
        } else if !diff {
            newPlaybackState.isShuffled = false
        } else {
            newPlaybackState.isShuffled = self.playbackState.isShuffled
        }
        
        if let repeatModeValue = payload.repeatMode {
            newPlaybackState.repeatMode = RepeatMode(rawValue: repeatModeValue) ?? .off
        } else if !diff {
            newPlaybackState.repeatMode = .off
        } else {
            newPlaybackState.repeatMode = self.playbackState.repeatMode
        }
        
        if let artworkDataString = payload.artworkData {
            newPlaybackState.artwork = Data(base64Encoded: artworkDataString.trimmingCharacters(in: .whitespacesAndNewlines))
        } else if !diff {
            newPlaybackState.artwork = nil
        }
        
        if let dateString = payload.timestamp,
           let date = ISO8601DateFormatter().date(from: dateString) {
            newPlaybackState.lastUpdate = date
        } else if !diff {
            newPlaybackState.lastUpdate = Date()
        } else {
            newPlaybackState.lastUpdate = self.playbackState.lastUpdate
        }
        
        newPlaybackState.playbackRate = payload.playbackRate ?? (diff ? self.playbackState.playbackRate : 1.0)
        newPlaybackState.isPlaying = payload.playing ?? (diff ? self.playbackState.isPlaying : false)
        newPlaybackState.bundleIdentifier = (
            payload.parentApplicationBundleIdentifier ??
            payload.bundleIdentifier ??
            (diff ? self.playbackState.bundleIdentifier : "")
        )
        
        newPlaybackState.volume = payload.volume ?? (diff ? self.playbackState.volume : 0.5)
        
        self.playbackState = newPlaybackState
    }
    
    private func fetchFavoriteStateIfSupported() async {
        let bundleId = playbackState.bundleIdentifier
        
        if bundleId == "com.apple.Music" {
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
            guard !runningApps.isEmpty else { return }
            
            let script = """
            tell application "Music"
                if it is running then
                    try
                        return favorited of current track
                    on error
                        return false
                    end try
            end tell    
            """
            
            if let result = try? await AppleScriptHelper.execute(script) {
                var updated = self.playbackState
                updated.isFavorite = result.booleanValue
                self.playbackState = updated
            }
        }
    }
}

struct NowPlayingUpdate: Codable {
    let payload: NowPlayingPlayload
    let diff: Bool?
}

struct NowPlayingPlayload: Codable {
    let title: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let elapsedTime: Double?
    let shuffleMode: Int?
    let repeatMode: Int?
    let artworkData: String?
    let timestamp: String?
    let playbackRate: Double?
    let playing: Bool?
    let parentApplicationBundleIdentifier: String?
    let bundleIdentifier: String?
    let volume: Double?
}
