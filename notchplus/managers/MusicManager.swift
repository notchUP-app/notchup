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
    private var debounceToggle: DispatchWorkItem?

    // Active Controller
    private var activeController: (any MediaControllerProtocol)?

    // Check if macOS version is supported
    public var isNowPlayingDeprecated: Bool {
        if #available(macOS 15.4, *) {
            return true
        }

        return false
    }

    // MARK: MEDIA PROPERTIES
    @Published var songTitle: String = ""
    @Published var songArtist: String = ""
    @Published var songAlbum: String = ""
    @Published var songArtwork: NSImage = defaultImage
    @Published var songDuration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var timestampDate: Date = .init()
    @Published var playbackRate: Double = 1
    @Published var avgColor: NSColor = .white

    // Player State
    @Published var isPlaying: Bool = false
    @Published var lastUpdated: Date = .init()
    @Published var ignoreLastUpdated: Bool = false
    @Published var isPlayerIdle: Bool = true
    @Published var bundleIdentifier: String? = nil
    @Published var usingAppIconForArtwork: Bool = false
    private let albumArtCache = NSCache<NSString, NSImage>()

    private var artworkData: Data? = nil

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

        setActiveControllerBasedOnPreference()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

        debounceToggle?.cancel()

        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        controllerCancellabes.forEach { $0.cancel() }
        controllerCancellabes.removeAll()

        flipWorkItem?.cancel()
        transitionWorkItem?.cancel()

        albumArtCache.removeAllObjects()

        activeController = nil
    }

    // MARK: - SETUP
    private func createController(for type: MediaControllerType) -> (any MediaControllerProtocol)? {
        if let _ = activeController {
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
        transitionWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.isTransitioning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.isTransitioning = false
            }
        }

        transitionWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)

        activeController = controller

        if let state = Mirror(reflecting: controller).children.first(where: { $0.label == "playbackState" })?.value as? PlaybackState {
            updateFromPlaybackState(state)
        }
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
        workItem = DispatchWorkItem { [weak self] in
            withAnimation(.smooth) {
                self?.songArtwork = newArtwork

                if Defaults[.coloredSpectogram] {
                    self?.calculateAverageColor()
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem!)
    }

    // MARK: UPDATE INTERNAL STATE FUNCTIONS

    private func updateFromPlaybackState(_ state: PlaybackState) {
        let updateBatch = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

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

            let contentChanged = titleChanged || artistChanged || albumChanged || artworkChanged

            if contentChanged {
                self.triggerFlipAnimation()

                if artworkChanged, let artwork = state.artwork {
                    self.updateArtwork(artwork)
                } else if contentChanged && state.artwork == nil {
                    if let appIcon = AppIconAsNSImage(for: state.bundleIdentifier) {
                        self.usingAppIconForArtwork = true
                        self.updateAlbumArt(newArtwork: appIcon)
                    }
                }

                self.artworkData = state.artwork
            }

            let timeChanged = self.elapsedTime != state.currentTime
            let durationChanged = self.songDuration != state.duration
            let playbackRateChanged = self.playbackRate != state.playbackRate

            if titleChanged { self.songTitle = state.title }
            if artistChanged { self.songArtist = state.artist }
            if albumChanged { self.songAlbum = state.album }
            if timeChanged { self.elapsedTime = state.currentTime }
            if durationChanged { self.songDuration = state.duration }
            if playbackRateChanged { self.playbackRate = state.playbackRate }

            if self.bundleIdentifier != state.bundleIdentifier {
                self.bundleIdentifier = state.bundleIdentifier
            }

            self.timestampDate = state.lastUpdate
        }

        DispatchQueue.main.async(execute: updateBatch)
    }

    private func updateIdleState(state: Bool) {
        if state {
            isPlayerIdle = false
            debounceToggle?.cancel()
        } else {
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

    // MARK: HELPER FUNCTIONS
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
        DispatchQueue.main.async { [weak self] in
            if self?.activeController?.isActive() == true {
                self?.activeController?.updatePlaybackInfo()
            }
        }
    }

    // MARK: PLAYER CONTROLS
    func playPause() { activeController?.togglePlay() }
    func play() { activeController?.play() }
    func pause() { activeController?.pause() }
    func togglePlay() { activeController?.togglePlay() }
    func next() { activeController?.next() }
    func previous() { activeController?.previous() }
    func seek(to time: TimeInterval) { activeController?.seek(to: time) }

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
