//
//  SpotifyMediaController.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 19/05/25.
//

import SwiftUI
import Foundation
import Combine

class SpotifyMediaController: MediaControllerProtocol {
    
    
    @Published private var playbackState: PlaybackState = .init(bundleIdentifier: "com.spotify.client")
    var playbackStatePublisher: Published<PlaybackState>.Publisher { $playbackState }
    
    init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(updatePlaybackInfo),
            name: Notification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        
        DispatchQueue.main.async { [weak self] in
            if self?.isActive() == true {
                self?.updatePlaybackInfo()
            }
        }
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: Notification.Name("com.spotify.client.PlaybackStateChanged"),
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
    
    func next() {
        executeCommand("next track")
    }
    
    func previous() {
        executeCommand("previous track")
    }
    
    func togglePlay() {
        executeCommand("playpause")
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
        let script = "tell application \"Spotify\" to \(command)"
        Task {
            try? await AppleScriptHelper.executeVoid(script)
        }
    }
    
    private func fetchPlaybackInfo() -> NSAppleEventDescriptor? {
        let script = """
        tell application "Spotify"
            set isRunning to true
            try
                set playerState to player state is playing
                set currentTrackName to name of current track
                set currentTrackArtist to artist of current track
                set currentTrackAlbum to album of current track
                set trackPosition to player position
                set trackDuration to duration of current track
                set shuffleState to shuffling
                set repeatState to repeating
                set artworkURL to artwork url of current track
                return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, shuffleState, repeatState, artworkURL}
            on error
                return {false, "Not playing", "Unknown", "Unknown", 0, 0, false, false, ""}
            end try
        end tell
        """
        
        var descriptor: NSAppleEventDescriptor? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            descriptor = try? await AppleScriptHelper.execute(script)
            semaphore.signal()
        }
        
        semaphore.wait()
        return descriptor
    }
    
    @objc func updatePlaybackInfo() {
        Logger.log("Spotify updatePlaybackInfo", type: .debug)
        
        guard let descriptor = fetchPlaybackInfo() else { return }
        guard descriptor.numberOfItems >= 9 else { return }
        
        let isPlaying = descriptor.atIndex(1)?.booleanValue ?? false
        let currentTrack = descriptor.atIndex(2)?.stringValue ?? "Unknown"
        let currentTrackArtist = descriptor.atIndex(3)?.stringValue ?? "Unknown"
        let currentTrackAlbum = descriptor.atIndex(4)?.stringValue ?? "Unknown"
        let currentTime = descriptor.atIndex(5)?.doubleValue ?? 0
        let duration = (descriptor.atIndex(6)?.doubleValue ?? 0) / 1000
        let shuffleState = descriptor.atIndex(7)?.booleanValue ?? false
        let repeatState = descriptor.atIndex(8)?.booleanValue ?? false
        let artworkURL = descriptor.atIndex(9)?.stringValue ?? ""
        
        let state = PlaybackState(
            bundleIdentifier: "com.spotify.client",
            isPlaying: isPlaying,
            title: currentTrack,
            artist: currentTrackArtist,
            album: currentTrackAlbum,
            duration: duration,
            currentTime: currentTime,
            playbackRate: 1,
            isShuffled: shuffleState,
            isRepeat: repeatState,
            lastUpdate: Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = state
        }
        
        if !artworkURL.isEmpty, let url = URL(string: artworkURL) {
            DispatchQueue.global(qos: .background ).async { [weak self] in
                do {
                    let artworkData = try Data(contentsOf: url)
                    DispatchQueue.main.async {
                        var updateState = state
                        updateState.artwork = artworkData
                        self?.playbackState = updateState
                    }
                } catch {
                    Logger.log("Failed to load artwork data from Spotify", type: .error)
                }
            }
        } else {
            self.playbackState = state
        }
    }
}
