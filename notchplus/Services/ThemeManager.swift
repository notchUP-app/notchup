//
//  ThemeManager.swift
//  notchplus
//
//  Created by Assistant on 14/09/25.
//

import SwiftUI
import Defaults
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = Defaults[.appTheme]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen for theme changes
        Defaults.publisher(.appTheme)
            .sink { [weak self] theme in
                DispatchQueue.main.async {
                    self?.currentTheme = theme.newValue
                    self?.applyTheme(theme.newValue)
                }
            }
            .store(in: &cancellables)
        
        // Apply initial theme
        applyTheme(currentTheme)
    }
    
    private func applyTheme(_ theme: AppTheme) {
        Logger.log("Applying theme: \(theme.rawValue)", type: .ui)
        
        switch theme {
        case .standard:
            applyStandardTheme()
        case .liquidGlass:
            if #available(macOS 26.0, *) {
                applyLiquidGlassTheme()
            } else {
                Logger.log("Liquid Glass theme not available, falling back to standard", type: .warning)
                Defaults[.appTheme] = .standard
            }
        }
    }
    
    private func applyStandardTheme() {
        // Standard theme with solid backgrounds
        NSApp.appearance = NSAppearance(named: .aqua)
    }
    
    @available(macOS 26.0, *)
    private func applyLiquidGlassTheme() {
        // Apply liquid glass theme with enhanced translucency
        NSApp.appearance = NSAppearance(named: .vibrantLight)
    }
    
    // MARK: - Theme Properties
    
    var backgroundMaterial: Material {
        switch currentTheme {
        case .standard:
            return .regularMaterial
        case .liquidGlass:
            if #available(macOS 26.0, *) {
                return .ultraThinMaterial
            }
            return .regularMaterial
        }
    }
    
    var cornerRadius: CGFloat {
        switch currentTheme {
        case .standard:
            return 8.0
        case .liquidGlass:
            return 16.0
        }
    }
    
    var shadowRadius: CGFloat {
        switch currentTheme {
        case .standard:
            return 5.0
        case .liquidGlass:
            return 20.0
        }
    }
    
    var blurRadius: CGFloat {
        switch currentTheme {
        case .standard:
            return 10.0
        case .liquidGlass:
            return 30.0
        }
    }
    
    func notchBackgroundView() -> some View {
        Group {
            switch currentTheme {
            case .standard:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .shadow(radius: shadowRadius)
            case .liquidGlass:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 5)
            }
        }
    }
}

// MARK: - View Modifiers

struct ThemedBackground: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.notchBackgroundView())
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackground())
    }
}
