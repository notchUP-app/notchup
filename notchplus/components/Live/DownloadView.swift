//
//  DownloadView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 13/11/24.
//

import SwiftUI
import Foundation

enum Browser {
    case safari
    case chrome
}

struct DownloadFile {
    var name: String
    var size: Int
    var formattedSize: String
    var browser: Browser
}

class DownloadWatcher: ObservableObject {
    @Published var downloadFiles: [DownloadFile] = []
}

struct DownloadView: View {
    @EnvironmentObject var watcher: DownloadWatcher
    
    var body: some View {
        HStack(alignment: .center) {
            HStack {
                if watcher.downloadFiles.first!.browser == .safari {
                    AppIcon(for: "com.apple.safari")
                } else {
                    EmptyView()
                        .onAppear {
                            print(watcher.downloadFiles.first!.browser)
                        }
//                    Image(.chrome)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading) {
                    Text("Download")
                    Text("in progress")
                        .font(.system(.footnote))
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            HStack(spacing: 12) {
                VStack(alignment: .trailing) {
                    Text(watcher.downloadFiles.first!.formattedSize)
                    Text(watcher.downloadFiles.first!.name)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}
