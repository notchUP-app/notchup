//
//  PlaybackState.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

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
    var isShuffled: Bool? = nil
    var isRepeat: Bool? = nil
    var isLive: Bool? = nil
    var lastUpdate: Date = Date.distantFuture
}
