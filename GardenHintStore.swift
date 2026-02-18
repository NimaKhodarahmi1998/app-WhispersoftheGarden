//
//  GardenHintStore.swift
//  WhispersoftheGardenApp
//
//  Tracks which garden interactions the user has discovered.
//  Hints show until each action is performed once, then never again.
//

import Foundation
import SwiftUI

enum GardenHintStage {
    case tapPool, tapLilyPad, tapNightingale
}

@MainActor
class GardenHintStore: ObservableObject {

    @Published private(set) var hasEverTappedPool: Bool
    @Published private(set) var hasEverTappedPad: Bool
    @Published private(set) var hasEverTappedNightingale: Bool

    private enum Keys {
        static let pool = "hint_tappedPool"
        static let pad  = "hint_tappedPad"
        static let nightingale = "hint_tappedNightingale"
    }

    init() {
        hasEverTappedPool        = UserDefaults.standard.bool(forKey: Keys.pool)
        hasEverTappedPad         = UserDefaults.standard.bool(forKey: Keys.pad)
        hasEverTappedNightingale = UserDefaults.standard.bool(forKey: Keys.nightingale)
    }

    var activeHint: GardenHintStage? {
        if !hasEverTappedPool        { return .tapPool }
        if !hasEverTappedPad         { return .tapLilyPad }
        if !hasEverTappedNightingale { return .tapNightingale }
        return nil
    }

    func markPoolTapped() {
        guard !hasEverTappedPool else { return }
        hasEverTappedPool = true
        UserDefaults.standard.set(true, forKey: Keys.pool)
    }

    func markPadTapped() {
        guard !hasEverTappedPad else { return }
        hasEverTappedPad = true
        UserDefaults.standard.set(true, forKey: Keys.pad)
    }

    func markNightingaleTapped() {
        guard !hasEverTappedNightingale else { return }
        hasEverTappedNightingale = true
        UserDefaults.standard.set(true, forKey: Keys.nightingale)
    }

    #if DEBUG
    func resetAllHints() {
        hasEverTappedPool = false
        hasEverTappedPad = false
        hasEverTappedNightingale = false
        UserDefaults.standard.removeObject(forKey: Keys.pool)
        UserDefaults.standard.removeObject(forKey: Keys.pad)
        UserDefaults.standard.removeObject(forKey: Keys.nightingale)
    }
    #endif
}
