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
                                VStack(alignment: .leading) {
                                    Text(controller.rawValue)
                                    Text(controllerDescription(controller))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(controller)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: mediaController) { _, _ in
                            NotificationCenter.default.post(
                                name: Notification.Name.mediaControllerChanged,
                                object: nil
                            )
                        }
                    } header: {
                        Text("Media")
                    } footer: {
                        Text(footerText)
                            .foregroundStyle(.secondary)
                            .font(.caption)
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
//               return MediaControllerType.allCases.filter { $0 != .nowPlaying }
               return MediaControllerType.allCases
           } else {
               return MediaControllerType.allCases
           }
       }
    
    private func controllerDescription(_ controller: MediaControllerType) -> String {
        switch controller {
        case .nowPlaying:
            return "Uses system MediaRemote (deprecated on macOS 15.0+)"
        case .appleMusic:
            return "Direct Apple Music integration via AppleScript"
        case .spotify:
            return "Direct Spotify integration via AppleScript"
        }
    }
    
    private var footerText: String {
        if MusicManager.shared.isNowPlayingDeprecated {
            return "Now Playing is deprecated on macOS 15.4+. Using Apple Music for better compatibility."
        } else {
            return "Choose your preferred music source for live activities."
        }
    }
    
}

#Preview {
    LiveView()
}
