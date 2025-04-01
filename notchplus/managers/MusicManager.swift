//
//  MusicManager.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 19/10/24.
//

import SwiftUI
import AppKit
import Combine
import Defaults

let defaultImage: NSImage = .init(
    systemSymbolName: "music.note",
    accessibilityDescription: "Album artwork"
)!

class MusicManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var debounceToggle: DispatchWorkItem?
    private var viewModel: NotchViewModel
    private var lastMusicItem: (title: String, artist: String, album: String, duration: TimeInterval, artworkData: Data?)?
    private var isCurrentlyPlaying: Bool = false
    
    // MARK: Song variables
    @Published var songTitle: String = ""
    @Published var songArtist: String = ""
    @Published var songAlbum: String = ""
    @Published var songArtwork: NSImage = defaultImage
    @Published var songDuration: TimeInterval = 0
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var timestampDate: Date = Date()
    @Published var playbackRate: Double = 0
    
    // MARK: PLAYER VARIBALES
    @Published var isPlaying: Bool = false
    @Published var avgColor: NSColor = .white
    @Published var isPlayerIdle: Bool = true
    @Published var bundleIdentifier: String = "com.apple.Music"
    @Published var musicToggledManually: Bool = false
    
    // MARK: STATES
    @Published var lastUpdated: Date = .init()
    @Published var animations: NotchAnimation = .init()
    @Published var playbackManager = PlaybackManager()
    @ObservedObject var detector: FullScreenMediaDetector
    var nowPlaying: NowPlaying
    
    // MARK: FRAMEWORK
    private let mediaRemoteBundle: CFBundle
    private let MRMediaRemoteGetNowPlayingInfo: @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) ->  Void
    private let MRMediaRemoteRegisterForNowPlayingNotifications: @convention(c) (DispatchQueue) -> Void
    
    // MARK: CACHED DATA
    private let albumArtCache = NSCache<NSString, NSImage>()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        debounceToggle?.cancel()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        albumArtCache.removeAllObjects()
    }
    
    init?(viewModel: NotchViewModel) {
        self.viewModel = viewModel
        _detector = ObservedObject(wrappedValue: FullScreenMediaDetector())
        nowPlaying = NowPlaying()
        
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
              let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString),
              let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString)
        else {
            Logger.log("Failed to load MediaRemote.framework or get function pointers", type: .error)
            return nil
        }
        
        self.mediaRemoteBundle = bundle
        self.MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void).self)
        self.MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: (@convention(c) (DispatchQueue) -> Void).self)
        
        
        setupNowPlayingObserver()
        fetchNowPlayingInfo()
        
        setupDetectorObserver()
        
        if nowPlaying.playing {
            self.fetchNowPlayingInfo()
        }
    }
    
    // MARK: OBSERVERS
    private func setupDetectorObserver() {
        detector.$currentAppInFullScreen
            .sink { [weak self] _ in
                self?.fetchNowPlayingInfo(bypass: true, bundle: self?.nowPlaying.appBundleIdentifier ?? nil)
            }
            .store(in: &cancellables)
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
        Logger.log("Listening for media remote notifications", type: .info)
        
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
            print("com.apple.Music.playerInfo")
            self?.fetchNowPlayingInfo(bundle: "com.apple.Music")
        }
    }
    
    // MARK: UPDATE SONG DATA FUNCTIONS
    
    @objc func updateApp() {
        self.bundleIdentifier = nowPlaying.appBundleIdentifier ?? "com.apple.Music"
    }
    
    private func updateBundleIdentifier(_ bundle: String?) {
        if let bundle = bundle {
            self.bundleIdentifier = bundle == "com.apple.WebKit.GPU" ? "com.apple.Safari" : bundle
        }
    }
    
    private func updateArtwork(_ artworkData: Data?, state: Int?, forceUpdate: Bool = false) {
        if let artworkData = artworkData ?? (state == 1 ? AppIcons().getIcon(bundleId: bundleIdentifier)?.tiffRepresentation : nil) {
            self.lastMusicItem?.artworkData = artworkData
            
            let identifier = "\(songTitle)-\(songArtist)-\(songAlbum)"
            
            if let originalImage = NSImage(data: artworkData) {
                self.updateAlbumArt(newArtwork: originalImage)
                
                let commonSizes = [CGSize(width: 300, height: 300), CGSize(width: 100, height: 100)]
                for size in commonSizes {
                    let resizedImage = resizeImage(originalImage, to: size)
                    let sizeKey = "\(identifier)-\(Int(size.width))-\(Int(size.height))" as NSString
                    
                    Logger.log("Storing resized artwork for \(sizeKey)", type: .media)
                    albumArtCache.setObject(resizedImage, forKey: sizeKey)
                }
            }
        }
    }
    
    func updateAlbumArt(newArtwork: NSImage) {
        withAnimation(.smooth) {
            self.songArtwork = newArtwork
            
            albumArtCache.setObject(newArtwork, forKey: "original-\(songTitle)-\(songArtist)-\(songAlbum)" as NSString)
            
            if Defaults[.coloredSpectogram] {
                calculateAverageColor()
            }
        }
    }
    
    func getAlbumArtwork(_ identifier: String, size: CGSize = CoverSize.small) -> NSImage? {
        let cacheKey = "\(identifier)-\(Int(size.width))-\(Int(size.height))" as NSString
        
        Logger.log("Getting album art for \(identifier) with size \(size)", type: .media)
        
        if let cachedImage = albumArtCache.object(forKey: cacheKey) {
            Logger.log("Using cached album art for \(identifier)", type: .media)
            return cachedImage
        }
        
        Logger.log("Using default image", type: .media)
        return defaultImage
    }
    
    // MARK: UPDATE INTERNAL STATE FUNCTIONS
    
    private func updateFullScreenMediaDetection() {
        DispatchQueue.main.async {
            if Defaults[.enableFullScreenMediaDetection] {
                self.viewModel.toggleMusicLiveActivityOnClosed(status: !self.detector.currentAppInFullScreen)
            }
        }
    }
    
    private func updateIdleState(setIdle: Bool, state: Bool) {
        if setIdle && state {
            self.isPlayerIdle = false
            debounceToggle?.cancel()
        } else if setIdle && !state {
            debounceToggle = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                if self.lastUpdated.timeIntervalSinceNow < -Defaults[.musicPlayerWaitInterval] {
                    withAnimation {
                        self.isPlayerIdle = !self.isPlaying
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Defaults[.musicPlayerWaitInterval], execute: debounceToggle!)
        }
    }
    
    private func updatePlaybackState(_ state: Int?) {
        if let state = state {
            self.musicIsPaused(state: state == 1, setIdle: true)
        } else if self.isPlaying {
            self.musicIsPaused(state: false, setIdle: true)
        }
    }
    
    private func updateMusicState(newInfo: (title: String, artist: String, album: String, duration: TimeInterval, artworkData: Data?), state: Int?) {
        Logger.log("Media source: \(bundleIdentifier)", type: .media)
        Logger.log("Album Art Cache: \(albumArtCache.attributeKeys)", type: .media)
        
        let songChanged = newInfo.title != songTitle || newInfo.artist != songArtist || newInfo.album != songAlbum
        
        updateArtwork(newInfo.artworkData, state: state, forceUpdate: true)
                
        withAnimation(.smooth) {
            self.songArtist = newInfo.artist
            self.songTitle = newInfo.title
            self.songAlbum = newInfo.album
            self.songDuration = newInfo.duration
        }
    
        if songChanged {
            self.lastMusicItem = (title: newInfo.title, artist: newInfo.artist, album: newInfo.album, duration: newInfo.duration, artworkData: lastMusicItem?.artworkData)
        }
        
        updatePlaybackState(state)
        
        if !self.isPlaying { return }
        
        NotificationCenter.default.post(name: .musicInfoChanged, object: nil)
    }
    
    // MARK: HELPER FUNCTIONS
    private func extractMusicInfo(from information: [String: Any]) -> (title: String, artist: String, album: String, duration: TimeInterval, artworkData: Data?) {
        let title = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
        let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        let album = information["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
        let duration = information["kMRMediaRemoteNowPlayingInfoDuration"] as? TimeInterval ?? 0
        let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
        
        return (title, artist, album, duration, artworkData)
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
    
    func musicIsPaused(state: Bool, bypass: Bool = false, setIdle: Bool = false) {
        if musicToggledManually && !bypass { return }
        
        withAnimation(.smooth) {
            self.isPlaying = state
            self.playbackManager.isPlaying = state
            
            if !state {
                self.lastUpdated = Date()
            }
            
            updateFullScreenMediaDetection()
            
            updateIdleState(setIdle: setIdle, state: state)
        }
    }
    
    @objc func fetchNowPlayingInfo(bypass: Bool = false, bundle: String? = nil) {
        if musicToggledManually && !bypass { return }
        
        updateBundleIdentifier(bundle)
        
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] (info) in
            guard let self = self else { return }
            
            let newInfo = self.extractMusicInfo(from: info)
            let state: Int? = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Int
            
            self.updateMusicState(newInfo: newInfo, state: state)
            
            guard let elapsedTime = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? TimeInterval,
                  let timestampDate = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date,
                  let playbackRate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double
            else { return }
            
            DispatchQueue.main.async {
                self.elapsedTime = elapsedTime
                self.timestampDate = timestampDate
                self.playbackRate = playbackRate
            }
        }
    }
    
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1)
        
        resizedImage.unlockFocus()
        return resizedImage
    }
    
    // MARK: PLAYER CONTROLS
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
    
    func seekTrack(to time: TimeInterval) {
        playbackManager.seekTrack(to: time)
    }
    
    func openAppMusic() {
        guard let bundleID = nowPlaying.appBundleIdentifier else {
            Logger.log("Error: appBundleIdentifier not found", type: .error)
            return
        }
        
        let workspace = NSWorkspace.shared
        if let appUrl = workspace.urlForApplication(withBundleIdentifier: bundleID) {
            let configuration = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: appUrl, configuration: configuration) { app, error in
                if let error = error {
                    Logger.log("Failed to open app with bundleID: \(bundleID) - \(error)", type: .error)
                } else {
                    Logger.log("Opened app with bundleID: \(bundleID)", type: .info)
                }
            }
        } else {
            Logger.log("Failed to get app URL for bundleID: \(bundleID)", type: .error)
        }
    }
    
    // MARK: CACHE FUNCTIONS
    func getAlbumArt(for identifier: String, size: CGSize) -> NSImage? {
        let cacheKey = "\(identifier)-\(Int(size.width))-\(Int(size.height))" as NSString
        
        if let cachedImage = albumArtCache.object(forKey: cacheKey) {
            Logger.log("Using cached album art for \(identifier)", type: .media)
            return cachedImage
        }
        
        guard let artworkData = lastMusicItem?.artworkData else {
            return defaultImage
        }
        
        guard let originalImage = NSImage(data: artworkData) else {
            return defaultImage
        }
        
        let resizedImage = resizeImage(originalImage, to: size)
        
        albumArtCache.setObject(resizedImage, forKey: cacheKey)
        
        return resizedImage
    }
}
