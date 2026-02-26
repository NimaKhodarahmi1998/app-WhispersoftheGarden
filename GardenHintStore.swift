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
    case tapPool, tapLilyPad, dragPool
    case tapNightingale
    case visitLibrary, exploreLibrary, returnToGarden
}

@MainActor
class GardenHintStore: ObservableObject {

    @Published private(set) var hasEverTappedPool: Bool
    @Published private(set) var hasEverTappedPad: Bool
    @Published private(set) var hasEverDraggedPool: Bool
    @Published private(set) var hasEverTappedNightingale: Bool
    @Published private(set) var hasEverVisitedLibrary: Bool
    @Published private(set) var hasEverExploredLibrary: Bool
    @Published private(set) var hasEverReturnedToGarden: Bool

    private enum Keys {
        static let pool = "hint_tappedPool"
        static let pad  = "hint_tappedPad"
        static let dragPool = "hint_draggedPool"
        static let nightingale = "hint_tappedNightingale"
        static let visitedLibrary = "hint_visitedLibrary"
        static let exploredLibrary = "hint_exploredLibrary"
        static let returnedToGarden = "hint_returnedToGarden"
    }

    init() {
        hasEverTappedPool        = UserDefaults.standard.bool(forKey: Keys.pool)
        hasEverTappedPad         = UserDefaults.standard.bool(forKey: Keys.pad)
        hasEverDraggedPool       = UserDefaults.standard.bool(forKey: Keys.dragPool)
        hasEverTappedNightingale = UserDefaults.standard.bool(forKey: Keys.nightingale)
        hasEverVisitedLibrary    = UserDefaults.standard.bool(forKey: Keys.visitedLibrary)
        hasEverExploredLibrary   = UserDefaults.standard.bool(forKey: Keys.exploredLibrary)
        hasEverReturnedToGarden  = UserDefaults.standard.bool(forKey: Keys.returnedToGarden)
    }

    /// True only when the entire onboarding is done (including library visit + return).
    var isTutorialComplete: Bool { activeHint == nil }

    var activeHint: GardenHintStage? {
        if !hasEverTappedPool        { return .tapPool }
        if !hasEverTappedPad         { return .tapLilyPad }
        if !hasEverDraggedPool       { return .dragPool }
        if !hasEverTappedNightingale { return .tapNightingale }
        if !hasEverVisitedLibrary    { return .visitLibrary }
        if !hasEverExploredLibrary   { return .exploreLibrary }
        if !hasEverReturnedToGarden  { return .returnToGarden }
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

    func markPoolDragged() {
        guard hasEverTappedPad, !hasEverDraggedPool else { return }
        hasEverDraggedPool = true
        UserDefaults.standard.set(true, forKey: Keys.dragPool)
    }

    func markNightingaleTapped() {
        guard !hasEverTappedNightingale else { return }
        hasEverTappedNightingale = true
        UserDefaults.standard.set(true, forKey: Keys.nightingale)
    }

    func markLibraryVisited() {
        guard hasEverTappedNightingale, !hasEverVisitedLibrary else { return }
        hasEverVisitedLibrary = true
        UserDefaults.standard.set(true, forKey: Keys.visitedLibrary)
    }

    func markLibraryExplored() {
        guard hasEverVisitedLibrary, !hasEverExploredLibrary else { return }
        hasEverExploredLibrary = true
        UserDefaults.standard.set(true, forKey: Keys.exploredLibrary)
    }

    func markReturnedToGarden() {
        guard hasEverExploredLibrary, !hasEverReturnedToGarden else { return }
        hasEverReturnedToGarden = true
        UserDefaults.standard.set(true, forKey: Keys.returnedToGarden)
    }

    #if DEBUG
    func resetAllHints() {
        hasEverTappedPool = false
        hasEverTappedPad = false
        hasEverDraggedPool = false
        hasEverTappedNightingale = false
        hasEverVisitedLibrary = false
        hasEverExploredLibrary = false
        hasEverReturnedToGarden = false
        UserDefaults.standard.removeObject(forKey: Keys.pool)
        UserDefaults.standard.removeObject(forKey: Keys.pad)
        UserDefaults.standard.removeObject(forKey: Keys.dragPool)
        UserDefaults.standard.removeObject(forKey: Keys.nightingale)
        UserDefaults.standard.removeObject(forKey: Keys.visitedLibrary)
        UserDefaults.standard.removeObject(forKey: Keys.exploredLibrary)
        UserDefaults.standard.removeObject(forKey: Keys.returnedToGarden)
    }
    #endif
}
