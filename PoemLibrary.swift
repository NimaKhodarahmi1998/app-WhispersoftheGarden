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
            culturalNote: "You'll find this verse carved into the entrance of the United Nations in New York. Saadi wrote it in the Golestan around 1258, after spending decades traveling through lands torn apart by war. He came back convinced that caring for each other isn't just a nice idea. It's how we're built.",
            reflection: "Being kind to yourself isn't selfish. You're part of everyone else."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            poet: "Hafez",
            persian: "راهی‌ست راه عشق که هیچش کناره نیست",
            english: "The path of love has no edge, no final shore.",
            culturalNote: "Sufis talk about stages on the spiritual path, but here's the thing: there's no final stage. If you arrived, you'd stop longing, and longing is what keeps the whole thing alive. Hafez loved that paradox. He kept circling back to it, turning it into some of the most beautiful lines in the Persian language.",
            reflection: "You're not supposed to finish becoming who you are. That's the whole point."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            poet: "Khayyam",
            persian: "این قافلهٔ عمر عجب می‌گذرد",
            english: "How strangely this caravan of life passes by.",
            culturalNote: "Before he ever wrote poetry, Khayyam was a mathematician who calculated the length of a solar year with startling accuracy. That same precise mind looked at how quickly a life goes by and just marveled at it. His Rubaiyat isn't sad about impermanence. It's honestly kind of amazed.",
            reflection: "The caravan doesn't wait. But noticing it pass is already something."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            poet: "Rumi",
            persian: "دیروز من هوشیار بودم، امروز دیوانه‌ام",
            english: "Yesterday I was clever, today I am mad.",
            culturalNote: "Rumi was a respected scholar in 13th-century Konya until he met Shams, a wandering dervish who turned his ordered life inside out. He lost his reputation, his composure, most of what he thought he knew. He never stopped calling it the best thing that happened to him.",
            reflection: "Sometimes the most important changes don't look like progress. They look like everything falling apart."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            poet: "Hafez",
            persian: "دل می‌رود ز دستم، صاحبدلان خدا را",
            english: "My heart slips away — O wise ones, for God's sake.",
            culturalNote: "This opens what's probably the most famous ghazal in the Persian language. In Persian poetry, 'del' (heart) isn't just about feelings. It's where you do your deepest knowing. So when Hafez says his heart is slipping away, he means something inside him is pulling toward a direction his mind hasn't caught up with yet.",
            reflection: "Sometimes you just have to let the heart go where the mind is scared to follow."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            poet: "Hafez",
            persian: "گر چه بهشت وصل تو بی‌شک خوش است",
            english: "Though paradise with you is surely sweet.",
            culturalNote: "With Hafez, a love poem is always also a prayer, and a drinking song is always also philosophy. 'Paradise' here is both the garden you're promised after death and the plain miracle of sitting next to someone you love. People have argued for seven hundred years about which one he meant. He meant both.",
            reflection: "What you're looking for might already be sitting across from you."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            poet: "Khayyam",
            persian: "هر کس که در این بزم جهان آمد و رفت",
            english: "Everyone who came to this feast of the world and left.",
            culturalNote: "Khayyam calls the world a 'bazm,' a gathering with wine and music and friends. In Persian culture, a bazm is something you enjoy completely, knowing it will end. People arrive, they eat, they laugh, they go home. He made that feel not sad but perfectly natural. Like standing up from a good meal.",
            reflection: "You're a guest at this feast. Eat slowly. Notice the taste."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            poet: "Rumi",
            persian: "عاشقی آموز و از هر دو جهان آزاد شو",
            english: "Learn to love and be free from both worlds.",
            culturalNote: "The 'two worlds' here are this life and whatever comes next. Most traditions want you to pick one or the other. Rumi says love makes the whole question irrelevant. This line comes from the Masnavi, a poem so long (25,000 couplets) that he dictated it over years while pacing around the room, sometimes crying, sometimes dancing.",
            reflection: "Freedom isn't about escaping anything. It's about loving so completely that the walls stop mattering."
        ),

        Poem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            poet: "Saadi",
            persian: "خوشا آن روز که پرواز کنیم",
            english: "How beautiful the day when we take flight.",
            culturalNote: "Saadi traveled for thirty years across Baghdad, Damascus, North Africa, before finally coming back to Shiraz. When he talks about flight, it's not abstract. He actually did it. The Bustan, where this line appears, was basically a gift to his hometown: everything he'd learned, written down for the people he'd left behind.",
            reflection: "You don't always need to leave to take flight. Sometimes coming back is the real journey."
        )

    ]
}
