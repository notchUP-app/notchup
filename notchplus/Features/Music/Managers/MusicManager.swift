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
    static let shared = MusicManager()
    @ObservedObject var coordinator = NotchViewCoordinator.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var controllerCancellabes = Set<AnyCancellable>()
    private var debounceIdleTask: Task<Void, Never>?
    
    // Active Controller
    private var activeController: (any MediaControllerProtocol)?
    
    // Check if macOS version is supported
    public private(set) var isNowPlayingDeprecated: Bool = false
    
    // MARK: MEDIA PROPERTIES
    @Published var songTitle: String = ""
    @Published var songArtist: String = ""
    @Published var songAlbum: String = ""
    @Published var songArtwork: NSImage = defaultImage
    @Published var songDuration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var timestampDate: Date = .init()
    @Published var playbackRate: Double = 1
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var volume: Double = 0.5
    @Published var volumeControlsSupported: Bool = true
    @Published var avgColor: NSColor = .white
    @Published var canFavorite: Bool = false
    
    // Player State
    @Published var isPlaying: Bool = false
    @Published var lastUpdated: Date = .init()
    @Published var ignoreLastUpdated: Bool = false
    @Published var isPlayerIdle: Bool = true
    @Published var bundleIdentifier: String? = nil
    @Published var usingAppIconForArtwork: Bool = false
    private let albumArtCache = NSCache<NSString, NSImage>()
    @Published var isFavoriteTrack: Bool = false
    
    private var artworkData: Data? = nil
    
    private var lastTitle: String = ""
    private var lastArtist: String = ""
    private var lastAlbum: String = ""
    private var lastBundleIdentifier: String? = nil
    
    private var workItem: DispatchWorkItem?
    
    private var flipWorkItem: DispatchWorkItem?
    @Published var isFlipping: Bool = false
    
    private var transitionWorkItem: DispatchWorkItem?
    @Published var isTransitioning: Bool = false
    
    
    // MARK: - INIT
    init() {
        NotificationCenter.default.publisher(for: Notification.Name.mediaControllerChanged)
            .sink { [weak self] _ in
                self?.setActiveControllerBasedOnPreference()
            }
            .store(in: &cancellables)
        
        Task { @MainActor in
            // check for macOS version and set isNowPlayingDeprecated accordingly
            
            self.setActiveControllerBasedOnPreference()
        }
    }
    
    deinit {
        destroy()
    }
    
    public func destroy() {
        debounceIdleTask?.cancel()
        cancellables.removeAll()
        controllerCancellabes.removeAll()
        flipWorkItem?.cancel()
        transitionWorkItem?.cancel()
        
        activeController = nil
    }
    
    // MARK: - SETUP
    private func createController(for type: MediaControllerType) -> (any MediaControllerProtocol)? {
        if activeController != nil {
            controllerCancellabes.removeAll()
            activeController = nil
        }
        
        let newController: (any MediaControllerProtocol)?
        
        switch type {
        case .nowPlaying:
            if !self.isNowPlayingDeprecated {
                ignoreLastUpdated = false
                newController = NowPlayingController()
            } else {
                return nil
            }
        case .appleMusic:
            ignoreLastUpdated = true
            newController = AppleMusicController()
        case .spotify:
            ignoreLastUpdated = true
            newController = SpotifyMediaController()
        }
        
        if let controller = newController {
            controller.playbackStatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    guard let self = self,
                          self.activeController === controller else { return }
                    self.updateFromPlaybackState(state)
                }
                .store(in: &controllerCancellabes)
        }
        
        return newController
    }
    
    private func setActiveController(_ controller: any MediaControllerProtocol) {
        flipWorkItem?.cancel()
        
        activeController = controller
        
        self.canFavorite = controller.supportsFavorite
        
        forceUpdate()
    }
    
    private func setActiveControllerBasedOnPreference() {
        let preferredType = Defaults[.preferredMediaController]
        Logger.log("Preferred media controller: \(preferredType)", type: .media)
        
        let controllerType = (self.isNowPlayingDeprecated && preferredType == .nowPlaying) ? .appleMusic : preferredType
        
        if let controller = createController(for: controllerType) {
            setActiveController(controller)
        } else if controllerType != .appleMusic,
                  let fallbackController = createController(for: .appleMusic) {
            setActiveController(fallbackController)
        }
    }
    
    // MARK: UPDATE SONG DATA FUNCTIONS
    
    private func updateArtwork(_ artworkData: Data) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let artworkImage = NSImage(data: artworkData) {
                DispatchQueue.main.async {
                    self.usingAppIconForArtwork = false
                    self.updateAlbumArt(newArtwork: artworkImage)
                }
            }
        }
    }
    
    func updateAlbumArt(newArtwork: NSImage) {
        workItem?.cancel()
        
        withAnimation(.smooth) {
            self.songArtwork = newArtwork
            if Defaults[.coloredSpectogram] {
                self.calculateAverageColor()
            }
        }
    }
    
    // MARK: UPDATE INTERNAL STATE FUNCTIONS
    
    @MainActor
    private func updateFromPlaybackState(_ state: PlaybackState) {
        // Check for playback state changes
        if state.isPlaying != self.isPlaying {
            self.lastUpdated = Date()
            withAnimation(.smooth) {
                self.isPlaying = state.isPlaying
                self.updateIdleState(state: state.isPlaying)
            }
        }
        
        // Check for changes in track metadata
        let titleChanged = self.songTitle != state.title
        let artistChanged = self.songArtist != state.artist
        let albumChanged = self.songAlbum != state.album
        let artworkChanged = self.artworkData != state.artwork && state.artwork != nil
        let bundleChanged = state.bundleIdentifier != self.bundleIdentifier
        
        let contentChanged = titleChanged || artistChanged || albumChanged || artworkChanged || bundleChanged
        
        if contentChanged {
            self.triggerFlipAnimation()
            
            if artworkChanged, let artwork = state.artwork {
                self.updateArtwork(artwork)
            } else if state.artwork == nil {
                if let appIcon = AppIconAsNSImage(for: state.bundleIdentifier) {
                    self.usingAppIconForArtwork = true
                    self.updateAlbumArt(newArtwork: appIcon)
                }
            }
            
            self.artworkData = state.artwork
            
            if artworkChanged || state.artwork == nil {
                self.lastTitle = state.title
                self.lastArtist = state.artist
                self.lastAlbum = state.album
                self.lastBundleIdentifier = state.bundleIdentifier
            }
        }
        
        let timeChanged = self.elapsedTime != state.currentTime
        let durationChanged = self.songDuration != state.duration
        let playbackRateChanged = self.playbackRate != state.playbackRate
        let shuffleChanged = self.isShuffled != state.isShuffled
        let repeatModeChanged = self.repeatMode != state.repeatMode
        let volumeChanged = self.volume != state.volume
        
        if state.title != self.songTitle { self.songTitle = state.title }
        if state.artist != self.songArtist { self.songArtist = state.artist }
        if state.album != self.songAlbum { self.songAlbum = state.album }
        if timeChanged { self.elapsedTime = state.currentTime }
        if durationChanged { self.songDuration = state.duration }
        if playbackRateChanged { self.playbackRate = state.playbackRate }
        if shuffleChanged { self.isShuffled = state.isShuffled }
        if repeatModeChanged { self.repeatMode = state.repeatMode }
        if volumeChanged { self.volume = state.volume }
        if state.isFavorite != self.isFavoriteTrack { self.isFavoriteTrack = state.isFavorite }
        
        if self.bundleIdentifier != state.bundleIdentifier {
            self.bundleIdentifier = state.bundleIdentifier
            self.volumeControlsSupported = activeController?.supportsVolumeControls ?? false
        }
        
        self.timestampDate = state.lastUpdate
        
    }
    
    private func updateIdleState(state: Bool) {
        if state {
            isPlayerIdle = false
            debounceIdleTask?.cancel()
        } else {
            debounceIdleTask?.cancel()
            debounceIdleTask = Task { [weak self] in
                guard let self = self else { return }
                
                try? await Task.sleep(for: .seconds(Defaults[.musicPlayerWaitInterval]))
                withAnimation {
                    self.isPlayerIdle = !self.isPlaying
                }
                
            }
        }
    }
    
    func toggleFavoriteTrack() {
        guard canFavorite else { return }
        setFavoriteTrack(!isFavoriteTrack)
    }
    
    func setFavoriteTrack(_ favorite: Bool) {
        guard canFavorite else { return }
        guard let controller = activeController else { return }
        
        Task { @MainActor in
            await controller.setFavorite(favorite)
            try? await Task.sleep(for: .milliseconds(150))
            await controller.updatePlaybackInfo()
        }
    }
    
    @MainActor
    private func toggleAppleMusicFavorite() async {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")
        guard !runningApps.isEmpty else { return }
        
        let script = """
            tell application \"Music\"
                if it running then
                    try
                        set favorited of current track to (not favorited of current track)
                        return favorited of current track
                    on error
                        return false
                    end try
                else
                    return false
                end if
            end tell
            """
        
        if let result = try? await AppleScriptHelper.execute(script) {
            let loved = result.booleanValue
            self.isFavoriteTrack = loved
            self.forceUpdate()
        }
    }
    
    // MARK: HELPER FUNCTIONS
    public func estimatedPlaybackPosition(at date: Date = Date()) -> TimeInterval {
        guard isPlaying else { return min(elapsedTime, songDuration) }
        
        let timeDiff = date.timeIntervalSince(timestampDate)
        let estimatedPosition = elapsedTime + timeDiff * playbackRate
        return min(max(0, estimatedPosition), songDuration)
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
    
    private func triggerFlipAnimation() {
        flipWorkItem?.cancel()
        
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.isFlipping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.isFlipping = false
            }
        }
        
        flipWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
    
    func forceUpdate() {
        Task { [weak self] in
            if self?.activeController?.isActive() == true {
                await self?.activeController?.updatePlaybackInfo()
            } else {
                // If current controller is not active, try to find a better one
                Logger.log("Current controller is not active, attempting to find alternative", type: .media)
                self?.setActiveControllerBasedOnPreference()
            }
        }
    }
    
    // Add a method to periodically check for music updates
    func startPeriodicUpdates() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.forceUpdate()
        }
    }
    
    // MARK: PLAYER CONTROLS
    func playPause() { Task { await activeController?.togglePlay() }  }
    func play() { Task { await activeController?.play() } }
    func pause() { Task { await activeController?.pause() } }
    func togglePlay() { Task { await activeController?.togglePlay() } }
    func next() { Task { await activeController?.next() } }
    func previous() { Task { await activeController?.previous() } }
    func seek(to time: TimeInterval) { Task { await activeController?.seek(to: time) } }
    func toggleShuffle() { Task { await activeController?.toggleShuffle() } }
    func toggleRepeat() { Task { await activeController?.toggleRepeat() } }
    func setVolume(to level: Double) { Task { await activeController?.setVolume(to: level) } }
    
    func openAppMusic() {
        guard let bundleID = bundleIdentifier else {
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
    
    func syncVolumeFromActiveApp() async {
        guard let bundleId = bundleIdentifier, !bundleId.isEmpty,
              NSWorkspace.shared.runningApplications.contains(where: {  $0.bundleIdentifier == bundleId }) else { return }
        
        var script: String?
        if bundleId == "com.apple.Music" {
            script = """
                tell application "Music"
                    if it is running then
                        get sound volume
                    else
                        return 0
                    end if
                end tell
                """
        } else if bundleId == "com.spotify.client" {
            script = """
                tell application "Spotify"
                    if it is running then
                        get sound volume
                    else
                        return 0
                    end if
                end tell
                """
        } else { return }
        
        if let volumeScript = script,
           let result = try? await AppleScriptHelper.execute(volumeScript) {
            let volumeLevel = result.int32Value
            let currentVolume = Double(volumeLevel) / 100.0
            
            await MainActor.run {
                if abs(currentVolume - self.volume) > 0.01 {
                    self.volume = currentVolume
                }
            }
        }
    }
    
    // MARK: CACHE FUNCTIONS
    func getAlbumArt(for identifier: String, size: CGSize) -> NSImage? {
        let cacheKey = "\(identifier)-\(Int(size.width))-\(Int(size.height))" as NSString
        
        if let cachedImage = albumArtCache.object(forKey: cacheKey) {
            Logger.log("Using cached album art for \(identifier)", type: .media)
            return cachedImage
        }
        
        guard let artworkData = artworkData else {
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
