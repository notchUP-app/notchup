//
//  PlaybackState.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

import Foundation

enum RepeatMode: Int, Codable {
    case off = 0
    case one = 1
    case all = 2
}

struct PlaybackState {
    var bundleIdentifier: String
    var isPlaying: Bool = false
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: Data?
    var duration: Double = 0
    var currentTime: Double = 0
    var playbackRate: Double = 1.0
    var isShuffled: Bool = false
    var repeatMode: RepeatMode = .off
    var lastUpdate: Date = Date.distantPast
    var volume: Double = 0.5
    var isFavorite: Bool = false
}

extension PlaybackState: Equatable {
    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
            && lhs.isPlaying == rhs.isPlaying
            && lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
            && lhs.artwork == rhs.artwork
            && lhs.duration == rhs.duration
            && lhs.currentTime == rhs.currentTime
            && lhs.isShuffled == rhs.isShuffled
            && lhs.repeatMode == rhs.repeatMode
            && lhs.isFavorite == rhs.isFavorite
    }
}
