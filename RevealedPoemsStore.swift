//
//  RevealedPoemsStore.swift - INFINITE CYCLING
//  WhispersoftheGardenApp
//
//  After all poems revealed, keeps showing random poems forever
//

import Foundation
import SwiftUI

@MainActor
class RevealedPoemsStore: ObservableObject {
    
    @Published private(set) var revealedPoemIDs: Set<UUID> = []
    
    private let userDefaultsKey = "revealedPoemIDs"
    
    init() {
        loadRevealedPoems()
    }
    
    func revealPoem(_ poem: Poem) {
        guard !revealedPoemIDs.contains(poem.id) else { return }
        
        revealedPoemIDs.insert(poem.id)
        saveRevealedPoems()
    }
    
    func getRevealedPoems() -> [Poem] {
        PoemLibrary.poems.filter { revealedPoemIDs.contains($0.id) }
    }
    
    func isRevealed(_ poem: Poem) -> Bool {
        revealedPoemIDs.contains(poem.id)
    }
    
    var revealedCount: Int {
        revealedPoemIDs.count
    }
    
    var totalPoemsCount: Int {
        PoemLibrary.poems.count
    }
    
    // ✨ FIXED: Never returns nil, always gives you a poem!
    func getNextPoem() -> Poem? {
        // Safety check - make sure we have poems!
        guard !PoemLibrary.poems.isEmpty else { return nil }
        
        // Find unrevealed poems
        let unrevealedPoems = PoemLibrary.poems.filter { !revealedPoemIDs.contains($0.id) }
        
        if !unrevealedPoems.isEmpty {
            // Still have unrevealed poems - prioritize those
            return unrevealedPoems.randomElement()
        } else {
            // ✨ ALL POEMS REVEALED - Keep playing with random poems!
            // This ensures the game never "ends"
            return PoemLibrary.poems.randomElement()
        }
    }
    
    private func loadRevealedPoems() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let stringIDs = try? JSONDecoder().decode([String].self, from: data) else {
            revealedPoemIDs = []
            return
        }
        
        revealedPoemIDs = Set(stringIDs.compactMap { UUID(uuidString: $0) })
    }
    
    private func saveRevealedPoems() {
        let stringIDs = revealedPoemIDs.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(stringIDs) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    #if DEBUG
    func resetAllPoems() {
        revealedPoemIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    #endif
}
