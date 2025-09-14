//
//  AppleMusicController.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

class AppleMusicController: MediaControllerProtocol {
    @Published private var playbackState: PlaybackState = .init(bundleIdentifier: "com.apple.Music")
    var playbackStatePublisher: Published<PlaybackState>.Publisher { $playbackState }
    
    // MARK: - Init
    init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(updatePlaybackInfo),
            name: Notification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
        
        updatePlaybackInfo()
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(
        self,
        name: Notification.Name("com.apple.Music.playerInfo"),
        object: nil
        )
    }
    
    // MARK: - Protocol Implementation
    func play() {
        executeCommand("play")
    }
    
    func pause() {
        executeCommand("pause")
    }
    
    func togglePlay() {
        executeCommand("playpause")
    }
    
    func next() {
        executeCommand("next track")
    }
    
    func previous() {
        executeCommand("previous track")
    }
    
    func seek(to time: Double) {
        executeCommand("set player position to \(time)")
        updatePlaybackInfo()
    }
    
    func isActive() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == playbackState.bundleIdentifier }
            
    }
    
    // MARK: - Private Methods
    private func executeCommand(_ command: String) {
        let script = "tell application \"Music\" to \(command)"
        Task {
            try? await AppleScriptHelper.executeVoid(script)
        }
    }
    
    private func fetchPlaybackInfo() -> NSAppleEventDescriptor? {
        let script = """
        tell application "Music"
            set isRuninng to true
            try
                set playerState to player state is playing
                set currentTrackName to name of current track
                set currentTrackArtist to artist of current track
                set currentTrackAlbum to album of current track
                set trackPosition to player position
                set trackDuration to duration of current track
                set shuffleState to false
                set repeatState to false
                try
                    set artData to data of artwork 1 of current track
                on error
                    set artData to ""
                end try
                return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, shuffleState, repeatState, artData}
            on error
                return {false, "Not playing", "Unknown", "Unknown", 0, 0, false, false, ""}
            end try
        end tell
        """
        
        var descriptor: NSAppleEventDescriptor? = nil
        let sempaphore = DispatchSemaphore(value: 0)
        
        Task {
            descriptor = try? await AppleScriptHelper.execute(script)
            sempaphore.signal()
        }
        
        sempaphore.wait()
        return descriptor
    }
    
    @objc func updatePlaybackInfo() {
        guard let descriptor = fetchPlaybackInfo() else { return }
        guard descriptor.numberOfItems >= 8 else { return }
        
        let isPlaying = descriptor.atIndex(1)?.booleanValue ?? false
        let currentTrack = descriptor.atIndex(2)?.stringValue ?? "Unknown"
        let currentTrackArtist = descriptor.atIndex(3)?.stringValue ?? "Unknown"
        let currentTrackAlbum = descriptor.atIndex(4)?.stringValue ?? "Unknown"
        let currentTime = descriptor.atIndex(5)?.doubleValue ?? 0
        let duration = descriptor.atIndex(6)?.doubleValue ?? 0
        let shuffleState = descriptor.atIndex(7)?.booleanValue ?? false
        let repeatState = descriptor.atIndex(8)?.booleanValue ?? false
        let artworkData = descriptor.atIndex(9)?.data as Data?
        
        let updatedState = PlaybackState(
            bundleIdentifier: "com.apple.Music",
            isPlaying: isPlaying,
            title: currentTrack,
            artist: currentTrackArtist,
            album: currentTrackAlbum,
            artwork: artworkData,
            duration: duration,
            currentTime: currentTime,
            playbackRate: 1,
            isShuffled: shuffleState,
            isRepeat: repeatState,
            lastUpdate: Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = updatedState
        }
    }
}
