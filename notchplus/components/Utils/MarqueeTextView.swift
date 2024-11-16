//
//  MarqueeTextView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 03/11/24.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct MeasureSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { geo in
            Color.clear.preference(key: SizePreferenceKey.self, value: geo.size)
        })
    }
}

struct MarqueeText: View {
    var text: String
    let font: Font
    let nsFont: NSFont.TextStyle
    let textColor: Color
    let backgroundColor: Color
    let minDuration: Double
    let frameWidth: CGFloat
    
    @State var animate: Bool = false
    @State var textSize: CGSize = .zero
    @State var offset: CGFloat = 0
    
    init(_ text: String, font: Font = .body, nsFont: NSFont.TextStyle = .body, textColor: Color = .primary, backgroundColor: Color = .clear, minDuration: Double = 3.0, frameWidth: CGFloat = 200) {
        self.text = text
        self.font = font
        self.nsFont = nsFont
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.minDuration = minDuration
        self.frameWidth = frameWidth
    }
    
    private var needsScroll: Bool {
        textSize.width > frameWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: 20) {
                    Text(text)
                    Text(text)
                        .opacity(needsScroll ? 1 : 0)
                }
                .font(font)
                .foregroundColor(textColor)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: animate ? offset : 0)
                .animation(
                    animate ?
                        .linear(duration: Double(textSize.width / 30))
                        .delay(minDuration)
                        .repeatForever(autoreverses: false) : .none,
                    value: animate
                )
                .background(backgroundColor)
                .modifier(MeasureSizeModifier())
                .onPreferenceChange(SizePreferenceKey.self) { size in
                    self.textSize = CGSize(width: textSize.width / 2, height: NSFont.preferredFont(forTextStyle: nsFont).pointSize)
                }
                .onChange(of: text) {
                    offset = 0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if needsScroll {
                            offset = -(textSize.width + 10)
                            withAnimation {
                                animate = true
                            }
                        }
                    }
                }
                .onAppear {
                    withAnimation {
                        animate = true
                    }
                    
                    offset = 0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if needsScroll {
                            offset = -(textSize.width + 10)
                            withAnimation {
                                animate = true
                            }
                        }
                    }
                }
            }
            .frame(width: frameWidth, alignment: .leading)
            .clipped()
        }
        .frame(height: textSize.height * 1.3)
    }
}
