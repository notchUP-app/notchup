//
//  MusicManager.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 19/10/24.
//

import SwiftUI
import Combine
import AppKit
import Defaults

let defaultImage: NSImage = .init(
    systemSymbolName: "heart.fill",
    accessibilityDescription: "Album artwork"
)!

class MusicManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var debounceToggle: DispatchWorkItem?
    private var viewModel: NotchViewModel
    private var lastMusicItem: (title: String, artist: String, album: String, artworkData: Data?)?
    private var isCurrentlyPlaying: Bool = false
    
    @Published var songTitle: String = ""
    @Published var songArtist: String = ""
    @Published var songAlbum: String = ""
    @Published var songArtwork: NSImage = defaultImage
    @Published var isPlaying: Bool = false
    @Published var avgColor: NSColor = .white
    @Published var isPlayerIdle: Bool = true
    @Published var bundleIdentifier: String = "com.apple.Music"
    @Published var musicToggledManually: Bool = false
    
    @Published var lastUpdated: Date = .init()
    @Published var animations: NotchAnimations = .init()
    @Published var playbackManager = PlaybackManager()
    @ObservedObject var detector: FullScreenMediaDetector
    var nowPlaying: NowPlaying
    
    private let mediaRemoteBundle: CFBundle
    private let MRMediaRemoteGetNowPlayingInfo: @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) ->  Void
    private let MRMediaRemoteRegisterForNowPlayingNotifications: @convention(c) (DispatchQueue) -> Void
    
    deinit {
        debounceToggle?.cancel()
        cancellables.removeAll()
    }
    
    init?(viewModel: NotchViewModel) {
        self.viewModel = viewModel
        _detector = ObservedObject(wrappedValue: FullScreenMediaDetector())
        nowPlaying = NowPlaying()
        
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
              let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString),
              let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString)
        else {
            print("Failed to load MediaRemote.framework or get function pointers")
            return nil
        }
        
        self.mediaRemoteBundle = bundle
        self.MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void).self)
        self.MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: (@convention(c) (DispatchQueue) -> Void).self)
        
        
    }
    
    private func observeNotification(name: String, handler: @escaping () -> Void) {
        NotificationCenter.default.publisher(for: NSNotification.Name(name))
            .sink { _ in handler() }
            .store(in: &cancellables)
    }
    
    private func observeDistributedNotification(name: String, handler: @escaping () -> Void) {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(name),
            object: nil,
            queue: .main
        ) { _ in handler() }
    }
    
    private func setupNowPlayingObserver() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        
        observeNotification(name: "kMRMediaRemoteNowPlayingInfoDidChangeNotification") { [weak self] in
            self?.fetchNowPlayingInfo(bundle: self?.nowPlaying.appBundleIdentifier ?? nil)
        }
        
        observeNotification(name: "kMRMediaRemoteNowPlayingApplicationDidChangeNotification") { [weak self] in
            self?.updateApp()
        }
        
        observeNotification(name: "com.spotify.client.PlaybackStateChanged") { [weak self] in
            self?.fetchNowPlayingInfo(bundle: "com.spotify.client")
        }
        
        observeNotification(name: "com.apple.Music.playerInfo") { [weak self] in
            self?.fetchNowPlayingInfo(bundle: "com.apple.Music")
        }
    }
    
    @objc func updateApp() {
        self.bundleIdentifier = nowPlaying.appBundleIdentifier ?? "com.apple.Music"
    }
    
    private func updateBundleIdentifier(_ bundle: String?) {
        if let bundle = bundle {
            self.bundleIdentifier = bundle == "com.apple.WebKit.GPU" ? "com.apple.Safari" : bundle
        }
    }
    
    private func extractMusicInfo(from information: [String: Any]) -> (title: String, artist: String, album: String, artworkData: Data?) {
        let title = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
        let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        let album = information["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
        let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
        
        return (title, artist, album, artworkData)
    }
    
    private func updateArtwork(_ artworkData: Data?, state: Int?) {
        if let artworkData = artworkData ?? (state == 1 ? AppIcons().getIcon(bundleId: bundleIdentifier)?.tiffRepresentation : nil),
           let artworkImage = NSImage(data: artworkData) {
            self.updateAlbumArt(newArtwork: artworkImage)
        }
    }
    
    func calculateAverageColor() {
        songArtwork.averageColor { [weak self] color in
            DispatchQueue.main.async {
                withAnimation(.smooth) {
                    self?.avgColor = color ?? .white
                }
            }
        }
    }
    
    func updateAlbumArt(newArtwork: NSImage) {
        withAnimation(.smooth) {
            self.songArtwork = newArtwork
            if Defaults[.coloredSpectogram] {
                calculateAverageColor()
            }
        }
    }
    
    private func updateFullScreenMediaDetection() {
        DispatchQueue.main.async {
            if Defaults[.enableFullScreenMediaDetection] {
                self.viewModel.toggleMusicLiveActivityOnClosed(status: !self.detector.currentAppInFullScreen)
            }
        }
    }
    
    private func updateSneakPeek() {
        if self.isPlaying && Defaults[.enableSneekPeek] && !self.detector.currentAppInFullScreen {
            self.viewModel.toggleSneakPeek(status: true, type: SneakContentType.music)
        }
    }
    
    private func updateIdleState(setIdle: Bool, state: Bool) {
        if setIdle && state {
            self.isPlayerIdle = false
            debounceToggle?.cancel()
        } else if setIdle && !state {
            debounceToggle = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                if self.lastUpdated.timeIntervalSinceNow < -Defaults[.waitInterval] {
                    withAnimation {
                        self.isPlayerIdle = !self.isPlaying
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Defaults[.waitInterval], execute: debounceToggle!)
        }
    }
    
    func musicIsPaused(state: Bool, bypass: Bool = false, setIdle: Bool = false) {
        if musicToggledManually && !bypass { return }
        
        let previousState = self.isPlaying
        
        withAnimation(.smooth) {
            self.isPlaying = state
            self.playbackManager.isPlaying = state
            
            if !state {
                self.lastUpdated = Date()
            }
            
            updateFullScreenMediaDetection()
            
            if previousState != state {
                updateSneakPeek()
            }
            
            
            updateIdleState(setIdle: setIdle, state: state)
        }
    }

    private func updatePlaybackState(_ state: Int?) {
        if let state = state {
            self.musicIsPaused(state: state == 1, setIdle: true)
        } else if self.isPlaying {
            self.musicIsPaused(state: false, setIdle: true)
        }
    }
    
    private func updateMusicState(newInfo: (title: String, artist: String, album: String, artworkData: Data?), state: Int?) {
        self.lastMusicItem = newInfo
        
        print("Media source: ", bundleIdentifier)
        
        updateArtwork(newInfo.artworkData, state: state)
        updatePlaybackState(state)
        
        if !self.isPlaying { return }
        
        self.songArtist = newInfo.artist
        self.songTitle = newInfo.title
        self.songAlbum = newInfo.album
    }
    
    @objc func fetchNowPlayingInfo(bypass: Bool = false, bundle: String? = nil) {
        if musicToggledManually && bypass { return }
        
        updateBundleIdentifier(bundle)
        
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] (info) in
            guard let self = self else { return }
            
            let newInfo = self.extractMusicInfo(from: info)
            let state: Int? = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Int
            
            self.updateMusicState(newInfo: newInfo, state: state)
        }
    }
    
    func togglePlayPause() {
        self.musicToggledManually = true
        
        let playState = self.playbackManager.playPause()
        
        musicIsPaused(state: playState, bypass: true, setIdle: true)
        
        if playState {
            fetchNowPlayingInfo(bypass: true)
        } else {
            self.lastUpdated = Date()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.musicToggledManually = false
        }
    }
    
    func nextTrack() {
        playbackManager.nextTrack()
        fetchNowPlayingInfo(bypass: true)
    }
    
    func previousTrack() {
        playbackManager.previousTrack()
        fetchNowPlayingInfo(bypass: true)
    }
    
    func openAppMusic() {
        guard let bundleID = nowPlaying.appBundleIdentifier else {
            print("Error: appBundleIdentifier not found")
            return
        }
        
        let workspace = NSWorkspace.shared
        if workspace.launchApplication(
            withBundleIdentifier: bundleID,
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil) {
            print("Launched app with bundle ID: \(bundleID)")
        } else {
            print("Failed to launch app with bundle ID: \(bundleID)")
        }
    }
}
