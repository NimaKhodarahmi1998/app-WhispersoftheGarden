//
//  GardenHintStore.swift
//  WhispersoftheGardenApp
//
//  Tracks which garden interactions the user has discovered.
//  Hints show until each action is performed once, then never again.
//

import Foundation
import SwiftUI

enum GardenHintStage: Equatable {
    case tapPool, tapLilyPad
    case tapPoolAgain, tapSecondLilyPad
    case tapPoolThrice, tapThirdLilyPad
    case tapNightingale
}

@MainActor
class GardenHintStore: ObservableObject {

    @Published private(set) var hasEverTappedPool: Bool
    @Published private(set) var hasEverTappedPad: Bool
    @Published private(set) var hasEverTappedPoolAgain: Bool
    @Published private(set) var hasEverTappedSecondPad: Bool
    @Published private(set) var hasEverTappedPoolThrice: Bool
    @Published private(set) var hasEverTappedThirdPad: Bool
    @Published private(set) var hasEverTappedNightingale: Bool

    private enum Keys {
        static let pool = "hint_tappedPool"
        static let pad  = "hint_tappedPad"
        static let poolAgain = "hint_tappedPoolAgain"
        static let secondPad = "hint_tappedSecondPad"
        static let poolThrice = "hint_tappedPoolThrice"
        static let thirdPad = "hint_tappedThirdPad"
        static let nightingale = "hint_tappedNightingale"
    }

    init() {
        hasEverTappedPool        = UserDefaults.standard.bool(forKey: Keys.pool)
        hasEverTappedPad         = UserDefaults.standard.bool(forKey: Keys.pad)
        hasEverTappedPoolAgain   = UserDefaults.standard.bool(forKey: Keys.poolAgain)
        hasEverTappedSecondPad   = UserDefaults.standard.bool(forKey: Keys.secondPad)
        hasEverTappedPoolThrice  = UserDefaults.standard.bool(forKey: Keys.poolThrice)
        hasEverTappedThirdPad    = UserDefaults.standard.bool(forKey: Keys.thirdPad)
        hasEverTappedNightingale = UserDefaults.standard.bool(forKey: Keys.nightingale)
    }

    var isTutorialComplete: Bool { activeHint == nil }

    var activeHint: GardenHintStage? {
        if !hasEverTappedPool        { return .tapPool }
        if !hasEverTappedPad         { return .tapLilyPad }
        if !hasEverTappedPoolAgain   { return .tapPoolAgain }
        if !hasEverTappedSecondPad   { return .tapSecondLilyPad }
        if !hasEverTappedPoolThrice  { return .tapPoolThrice }
        if !hasEverTappedThirdPad    { return .tapThirdLilyPad }
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

    func markPoolTappedAgain() {
        guard hasEverTappedPad, !hasEverTappedPoolAgain else { return }
        hasEverTappedPoolAgain = true
        UserDefaults.standard.set(true, forKey: Keys.poolAgain)
    }

    func markSecondPadTapped() {
        guard hasEverTappedPoolAgain, !hasEverTappedSecondPad else { return }
        hasEverTappedSecondPad = true
        UserDefaults.standard.set(true, forKey: Keys.secondPad)
    }

    func markPoolTappedThrice() {
        guard hasEverTappedSecondPad, !hasEverTappedPoolThrice else { return }
        hasEverTappedPoolThrice = true
        UserDefaults.standard.set(true, forKey: Keys.poolThrice)
    }

    func markThirdPadTapped() {
        guard hasEverTappedPoolThrice, !hasEverTappedThirdPad else { return }
        hasEverTappedThirdPad = true
        UserDefaults.standard.set(true, forKey: Keys.thirdPad)
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
        hasEverTappedPoolAgain = false
        hasEverTappedSecondPad = false
        hasEverTappedPoolThrice = false
        hasEverTappedThirdPad = false
        hasEverTappedNightingale = false
        UserDefaults.standard.removeObject(forKey: Keys.pool)
        UserDefaults.standard.removeObject(forKey: Keys.pad)
        UserDefaults.standard.removeObject(forKey: Keys.poolAgain)
        UserDefaults.standard.removeObject(forKey: Keys.secondPad)
        UserDefaults.standard.removeObject(forKey: Keys.poolThrice)
        UserDefaults.standard.removeObject(forKey: Keys.thirdPad)
        UserDefaults.standard.removeObject(forKey: Keys.nightingale)
    }
    #endif
}
