//
//  Ext+View.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 21/10/24.
//

import SwiftUI

enum PanDirection {
    case left
    case right
    case up
    case down
}

extension View {
    func panGesture(direction: PanDirection, action: @escaping (CGFloat, NSEvent.Phase) -> Void) -> some View {
        background(
            PanGestureView(direction: direction, action: action)
                .frame(maxWidth: 0, maxHeight: 0)
        )
    }
    
    @ViewBuilder func conditionalModifier<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func trackLifecycle(identifier: String) -> some View {
        self.modifier(ViewLifecycleTracker(identifier: identifier))
    }
}

struct PanGestureView: NSViewRepresentable {
    let direction: PanDirection
    let action: (CGFloat, NSEvent.Phase) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
            if event.window == view.window {
                context.coordinator.handleEvent(event)
            }
            
            return event
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(direction: self.direction, action: self.action)
    }
    
    class Coordinator: NSObject {
        let direction: PanDirection
        let action: (CGFloat, NSEvent.Phase) -> Void
        
        var accumulatedScrollDeltaX: CGFloat = 0
        var accumulatedScrollDeltaY: CGFloat = 0
        
        init(direction: PanDirection, action: @escaping (CGFloat, NSEvent.Phase) -> Void) {
            self.direction = direction
            self.action = action
        }
        
        @objc func handleEvent(_ event: NSEvent) {
            if event.type == .scrollWheel {
                accumulatedScrollDeltaX += event.scrollingDeltaX
                accumulatedScrollDeltaY += event.scrollingDeltaY
                
                switch direction {
                case .left:
                    if accumulatedScrollDeltaX < 0 {
                        handle()
                    }
                case .right:
                    if accumulatedScrollDeltaX > 0 {
                        handle()
                    }
                case .up:
                    if accumulatedScrollDeltaY < 0 {
                        handle()
                    }
                case .down:
                    if accumulatedScrollDeltaY > 0 {
                        handle()
                    }
                }
            }
            
            func handle() {
                if (direction == .left || direction == .right) {
                    action(abs(accumulatedScrollDeltaX), event.phase)
                } else {
                    action(abs(accumulatedScrollDeltaY), event.phase)
                }
            }
            
            if event.phase == .ended {
                accumulatedScrollDeltaX = 0
                accumulatedScrollDeltaY = 0
            }
        }
        
    }
}

extension View where Self: Shape {
    func glow(
        fill: some ShapeStyle,
        lineWidth: Double,
        blurRadius: Double = 8.0,
        lineCap: CGLineCap = .round
    ) -> some View {
        self
            .stroke(style: StrokeStyle(lineWidth: lineWidth/2, lineCap: lineCap))
            .fill(fill)
            .overlay(
                self
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
                    .fill(fill)
                    .blur(radius: blurRadius)
            )
            .overlay(
                self
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
                    .fill(fill)
                    .blur(radius: blurRadius/2)
            )
    }
}

struct ViewLifecycleTracker: ViewModifier {
    let identifier: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Logger.log("\(identifier) appeared", type: .lifecycle)
                Logger.trackMemoryUsage()
            }
            .onDisappear {
                Logger.log("\(identifier) disappeared", type: .lifecycle)
                Logger.trackMemoryUsage()
            }
    }
}
