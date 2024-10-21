//
//  MusicVisualizer.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 20/10/24.
//

import Foundation
import SwiftUI

class AudioSpectrum: NSView {
    private var barLayers: [CAShapeLayer] = []
    private var isPlaying: Bool = true
    private var animationTimer: Timer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBars()
    }
    
    private func setupBars() {
        let barWidth: CGFloat = 2
        let barCount: Int = 4
        let spacing: CGFloat = barWidth
        let totalWidth = CGFloat(barCount) * (barWidth + spacing)
        let totalHeight: CGFloat = 14
        frame.size = CGSize(width: totalWidth, height: totalHeight)
        
        for i in 0 ..< barCount {
            let xPos = CGFloat(i) * (barWidth + spacing)
            let barLayer = CAShapeLayer()
            
            barLayer.frame = CGRect(x: xPos, y: 0, width: barWidth, height: totalHeight)
            barLayer.position = CGPoint(x: xPos + barWidth / 2, y: totalHeight / 2)
            barLayer.fillColor = NSColor.white.cgColor
            
            let path = NSBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: barWidth, height: totalHeight),
                xRadius: barWidth / 2,
                yRadius: barWidth / 2
            )
            
            barLayer.path = path.cgPath
            barLayers.append(barLayer)
            layer?.addSublayer(barLayer)
        }
    }
    
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
        if isPlaying {
            startAnimation()
        } else {
            stopAnimation()
        }
    }
    
    private func updateBars() {
        for barLayer in barLayers {
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = barLayer.presentation()?.value(forKeyPath: "transform.scale.y") ?? 0.35
            animation.toValue = CGFloat.random(in: 0.35 ... 1.0)
            animation.duration = 0.3
            animation.autoreverses = true
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
            barLayer.add(animation, forKey: "scaleY")
        }
    }
    
    private func resetBars() {
        for barLayer in barLayers {
            barLayer.removeAllAnimations()
            barLayer.transform = CATransform3DMakeScale(1, 0.35, 1)
        }
    }
    
    private func startAnimation() {
        guard animationTimer == nil else { return }
        
        self.animationTimer = Timer.scheduledTimer(
            withTimeInterval: 0.3,
            repeats: true
        ) {
            [weak self] _ in
            self?.updateBars()
        }
    }
    
    private func stopAnimation() {
        self.animationTimer?.invalidate()
        self.animationTimer = nil
        resetBars()
    }
}

struct AudioSpectrumView: NSViewRepresentable {
    @Binding var isPlaying: Bool
    
    func makeNSView(context: Context) -> AudioSpectrum {
        let spectrum = AudioSpectrum()
        spectrum.setPlaying(isPlaying)
        return spectrum
    }
    
    func updateNSView(_ nsView: AudioSpectrum, context: Context) {
        nsView.setPlaying(isPlaying)
    }
}

#Preview {
    AudioSpectrumView(isPlaying: .constant(true))
        .frame(width: 16, height: 20)
        .padding(16)
}
