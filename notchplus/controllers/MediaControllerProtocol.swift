//
//  MediaControllerProtocol.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

import Foundation
import AppKit

protocol MediaControllerProtocol: ObservableObject {
    var playbackStatePublisher: Published<PlaybackState>.Publisher { get }
    func play()
    func pause()
    func seek(to time: Double)
    func next()
    func previous()
    func togglePlay()
    func isActive() -> Bool
    func updatePlaybackInfo()
}
