//
//  MusicPlayerView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 11/04/25.
//

import SwiftUI

struct MusicPlayerView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        HStack {
            AlbumArtView(viewModel: viewModel, albumArtNamespace: albumArtNamespace)
            MusicControlsView()
                .drawingGroup()
                .compositingGroup()
        }
    }
}
