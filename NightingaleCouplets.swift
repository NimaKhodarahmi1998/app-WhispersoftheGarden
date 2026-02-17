//
//  NightingaleCouplets.swift
//  WhispersoftheGardenApp
//
//  Bonus Hafez couplets about the nightingale and rose.
//  Separate from PoemLibrary — does not interfere with
//  the main 9-poem progression. Uses fixed UUIDs for persistence.
//

import Foundation

struct NightingaleCouplets {

    static let couplets: [Poem] = [

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000001")!,
            poet: "Hafez",
            persian: "بلبل ز شاخ سرو به گلبانگ پهلوی\nمی‌خواند دوش درس مقامات معنوی",
            english: "From the cypress bough the nightingale sang\na lesson in the stations of the spirit.",
            culturalNote: "The 'stations of the spirit' he mentions are a Sufi concept: stages a seeker moves through on the inner path, from repentance all the way to the dissolution of the self. But Hafez puts this whole esoteric curriculum in the mouth of a bird singing on a branch. As if the deepest truths aren't locked away somewhere. They're just floating around the garden.",
            reflection: "The teacher you're looking for might not look anything like a teacher."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000002")!,
            poet: "Hafez",
            persian: "گل در بر و می در کف و معشوق به کام است\nسلطان جهانم به چنین روز غلام است",
            english: "Rose in hand, wine in cup, the beloved willing —\nthe sultan of the world would envy such a day.",
            culturalNote: "Hafez lived under several tyrants in 14th-century Shiraz. So when he says a single afternoon with a rose and a cup of wine outranks a sultan, that wasn't just poetry. That was a quietly dangerous thing to say. He even uses the word 'gholam' (slave), making the king a servant to an ordinary moment.",
            reflection: "Power always envies presence. Being fully here, right now, is worth more than any title."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000003")!,
            poet: "Hafez",
            persian: "بلبلی خون‌دلی خورد و گلی حاصل کرد\nباد غیرت به صدش خار پریشان می‌کرد",
            english: "The nightingale drank heart's blood and earned a rose,\nwhile jealous winds scattered a hundred thorns.",
            culturalNote: "The nightingale and the rose might be the oldest love story in Persian poetry. The nightingale loves the rose so much it sings until its chest bleeds against the thorns. But Hafez throws in a third character here: a jealous wind that scatters thorns everywhere. The world trying to get between lover and beloved.",
            reflection: "Devotion always meets resistance. The thorns don't mean you chose wrong."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000004")!,
            poet: "Hafez",
            persian: "دلم جز مهر مه‌رویان طریقی بر نمی‌گیرد\nز هر در می‌دهم پندش ولیکن در نمی‌گیرد",
            english: "My heart takes no path but love of the moon-faced;\nI counsel it from every door, yet it will not listen.",
            culturalNote: "There's a wordplay here that doesn't survive translation: 'dar' means both 'door' and 'to accept.' So the line reads as 'from every door I advise it, but it doesn't take' on two levels at once. Hafez loved playing the helpless rational mind watching his heart do whatever it wanted. His humor about it is what makes it feel real.",
            reflection: "You can argue with yourself forever. The heart already knows where it's going."
        )
    ]
}
