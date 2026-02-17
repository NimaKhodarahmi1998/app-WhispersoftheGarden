//
//  Poem.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 14/12/25.
//
import Foundation

struct Poem: Identifiable {
    let id: UUID
    let poet: String
    let persian: String
    let english: String
    let culturalNote: String
    let reflection: String
}
