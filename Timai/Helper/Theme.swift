//
//  Theme.swift
//  Timai
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Color Theme
extension Color {
    /// Timai background color - adaptive für Light/Dark Mode
    static let timaiGray = Color(light: Color(red: 244/255, green: 244/255, blue: 247/255),
                                  dark: Color(red: 28/255, green: 28/255, blue: 30/255))
    
    /// Timai card background color - adaptive für Light/Dark Mode
    static let timaiCardBackground = Color(light: .white,
                                            dark: Color(red: 44/255, green: 44/255, blue: 46/255))
    
    /// Timai highlight color (blue from login screen)
    static let timaiHighlight = Color(red: 0.2, green: 0.5, blue: 0.9)
    
    /// Timai primary text color - adaptive für Light/Dark Mode
    static let timaiTextBlack = Color(light: Color(red: 0/255, green: 0/255, blue: 0/255),
                                       dark: Color(red: 255/255, green: 255/255, blue: 255/255))
    
    /// Timai highlight text color
    static let timaiHighlightText = Color(red: 0.2, green: 0.5, blue: 0.9)
    
    /// Timai subheader text color - adaptive für Light/Dark Mode
    static let timaiSubheaderColor = Color(light: Color(red: 66/255, green: 66/255, blue: 66/255),
                                            dark: Color(red: 174/255, green: 174/255, blue: 178/255))
    
    /// Timai table view section header color - adaptive für Light/Dark Mode
    static let timaiTableViewHeaderColor = Color(light: Color(red: 137/255, green: 137/255, blue: 138/255),
                                                  dark: Color(red: 142/255, green: 142/255, blue: 147/255))
    
    /// Timai gray tone 1 - adaptive für Light/Dark Mode
    static let timaiGrayTone1 = Color(light: Color(red: 225/255, green: 225/255, blue: 225/255),
                                       dark: Color(red: 58/255, green: 58/255, blue: 60/255))
    
    /// Timai gray tone 2 - adaptive für Light/Dark Mode
    static let timaiGrayTone2 = Color(light: Color(red: 142/255, green: 142/255, blue: 142/255),
                                       dark: Color(red: 142/255, green: 142/255, blue: 147/255))
    
    /// Timai gray tone 3 - adaptive für Light/Dark Mode
    static let timaiGrayTone3 = Color(light: Color(red: 66/255, green: 66/255, blue: 66/255),
                                       dark: Color(red: 174/255, green: 174/255, blue: 178/255))
}

// MARK: - Color Helper für Light/Dark Mode
extension Color {
    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #elseif os(macOS)
        // macOS: Verwende NSColor mit dynamischer Appearance
        // Konvertiere SwiftUI Colors zu CGColor für die Konvertierung
        let lightCG = light.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let darkCG = dark.cgColor ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        let lightNS = NSColor(cgColor: lightCG) ?? NSColor.white
        let darkNS = NSColor(cgColor: darkCG) ?? NSColor.black
        
        self.init(NSColor(name: nil) { appearance in
            switch appearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return darkNS
            default:
                return lightNS
            }
        })
        #else
        // Fallback für andere Plattformen
        self = light
        #endif
    }
}

#if os(macOS)
extension Color {
    var cgColor: CGColor? {
        let nsColor = NSColor(self)
        return nsColor.cgColor
    }
}
#endif

// MARK: - Theme Management
enum AppThemeMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system:
            return "settings.theme.system".localized()
        case .light:
            return "settings.theme.light".localized()
        case .dark:
            return "settings.theme.dark".localized()
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppThemeMode {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
            print("🎨 [ThemeManager] Theme gewechselt zu: \(currentTheme.displayName)")
        }
    }
    
    private init() {
        // Lade gespeichertes Theme oder verwende System als Standard
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppThemeMode(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
        print("🎨 [ThemeManager] Initialisiert mit Theme: \(currentTheme.displayName)")
    }
}

// MARK: - Language Management
enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .german:
            return "Deutsch"
        case .english:
            return "English"
        }
    }
}

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            Bundle.setLanguage(currentLanguage.rawValue)
            print("🌍 [LanguageManager] Sprache gewechselt zu: \(currentLanguage.displayName)")
        }
    }
    
    private init() {
        // Lade gespeicherte Sprache oder verwende System-Sprache
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
            Bundle.setLanguage(language.rawValue)
        } else {
            // Verwende System-Sprache als Standard
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            if let language = AppLanguage(rawValue: systemLanguage) {
                self.currentLanguage = language
            } else {
                self.currentLanguage = .english
            }
        }
        print("🌍 [LanguageManager] Initialisiert mit Sprache: \(currentLanguage.displayName)")
    }
    
    func localizedString(_ key: String) -> String {
        return key.localizedString(for: currentLanguage)
    }
}

// MARK: - Bundle Extension für Sprachumschaltung
private var bundleKey: UInt8 = 0

extension Bundle {
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, PrivateBundle.self)
        }
        objc_setAssociatedObject(Bundle.main, &bundleKey, language, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    class PrivateBundle: Bundle {
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            guard let language = objc_getAssociatedObject(self, &bundleKey) as? String,
                  let path = Bundle.main.path(forResource: language, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                return super.localizedString(forKey: key, value: value, table: tableName)
            }
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
    }
}

// MARK: - String Extensions
extension String {
    /// Returns the corresponding NSLocalizedString with support for runtime language switching
    public func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedString(for language: AppLanguage) -> String {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}

