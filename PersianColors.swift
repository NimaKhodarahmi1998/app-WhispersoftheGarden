//
//  PersianColors.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 14/12/25.
//

import SwiftUI

extension Color {
    // Tile & overlay accents (used by GardenHintView, PoemOverlayView)
    static let persianTurquoise = Color(red: 0.17, green: 0.64, blue: 0.63)
    static let persianSaffron   = Color(red: 0.95, green: 0.78, blue: 0.45)
    static let persianPomegranate = Color(red: 0.60, green: 0.12, blue: 0.17)
    static let persianIndigo = Color(red: 0.15, green: 0.17, blue: 0.31)
    static let persianSand = Color(red: 0.92, green: 0.88, blue: 0.77)
    static let persianGold = Color(red: 0.98, green: 0.88, blue: 0.55)

    // Shared UI palette (tab bar, options, navigation)
    static let gardenGold = Color(red: 1.0, green: 0.92, blue: 0.65)
    static let gardenDarkGold = Color(red: 0.92, green: 0.78, blue: 0.48)
    static let gardenDimGold = Color(red: 0.7, green: 0.6, blue: 0.4)
    static let gardenRose = Color(red: 0.9, green: 0.4, blue: 0.5)
    static let gardenDeepBlue = Color(red: 0.03, green: 0.08, blue: 0.18)
    static let gardenLighterBlue = Color(red: 0.06, green: 0.13, blue: 0.26)
    static let gardenNavy = Color(red: 0, green: 32/255, blue: 72/255)
}

// MARK: - Adaptive Color Palette (shared across Library, Options, PoemDetail)

struct AdaptiveColors {
    let bgBase: Color
    let cardColor: Color
    let gold: Color
    let darkGold: Color
    let rose: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    init(colorScheme: ColorScheme) {
        let isDark = colorScheme == .dark
        bgBase = isDark
            ? Color(red: 0.04, green: 0.06, blue: 0.14)
            : Color(red: 0.96, green: 0.93, blue: 0.87)
        cardColor = isDark
            ? Color(red: 0.95, green: 0.88, blue: 0.7).opacity(0.06)
            : Color(red: 0.91, green: 0.86, blue: 0.78).opacity(0.45)
        gold = isDark
            ? Color(red: 1.0, green: 0.85, blue: 0.55)
            : Color(red: 0.72, green: 0.56, blue: 0.18)
        darkGold = isDark
            ? Color(red: 0.92, green: 0.78, blue: 0.48)
            : Color(red: 0.65, green: 0.48, blue: 0.15)
        rose = isDark
            ? Color(red: 0.9, green: 0.4, blue: 0.5)
            : Color(red: 0.75, green: 0.28, blue: 0.38)
        textPrimary = isDark ? .white : Color(red: 0.15, green: 0.12, blue: 0.08)
        textSecondary = textPrimary.opacity(0.6)
        textTertiary = textPrimary.opacity(0.35)
    }
}
