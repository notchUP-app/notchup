//
//  HoverButton.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 04/11/24.
//

import SwiftUI

struct HoverButton: View {
    var icon: String
    var iconColor: Color = .white
    var action: () -> Void
    var contentTransition: ContentTransition = .symbolEffect
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .frame(width: 30, height: 30)
                .overlay {
                    Capsule()
                        .fill(isHovering ? Color.gray.opacity(0.3) : .clear)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: icon)
                                .foregroundColor(iconColor)
                                .contentTransition(contentTransition)
                                .imageScale(.medium)
                        }
                }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.3)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    HoverButton(icon: "play.fill") {
        print("OK")
    }
}
