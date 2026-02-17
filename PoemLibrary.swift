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
            culturalNote: "Written in the Golestan (1258) and carved at the entrance of the United Nations. Saadi spent decades in war-torn lands before writing this.",
            reflection: "You are not separate from anyone. When someone else hurts, something in you knows it. Being kind to yourself isn't selfish — it's recognizing that you're woven into the same fabric as everyone around you. Pull one thread and the whole cloth feels it."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            poet: "Hafez",
            persian: "راهی‌ست راه عشق که هیچش کناره نیست",
            english: "The path of love has no edge, no final shore.",
            culturalNote: "In Sufi tradition, the spiritual path has no final stage — arrival would end the longing that keeps the journey alive.",
            reflection: "You're not supposed to finish becoming who you are. There's no final version of you waiting at the end. The searching, the longing, the feeling that there's more — that isn't a problem to solve. It's the whole point. Keep walking. The path is the destination."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            poet: "Khayyam",
            persian: "این قافلهٔ عمر عجب می‌گذرد",
            english: "How strangely this caravan of life passes by.",
            culturalNote: "Khayyam was a mathematician who calculated the solar year with extraordinary precision — then turned that same clear mind toward the brevity of life.",
            reflection: "The caravan doesn't wait. It was moving before you noticed and it'll keep going after you stop watching. But right now, in this breath, you noticed. That moment of awareness — that's not nothing. That might be everything. Don't waste it wishing the caravan would slow down."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            poet: "Rumi",
            persian: "دیروز من هوشیار بودم، امروز دیوانه‌ام",
            english: "Yesterday I was clever, today I am mad.",
            culturalNote: "After meeting the dervish Shams, Rumi abandoned his reputation as a scholar — and never stopped calling it the best thing that happened to him.",
            reflection: "Sometimes the most important changes don't look like progress. They look like everything falling apart. The life you carefully built might need to crack open so something truer can grow through it. What feels like losing your mind might actually be finding your heart."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            poet: "Hafez",
            persian: "دل می‌رود ز دستم، صاحبدلان خدا را",
            english: "My heart slips away — O wise ones, for God's sake.",
            culturalNote: "Opens the most famous ghazal in Persian. 'Del' (heart) means where your deepest knowing lives, not just your feelings.",
            reflection: "There are moments when something inside you starts pulling in a direction your mind hasn't caught up with. You can fight it, argue with it, build a case for staying put. But the heart already knows. Sometimes the bravest thing is to stop resisting and let it lead you where the mind is too afraid to go."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            poet: "Hafez",
            persian: "گر چه بهشت وصل تو بی‌شک خوش است",
            english: "Though paradise with you is surely sweet.",
            culturalNote: "With Hafez, 'paradise' is both the garden promised after death and the miracle of sitting next to someone you love. He meant both.",
            reflection: "What you're looking for might already be sitting across from you. The paradise you imagine somewhere in the future — it might be this room, this person, this ordinary afternoon. The search for something extraordinary can make you blind to what's already here, already sweet, already enough."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            poet: "Khayyam",
            persian: "هر کس که در این بزم جهان آمد و رفت",
            english: "Everyone who came to this feast of the world and left.",
            culturalNote: "A 'bazm' in Persian culture is a gathering you enjoy completely, knowing it will end. Khayyam saw the whole world as one.",
            reflection: "You're a guest at this feast. You didn't set the table and you won't be here to clear it. But while you're here — eat slowly, taste everything, look at the faces around you. The beauty of a gathering isn't that it lasts forever. It's that for a little while, you got to be here at all."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            poet: "Rumi",
            persian: "عاشقی آموز و از هر دو جهان آزاد شو",
            english: "Learn to love and be free from both worlds.",
            culturalNote: "The 'two worlds' are this life and the next. Most traditions want you to choose. Rumi says love makes the question irrelevant.",
            reflection: "Freedom isn't about escaping anything. It's about loving so completely that the walls stop mattering. Not this world or the next, not success or failure, not holding on or letting go — just love, burning through every boundary you ever drew. That's what it means to be free from both worlds."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            poet: "Saadi",
            persian: "خوشا آن روز که پرواز کنیم",
            english: "How beautiful the day when we take flight.",
            culturalNote: "From the Bustan — Saadi's gift to Shiraz after thirty years of traveling through Baghdad, Damascus, and North Africa.",
            reflection: "You don't always need to leave to take flight. Sometimes coming back is the real journey. Sometimes the thing you've been searching for across the world is the place you started from, seen with new eyes. The flight isn't always outward. Sometimes it's the moment you finally let yourself land."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            poet: "Ferdowsi",
            persian: "توانا بود هر که دانا بود\nز دانش دل پیر برنا بود",
            english: "Mighty is the one who is wise —\nknowledge makes an old heart young again.",
            culturalNote: "One of the most quoted lines in Persian. Ferdowsi spent thirty years writing the Shahnameh to preserve the language when Arabic was replacing it.",
            reflection: "What you know can never be taken from you. Empires fall, money disappears, beauty fades — but what you've learned, what you truly understand, stays. It keeps your heart young when everything else ages. That's the only kind of power worth building: the kind that no one can take away."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            poet: "Ferdowsi",
            persian: "چو ایران نباشد تن من مباد\nبدین بوم و بر زنده یک تن مباد",
            english: "If Iran shall not be, let my body not be —\nlet no one remain alive in this land and soil.",
            culturalNote: "Spoken by the hero Rostam in the Shahnameh. Ferdowsi's patriotism was about a civilization and a language, not borders or kings.",
            reflection: "Loving where you come from isn't about looking backward. It's about making sure something beautiful survives. Every culture, every language, every tradition is a way of seeing the world that no other can replace. When one disappears, we all lose a piece of what it means to be human. Protect what matters."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            poet: "Ferdowsi",
            persian: "میازار موری که دانه‌کش است\nکه جان دارد و جان شیرین خوش است",
            english: "Do not hurt an ant that carries its grain —\nit too has a life, and life is sweet.",
            culturalNote: "In the middle of an epic full of wars and kings, Ferdowsi pauses to say: don't step on an ant. The Shahnameh's moral heart is gentleness.",
            reflection: "Strength isn't measured by what you can destroy. It's measured by what you choose to protect. The smallest creature carrying its grain across the ground is doing exactly what you're doing — trying to live, trying to make it through. Recognizing that, even in the middle of your own battles, is what makes you truly strong."
        )

    ]
}
