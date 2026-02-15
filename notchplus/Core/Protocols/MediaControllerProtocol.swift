//
//  MediaControllerProtocol.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

import Foundation
import AppKit
import Combine

protocol MediaControllerProtocol: ObservableObject {
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { get }
    var supportsVolumeControls: Bool { get }
    var supportsFavorite: Bool { get }
    
    func play() async
    func pause() async
    func seek(to time: Double) async
    func next() async
    func previous() async
    func togglePlay() async
    func toggleShuffle() async
    func toggleRepeat() async
    func setVolume(to level: Double) async
    func setFavorite(_ favorite: Bool) async
    func isActive() -> Bool
    func updatePlaybackInfo() async
}
