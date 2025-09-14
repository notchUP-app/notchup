//
//  LiveView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 22/03/25.
//

import SwiftUI
import Defaults

struct LiveView: View {
    
    @Default(.enableLiveActivities) private var enableLiveActivities
    @Default(.preferredMediaController) var mediaController
    @ObservedObject var coordinator = NotchViewCoordinator.shared
    
    var body: some View {
        VStack {
            Form {
                Defaults.Toggle("Enable Live Activities", key: .enableLiveActivities)
                
                if enableLiveActivities {
                    Section {
                        Picker("Music Source", selection: $mediaController) {
                            ForEach(availableMediaControllers) { controller in
                                Text(controller.rawValue).tag(controller)
                            }
                        }
                        .onChange(of: mediaController) { _, _ in
                            NotificationCenter.default.post(
                                name: Notification.Name.mediaControllerChanged,
                                object: nil
                            )
                        }
                    } header: {
                        Text("Media")
                    } footer: {
                        if mediaController == .nowPlaying {
                            Text("Now Playing is only supported on macOS 15.3 and previous versions.")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .tint(Defaults[.accentColor])
        }
        .padding([.horizontal], 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var availableMediaControllers: [MediaControllerType] {
           if MusicManager.shared.isNowPlayingDeprecated {
               return MediaControllerType.allCases.filter { $0 != .nowPlaying }
           } else {
               return MediaControllerType.allCases
           }
       }
    
}

#Preview {
    LiveView()
}
