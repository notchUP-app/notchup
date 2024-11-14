//
//  LaunchAnimation.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 10/11/24.
//

import SwiftUI
import AppKit

// MARK: Animation side lines shapes
struct RightLaunchAnimationShape: Shape {
    let width = screenSize.width
    let height = screenSize.height
    let safeAreaInsets = screenSize.insets
    let topCornerRadius: CGFloat = 5
    var bottomCornerRadius: CGFloat
    
    init(cornerRadius: CGFloat? = nil) {
        if cornerRadius == nil {
            self.bottomCornerRadius = 10
        } else {
            self.bottomCornerRadius = cornerRadius!
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // BOTTOM CENTER
        path.move(to: CGPoint(x: width! / 2, y: height!))
        
        // BOTTOM CENTER -> BOTTOM RIGHT
        path.addLine(to: CGPoint(x: width! - safeAreaInsets!.right, y: height!))
        
        // BOTTOM RIGHT -> TOP RIGHT
        path.addLine(to: CGPoint(x: width! - safeAreaInsets!.right, y: 1))
        
        // TOP RIGHT -> NOTCH RIGHT
        path.addLine(to: CGPoint(x: (width! / 2) + (Sizes().size.closed.width! / 2), y: 1))
        
        // NOTCH RIGHT OUTER CURVE
        //        path.addQuadCurve(
        //            to: CGPoint(
        //                x: (width! / 2) + (Sizes().size.closed.width! / 2),
        //                y: 1
        //            ),
        //            control: CGPoint(
        //                x: ((width! / 2) + (Sizes().size.closed.width! / 2) + topCornerRadius),
        //                y: 1
        //            )
        //        )
        path.addQuadCurve(
            to: CGPoint(
                x: (width! / 2) + (Sizes().size.closed.width! / 2) - topCornerRadius,
                y: topCornerRadius
            ),
            control: CGPoint(
                x: (width! / 2) + (Sizes().size.closed.width! / 2) - topCornerRadius,
                y: 1
            )
        )
        
        // RIGHT NOTCH SIDE
        path.addLine(
            to: CGPoint(
                x: (width! / 2) + (Sizes().size.closed.width! / 2) - topCornerRadius,
                y: Sizes().size.closed.height! - bottomCornerRadius
            )
        )
        
        // NOTCH RIGHT INNER CURVE
        path.addQuadCurve(
            to: CGPoint(
                x: (width! / 2) + (Sizes().size.closed.width! / 2) - bottomCornerRadius * 2,
                y: Sizes().size.closed.height!
            ),
            control: CGPoint(
                x: (width! / 2) + (Sizes().size.closed.width! / 2) - topCornerRadius,
                y: Sizes().size.closed.height!
            )
        )
        
        // NOTCH HALF RIGHT BOTTOM
        path.addLine(
            to: CGPoint(
                x: (width! / 2) - 8,
                y: Sizes().size.closed.height!
            )
        )
        
        return path
    }
}

struct LeftLaunchAnimationShape: Shape {
    let width = screenSize.width
    let height = screenSize.height
    let safeAreaInsets = screenSize.insets
    let topCornerRadius: CGFloat = 5
    var bottomCornerRadius: CGFloat
    
    init(cornerRadius: CGFloat? = nil) {
        if cornerRadius == nil {
            self.bottomCornerRadius = 10
        } else {
            self.bottomCornerRadius = cornerRadius!
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // BOTTOM CENTER
        path.move(to: CGPoint(x: width! / 2, y: height!))
        
        // BOTTOM CENTER -> BOTTOM LEFT
        path.addLine(to: CGPoint(x: safeAreaInsets!.left, y: height!))
        
        // BOTTOM LEFT -> TOP LEFT
        path.addLine(to: CGPoint(x: safeAreaInsets!.left, y: 1))
        
        // TOP LEFT -> NOTCH LEFT
        path.addLine(to: CGPoint(x: (width! / 2) - (Sizes().size.closed.width! / 2), y: 1))
        
        // NOTCH LEFT OUTER CURVE
        path.addQuadCurve(
            to: CGPoint(
                x: (width! / 2) - (Sizes().size.closed.width! / 2) + topCornerRadius,
                y: topCornerRadius
            ),
            control: CGPoint(
                x: (width! / 2) - (Sizes().size.closed.width! / 2) + topCornerRadius,
                y: 1
            )
        )
        
        // LEFT NOTCH SIDE
        path.addLine(
            to: CGPoint(
                x: (width! / 2) - (Sizes().size.closed.width! / 2) + topCornerRadius,
                y: Sizes().size.closed.height! - bottomCornerRadius
            )
        )
        
        // NOTCH LEFT INNER CURVE
        path.addQuadCurve(
            to: CGPoint(
                x: (width! / 2) - (Sizes().size.closed.width! / 2) + bottomCornerRadius * 2,
                y: Sizes().size.closed.height!
            ),
            control: CGPoint(
                x: (width! / 2) - (Sizes().size.closed.width! / 2) + topCornerRadius,
                y: Sizes().size.closed.height!
            )
        )
        
        // NOTCH HALF LEFT BOTTOM
        path.addLine(
            to: CGPoint(
                x: (width! / 2) + 8,
                y: Sizes().size.closed.height!
            )
        )
        
        return path
    }
}

// MARK: Line animations
struct FollowingLine<Content: Shape, Fill: ShapeStyle>: View, Animatable {
    var progress: Double
    var delay: Double = 1.0
    var fill: Fill
    var lineWith: CGFloat = 4.0
    var blurRadius: CGFloat = 8.0
    
    @ViewBuilder var shape: Content
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    var body: some View {
        shape
            .trim(
                from: {
                    if progress > 1 - delay {
                        2 * progress - 1
                    } else if progress > delay {
                        progress - delay
                    } else {
                        .zero
                    }
                    
                }(),
                to: progress
            )
            .glow(fill: fill, lineWidth: lineWith, blurRadius: blurRadius)
    }
}

struct LaunchAnimation: View {
    @State private var progress: Double = 0.0
    private var lineWIdth: CGFloat = 5.0
    @State private var blurRadius: CGFloat = 12.0
    @State private var animationDuration: Double = 6.0
    
    var body: some View {
        ZStack {
            FollowingLine(
                progress: progress,
                fill: .hello,
                lineWith: lineWIdth,
                blurRadius: blurRadius,
                shape: { RightLaunchAnimationShape() }
            ).onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
//                    .repeatForever(autoreverses: true)
                ) {
                    progress = 1.0
                }
            }
            
            FollowingLine(
                progress: progress,
                fill: .hello,
                lineWith: lineWIdth,
                blurRadius: blurRadius,
                shape: { LeftLaunchAnimationShape() }
            ).onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
//                    .repeatForever(autoreverses: true)
                ) {
                    progress = 1.0
                }
            }
        }
    }
}

class LaunchAnimationViewController: NSViewController {
    var onComplete: (() -> Void)?
    
    override func loadView() {
        view = NSHostingView(rootView: LaunchAnimation())
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            self.onComplete?()
        }
    }
}

struct LaunchAnimationView: NSViewControllerRepresentable {
    var onComplete: (() -> Void)?
    
    func makeNSViewController(context: Context) -> LaunchAnimationViewController {
        let viewController = LaunchAnimationViewController()
        viewController.onComplete = onComplete
        return viewController
    }
    
    func updateNSViewController(_ nsController: LaunchAnimationViewController, context: Context) {}
}

#Preview {
    LaunchAnimationView()
        .frame(width: screenSize.width!, height: screenSize.height!)
}