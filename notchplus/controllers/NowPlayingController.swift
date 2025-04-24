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
    @Published var playbackState: PlaybackState = .init( bundleIdentifier: "com.apple.Music" )
    
    var playbackStatePublisher: Published<PlaybackState>.Publisher { $playbackState }
    private var cancellables = Set<AnyCancellable>()
    private var lastMusicItem: (title: String, artist: String, album: String, duration: TimeInterval, artworkData: Data?)?
    
    // MARK: - MediaRemote Functions
    private let mediaRemoteBundle: CFBundle
    private let MRMediaRemoteGetNowPlayingInfo: @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private let MRMediaRemoteRegisterForNowPlayingNotifications: @convention(c) (DispatchQueue) -> Void
    private let MRMediaRemoteGetNowPlayingApplicationIsPlaying: @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private let MRMediaRemoteGetNowPlayingClient: @convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void
    private let MRNowPlayingClientGetBundleIndentifier: @convention(c) (AnyObject?) -> String?
    private let MRNowPlayingClientGetParentAppBundleIdentifier: @convention(c) (AnyObject?) -> String?
    private let MRMediaRemoteSendCommandFunction: @convention(c) (Int, AnyObject?) -> Void
    private let MRMediaRemoteSetElapsedTimeFunction: @convention(c) (Double) -> Void
    
    // MARK: - Init
    init?() {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
              let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString),
              let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString),
              let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString),
              let MRMediaRemoteGetNowPlayingClientPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingClient" as CFString),
              let MRNowPlayingClientGetBundleIndentifierPointer = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetBundleIdentifier" as CFString),
              let MRNowPlayingClientGetParentAppBundleIdentifierPointer = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetParentAppBundleIdentifier" as CFString),
              let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString),
              let MRMediaRemoteSetElapsedTimePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetElapsedTime" as CFString)
        else { return nil }
        
        mediaRemoteBundle = bundle
        MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void).self)
        MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: (@convention(c) (DispatchQueue) -> Void).self)
        MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: (@convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void).self)
        MRMediaRemoteGetNowPlayingClient = unsafeBitCast(MRMediaRemoteGetNowPlayingClientPointer, to: (@convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void).self)
        MRNowPlayingClientGetBundleIndentifier = unsafeBitCast(MRNowPlayingClientGetBundleIndentifierPointer, to: (@convention(c) (AnyObject?) -> String?).self)
        MRNowPlayingClientGetParentAppBundleIdentifier = unsafeBitCast(MRNowPlayingClientGetParentAppBundleIdentifierPointer, to: (@convention(c) (AnyObject?) -> String?).self)
        MRMediaRemoteSendCommandFunction = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: (@convention(c) (Int, AnyObject?) -> Void).self)
        MRMediaRemoteSetElapsedTimeFunction = unsafeBitCast(MRMediaRemoteSetElapsedTimePointer, to: (@convention(c) (Double) -> Void).self)
        
        setupNowPlayingObserver()
        updatePlaybackInfo()
    }
    
    deinit {
        cancellables.removeAll()
        
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
    }
    
    // MARK: - Protocol Implementation
    
    func play() {
        MRMediaRemoteSendCommandFunction(0, nil)
    }
    
    func pause() {
        MRMediaRemoteSendCommandFunction(1, nil)
    }
    
    func togglePlay() {
        MRMediaRemoteSendCommandFunction(2, nil)
    }
    
    func next() {
        MRMediaRemoteSendCommandFunction(4, nil)
    }
    
    func previous() {
        MRMediaRemoteSendCommandFunction(5, nil)
    }
    
    func seek(to time: TimeInterval) {
        MRMediaRemoteSetElapsedTimeFunction(time)
    }
    
    func isActive() -> Bool {
        return true
    }
    
    // MARK: - Setup Methods
    private func setupNowPlayingObserver() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        Logger.log("Listening for media remote notifications", type: .info)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"))
            .sink { [weak self] _ in self?.updatePlaybackInfo() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification"))
            .sink { [weak self] _ in self?.updateApp() }
            .store(in: &cancellables)
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(updatePlaybackInfo),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(updatePlaybackInfo),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
    }
    
    // MARK: - Update Methods
    @objc func updateApp() {
        MRMediaRemoteGetNowPlayingClient(DispatchQueue.main) { [weak self] client in
            guard let client = client else {
                DispatchQueue.main.async {
                    self?.playbackState.bundleIdentifier = "com.apple.Music"
                }
                return
            }
            
            // Try getting the parent bundle ID first, then fallback directly to the client bundle ID
            var appBundleID = self?.MRNowPlayingClientGetParentAppBundleIdentifier(client)
            if appBundleID == nil {
                appBundleID = self?.MRNowPlayingClientGetBundleIndentifier(client)
            }
            
            // Special case for WebKit GPU (safari-based)
            if appBundleID == "com.apple.WebKit.GPU" {
                appBundleID = "com.apple.Safari"
            }
            
            DispatchQueue.main.async {
                self?.playbackState.bundleIdentifier = appBundleID ?? "com.apple.Music"
            }
        }
    }
    
    @objc func updatePlaybackInfo() {
        updateApp()
        
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }
            
            let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
            let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? TimeInterval ?? 0
            let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            let timestamp = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date ?? Date()
            let playbackRate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 1
            
            DispatchQueue.main.async {
                self.playbackState.title = title
                self.playbackState.artist = artist
                self.playbackState.album = album
                self.playbackState.duration = duration
                self.playbackState.artwork = artworkData
                self.playbackState.lastUpdate = timestamp
                self.playbackState.playbackRate = playbackRate
                
                self.MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] isPlaying in
                    DispatchQueue.main.async {
                        self?.playbackState.isPlaying = isPlaying
                    }
                }
            }
        }
    }
    
}
