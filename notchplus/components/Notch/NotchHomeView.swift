//
//  NotchHomeView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 03/11/24.
//

import SwiftUI
import Combine
import Defaults

struct NotchHomeView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var coordinator = NotchViewCoordinator.shared
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        Group {
            if !coordinator.firstLaunch {
                HStack(alignment: .top, spacing: 20) {
                    MusicPlayerView(albumArtNamespace: albumArtNamespace)
                    
                    if Defaults[.dropBoxByDefault] {
                        Spacer()
                        NotchDropView()
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .blurReplace))
    }
}
