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
            poet: "Saadi",
            persian: "بنی آدم اعضای یکدیگرند",
            english: "Human beings are members of a whole.",
            culturalNote: "From the Golestan (1258), now carved at the United Nations entrance.",
            reflection: "You are not separate from anyone. Pull one thread and the whole cloth feels it."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            poet: "Hafez",
            persian: "راهی‌ست راه عشق که هیچش کناره نیست",
            english: "The path of love has no edge, no final shore.",
            culturalNote: "In Sufi tradition, arrival would end the longing that keeps the journey alive.",
            reflection: "There's no final version of you. The searching, the longing — that isn't a problem to solve. It's the whole point."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            poet: "Khayyam",
            persian: "این قافلهٔ عمر عجب می‌گذرد",
            english: "How strangely this caravan of life passes by.",
            culturalNote: "Khayyam calculated the solar year with extraordinary precision — then turned that clear mind toward life's brevity.",
            reflection: "The caravan doesn't wait. But right now, in this breath, you noticed. That moment of awareness might be everything."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            poet: "Rumi",
            persian: "دیروز من هوشیار بودم، امروز دیوانه‌ام",
            english: "Yesterday I was clever, today I am mad.",
            culturalNote: "After meeting the dervish Shams, Rumi abandoned his scholarly reputation and called it the best thing that ever happened.",
            reflection: "Sometimes the most important changes look like everything falling apart. What feels like losing your mind might be finding your heart."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            poet: "Hafez",
            persian: "دل می‌رود ز دستم، صاحبدلان خدا را",
            english: "My heart slips away — O wise ones, for God's sake.",
            culturalNote: "Opens the most famous ghazal in Persian. 'Del' means your deepest knowing, not just feelings.",
            reflection: "The heart pulls in directions the mind hasn't caught up with. Sometimes the bravest thing is to stop resisting and follow."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            poet: "Hafez",
            persian: "گر چه بهشت وصل تو بی‌شک خوش است",
            english: "Though paradise with you is surely sweet.",
            culturalNote: "For Hafez, 'paradise' is both the garden after death and sitting next to someone you love.",
            reflection: "What you're looking for might already be sitting across from you. Don't let the search for something extraordinary blind you to what's already here."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            poet: "Khayyam",
            persian: "هر کس که در این بزم جهان آمد و رفت",
            english: "Everyone who came to this feast of the world and left.",
            culturalNote: "A 'bazm' is a gathering you enjoy completely, knowing it will end. Khayyam saw the world as one.",
            reflection: "You're a guest at this feast. The beauty isn't that it lasts forever — it's that you got to be here at all."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            poet: "Rumi",
            persian: "عاشقی آموز و از هر دو جهان آزاد شو",
            english: "Learn to love and be free from both worlds.",
            culturalNote: "The 'two worlds' are this life and the next. Rumi says love makes the question irrelevant.",
            reflection: "Freedom isn't escaping anything. It's loving so completely that the walls stop mattering — burning through every boundary you ever drew."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            poet: "Saadi",
            persian: "خوشا آن روز که پرواز کنیم",
            english: "How beautiful the day when we take flight.",
            culturalNote: "From the Bustan — Saadi's gift to Shiraz after thirty years of wandering.",
            reflection: "You don't always need to leave to take flight. Sometimes the real journey is coming back and seeing where you started with new eyes."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            poet: "Ferdowsi",
            persian: "توانا بود هر که دانا بود\nز دانش دل پیر برنا بود",
            english: "Mighty is the one who is wise —\nknowledge makes an old heart young again.",
            culturalNote: "Ferdowsi spent thirty years writing the Shahnameh to preserve Persian when Arabic was replacing it.",
            reflection: "What you know can never be taken from you. Empires fall, beauty fades — but what you truly understand keeps your heart young."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            poet: "Ferdowsi",
            persian: "چو ایران نباشد تن من مباد\nبدین بوم و بر زنده یک تن مباد",
            english: "If Iran shall not be, let my body not be —\nlet no one remain alive in this land and soil.",
            culturalNote: "Spoken by Rostam in the Shahnameh. Ferdowsi's patriotism was about a civilization, not borders.",
            reflection: "Loving where you come from isn't looking backward. It's making sure something beautiful survives. When a culture disappears, we all lose."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            poet: "Ferdowsi",
            persian: "میازار موری که دانه‌کش است\nکه جان دارد و جان شیرین خوش است",
            english: "Do not hurt an ant that carries its grain —\nit too has a life, and life is sweet.",
            culturalNote: "In an epic of wars and kings, Ferdowsi pauses to say: don't step on an ant.",
            reflection: "Strength isn't measured by what you can destroy — it's measured by what you choose to protect."
        )

    ]
}
