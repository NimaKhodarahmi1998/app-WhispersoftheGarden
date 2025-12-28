//
//  PoemLibrary.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 14/12/25.
//

import Foundation

struct PoemLibrary {

    static let poems: [Poem] = [

        Poem(
            id: UUID(),
            persian: "بنی آدم اعضای یکدیگرند",
            english: "Human beings are members of a whole.",
            culturalNote: "Saʿdi emphasizes shared humanity as the foundation of ethics.",
            reflection: "Gentleness toward yourself is a form of care for others."
        ),

        Poem(
            id: UUID(),
            persian: "راهی‌ست راه عشق که هیچش کناره نیست",
            english: "The path of love has no edge, no final shore.",
            culturalNote: "Persian mysticism often rejects the idea of final arrival.",
            reflection: "You are not meant to finish becoming — only to continue."
        ),

        Poem(
            id: UUID(),
            persian: "این قافلهٔ عمر عجب می‌گذرد",
            english: "How strangely this caravan of life passes by.",
            culturalNote: "Khayyam reflects on impermanence and presence.",
            reflection: "Hope lives in attention to this moment."
        ),

        Poem(
            id: UUID(),
            persian: "دیروز من هوشیار بودم، امروز دیوانه‌ام",
            english: "Yesterday I was clever, today I am mad.",
            culturalNote: "Rumi embraces transformation through surrender.",
            reflection: "Growth begins when control loosens."
        ),

        Poem(
            id: UUID(),
            persian: "دل می‌رود ز دستم، صاحبدلان خدا را",
            english: "My heart slips away — O wise ones, for God’s sake.",
            culturalNote: "Hafez speaks of losing certainty as the start of insight.",
            reflection: "Even unsteadiness can be a beginning."
        )

    ]
}

