//
//  GesturesView.swift
//  notchplus
//
//  Created by Assistant on 14/09/25.
//

import SwiftUI
import Defaults

struct GesturesView: View {
    @Default(.enableGestures) private var enableGestures
    @Default(.closeGestureEnabled) private var closeGestureEnabled
    @Default(.gestureSensitivity) private var gestureSensitivity
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Defaults.Toggle("Enable gestures", key: .enableGestures)
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                } header: {
                    Text("Gesture Control")
                        .fontWeight(.semibold)
                } footer: {
                    Text("Enable gesture controls for the notch interface")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if enableGestures {
                    Section {
                        Defaults.Toggle("Close gesture", key: .closeGestureEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                        
                        HStack {
                            Text("Gesture sensitivity")
                            Spacer()
                            Slider(value: $gestureSensitivity, in: 50...500, step: 25)
                                .frame(width: 120)
                            Text("\(Int(gestureSensitivity))")
                                .frame(width: 40)
                        }
                    } header: {
                        Text("Gesture Settings")
                            .fontWeight(.semibold)
                    } footer: {
                        Text("Adjust gesture sensitivity. Lower values require more precise movements.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            gestureHelpItem(
                                gesture: "Swipe Up",
                                description: "Open the notch interface",
                                icon: "arrow.up"
                            )
                            
                            gestureHelpItem(
                                gesture: "Swipe Down",
                                description: "Close the notch interface",
                                icon: "arrow.down",
                                enabled: closeGestureEnabled
                            )
                            
                            gestureHelpItem(
                                gesture: "Click",
                                description: "Interact with notch elements",
                                icon: "hand.tap"
                            )
                            
                            gestureHelpItem(
                                gesture: "Hover",
                                description: "Auto-open notch on hover",
                                icon: "cursorarrow.rays",
                                enabled: Defaults[.openNotchOnHover]
                            )
                        }
                    } header: {
                        Text("Available Gestures")
                            .fontWeight(.semibold)
                    }
                }
            }
            .formStyle(.grouped)
            .tint(Defaults[.accentColor])
        }
        .padding([.horizontal], 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    @ViewBuilder
    private func gestureHelpItem(gesture: String, description: String, icon: String, enabled: Bool = true) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(enabled ? .accentColor : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(gesture)
                    .font(.headline)
                    .foregroundColor(enabled ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !enabled {
                Text("Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .opacity(enabled ? 1.0 : 0.6)
    }
}

#Preview {
    GesturesView()
}
