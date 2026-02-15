//
//  PoemLibrary.swift - WITH FIXED UUIDs FOR PERSISTENCE
//  WhispersoftheGardenApp
//
//  CRITICAL: Uses fixed UUID strings so poems are recognized after app restart
//

import Foundation

struct PoemLibrary {

    static let poems: [Poem] = [

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            persian: "بنی آدم اعضای یکدیگرند",
            english: "Human beings are members of a whole.",
            culturalNote: "Saʿdi emphasizes shared humanity as the foundation of ethics.",
            reflection: "Gentleness toward yourself is a form of care for others."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            persian: "راهی‌ست راه عشق که هیچش کناره نیست",
            english: "The path of love has no edge, no final shore.",
            culturalNote: "Persian mysticism often rejects the idea of final arrival.",
            reflection: "You are not meant to finish becoming — only to continue."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            persian: "این قافلهٔ عمر عجب می‌گذرد",
            english: "How strangely this caravan of life passes by.",
            culturalNote: "Khayyam reflects on impermanence and presence.",
            reflection: "Hope lives in attention to this moment."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            persian: "دیروز من هوشیار بودم، امروز دیوانه‌ام",
            english: "Yesterday I was clever, today I am mad.",
            culturalNote: "Rumi embraces transformation through surrender.",
            reflection: "Growth begins when control loosens."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            persian: "دل می‌رود ز دستم، صاحبدلان خدا را",
            english: "My heart slips away — O wise ones, for God's sake.",
            culturalNote: "Hafez speaks of losing certainty as the start of insight.",
            reflection: "Even unsteadiness can be a beginning."
        ),
        
        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            persian: "گر چه بهشت وصل تو بی‌شک خوش است",
            english: "Though paradise with you is surely sweet.",
            culturalNote: "Hafez explores the tension between earthly and divine love.",
            reflection: "The things we seek are already within reach."
        ),
        
        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            persian: "هر کس که در این بزم جهان آمد و رفت",
            english: "Everyone who came to this feast of the world and left.",
            culturalNote: "Khayyam reminds us of life's temporary nature.",
            reflection: "Presence matters more than permanence."
        ),
        
        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            persian: "عاشقی آموز و از هر دو جهان آزاد شو",
            english: "Learn to love and be free from both worlds.",
            culturalNote: "Rumi teaches that love liberates beyond material and spiritual realms.",
            reflection: "Freedom comes from embracing what is."
        ),
        
        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            persian: "خوشا آن روز که پرواز کنیم",
            english: "How beautiful the day when we take flight.",
            culturalNote: "Saʿdi speaks of spiritual ascension and transcendence.",
            reflection: "Every moment holds the possibility of rising."
        )

    ]
}
