//
//  PlaybackManager.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 19/10/24.
//

import SwiftUI
import Combine
import AppKit

class PlaybackManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var MrMediaRemoteSendCommandFunction: @convention(c) (Int, AnyObject?) -> Void
    
    private func handleLoadMediaHandlerApis() {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else { return }
        
        guard let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) else { return }
        
        typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, AnyObject?) -> Void
        
        MrMediaRemoteSendCommandFunction = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: MRMediaRemoteSendCommandFunction.self)
    }
    
    deinit {
        self.MrMediaRemoteSendCommandFunction = {_, _ in}
    }
    
    init() {
        self.isPlaying = false
        self.MrMediaRemoteSendCommandFunction = {_, _ in}
        handleLoadMediaHandlerApis()
    }
    
    func playPause() -> Bool {
        if self.isPlaying {
            MrMediaRemoteSendCommandFunction(2, nil)
            self.isPlaying = false
            return false
        } else {
            MrMediaRemoteSendCommandFunction(0, nil)
            self.isPlaying = true
            return true
        }
    }
    
    func nextTrack() {
        MrMediaRemoteSendCommandFunction(4, nil)
    }
    
    func previousTrack() {
        MrMediaRemoteSendCommandFunction(5, nil)
    }
}
