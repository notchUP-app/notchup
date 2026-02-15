//
//  AppleMusicController.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

import Foundation
import Combine
import SwiftUI

class AppleMusicController: MediaControllerProtocol {
    
    @Published private var playbackState: PlaybackState = PlaybackState(
        bundleIdentifier: "com.apple.Music",
        playbackRate: 1
    )
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        $playbackState.eraseToAnyPublisher()
    }
    
    var supportsVolumeControls: Bool { return true }
    var supportsFavorite: Bool { return true }
    
    private var notificationTasks: Task<Void, Never>?
    
    // MARK: - Init
    init() {
        setupPlaybackStateChangeObserver()
        Task {
            if isActive() {
                await updatePlaybackInfo()
            }
        }
    }
    
    deinit {
        notificationTasks?.cancel()
    }
    
    private func setupPlaybackStateChangeObserver() {
        notificationTasks = Task { @Sendable [weak self] in
            let notification = DistributedNotificationCenter.default().notifications(
                named: NSNotification.Name("com.apple.Music.playerInfo")
            )
            
            for await _ in notification {
                await self?.updatePlaybackInfo()
            }
        }
    }
    
    // MARK: - Protocol Implementation
    func play() async {
        await executeCommand("play")
    }
    
    func pause() async {
        await executeCommand("pause")
    }
    
    func togglePlay() async {
        await executeCommand("playpause")
    }
    
    func next() async {
        await executeCommand("next track")
    }
    
    func previous() async {
        await executeCommand("previous track")
    }
    
    func seek(to time: Double) async {
        await executeCommand("set player position to \(time)")
        await updatePlaybackInfo()
    }
    
    func toggleShuffle() async {
        await executeCommand("set shuffle enabled to not not shuffle enabled")
        try? await Task.sleep(for: .milliseconds(150))
        await updatePlaybackInfo()
    }
    
    func toggleRepeat() async {
        await executeCommand("""
            if song repeat is off then
                set song repeat to all
            else if song repeat is all then
                set song repeat to one
            else
                set song repeat to off
            end if
            """)
        try? await Task.sleep(for: .milliseconds(150))
        await updatePlaybackInfo()
    }
    
    func setVolume(to level: Double) async {
        let clampedLevel = max(0.0, min(1.0, level))
        let volumePercentage = Int(clampedLevel * 100)
        
        await executeCommand("set sound volume to \(volumePercentage)")
        try? await Task.sleep(for: .milliseconds(150))
        
        await updatePlaybackInfo()
    }
    
    func setFavorite(_ favorite: Bool) async {
        let script = """
        tell application "Music"
            try
                set favorited of current track to \(favorite)
            end try
        end tell
        """
        
        try? await AppleScriptHelper.executeVoid(script)
        try? await Task.sleep(for: .milliseconds(150))
        
        await updatePlaybackInfo()
    }
    
    func isActive() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        
    }
    
    // MARK: - Private Methods
    private func executeCommand(_ command: String) async {
        let script = "tell application \"Music\" to \(command)"
        try? await AppleScriptHelper.executeVoid(script)
    }
    
    private func fetchPlaybackInfoAsync() async throws -> NSAppleEventDescriptor? {
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
                set shuffleState to shuffle enabled
                set repeatState to song repeat
                if repeatState is off then
                    set repeatValue to 1
                else if repeatState is one then
                    set repeatValue to 2
                else if repeatState is all then
                    set repeatValue to 3
                end if
        
                try
                    set artData to data of artwork 1 of current track
                on error
                    set artData to ""
                end try
        
                set currentVolume to sound volume
                set favoriteState to favorited of current track
                return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, shuffleState, repeatValue, currentVolume, artData, favoriteState}
            on error
                return {false, "Not Playing", "Unknown", "Unknown", 0, 0, false, 0, 50, "", false}
            end try
        end tell
        """
        
        return try await AppleScriptHelper.execute(script)
    }
    
    @objc func updatePlaybackInfo() async {
        guard let descriptor = try? await fetchPlaybackInfoAsync() else {
            Logger.log("Failed to fetch Apple Music playback info", type: .warning)
            return
        }
        
        guard descriptor.numberOfItems >= 11 else {
            Logger.log("Insufficient Apple Music data items: \(descriptor.numberOfItems)", type: .warning)
            return
        }
        
        var updatedState = self.playbackState
        
        updatedState.isPlaying = descriptor.atIndex(1)?.booleanValue ?? false
        updatedState.title = descriptor.atIndex(2)?.stringValue ?? "Unknown"
        updatedState.artist = descriptor.atIndex(3)?.stringValue ?? "Unknown"
        updatedState.album = descriptor.atIndex(4)?.stringValue ?? "Unknown"
        updatedState.currentTime = descriptor.atIndex(5)?.doubleValue ?? 0
        updatedState.duration = descriptor.atIndex(6)?.doubleValue ?? 0
        updatedState.isShuffled = descriptor.atIndex(7)?.booleanValue ?? false
        let repeatModeValue = descriptor.atIndex(8)?.int32Value ?? 0
        updatedState.repeatMode = RepeatMode(rawValue: Int(repeatModeValue)) ?? .off
        let volumePercentage = descriptor.atIndex(9)?.int32Value ?? 50
        updatedState.volume = Double(volumePercentage) / 100.0
        updatedState.artwork = descriptor.atIndex(10)?.data as Data?
        let lovedState = descriptor.atIndex(11)?.booleanValue ?? false
        updatedState.isFavorite = lovedState
        updatedState.lastUpdate = Date()
        self.playbackState = updatedState
    }
}
