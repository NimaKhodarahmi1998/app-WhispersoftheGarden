//
//  GardenProgressStore.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 28/12/25.
//

import Foundation

enum GardenProgressStore {
    
    private static let key = "discoveredPoemsIDs"
    
    static func load() -> Set<UUID> {
        guard
            let data = UserDefaults.standard.data (forKey: key),
            let strings = try? JSONDecoder().decode([String].self, from: data)
        else
        {
            return []
        }
        return Set(strings.compactMap(UUID.init(uuidString:)))
        }
    
    
    static func save(_ ids: Set<UUID>) {
        
        let strings = ids.map { $0.uuidString }
        guard let data = try? JSONEncoder().encode(strings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
