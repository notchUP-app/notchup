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
    
    var body: some View {
        VStack {
            Form {
                Defaults.Toggle("Enable Live Activities", key: .enableLiveActivities)
                    .disabled(true)
                
                if enableLiveActivities {
                    Section {
                        
                    } header: {
                        Text("Media")
                    }
                }
            }
            .formStyle(.grouped)
            .tint(Defaults[.accentColor])
        }
        .padding([.horizontal], 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
}

#Preview {
    LiveView()
}
