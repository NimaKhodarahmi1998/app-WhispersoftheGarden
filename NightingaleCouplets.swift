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
            culturalNote: "The 'stations of the spirit' are Sufi stages of inner awakening. Hafez puts the whole curriculum in the mouth of a bird on a branch.",
            reflection: "The teacher you're looking for might not look anything like a teacher. Wisdom doesn't always come from books or lectures. Sometimes it comes from a bird singing on a branch, a stranger's passing remark, a moment of silence that says more than any sermon. Stay open. The lesson is everywhere."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000002")!,
            poet: "Hafez",
            persian: "گل در بر و می در کف و معشوق به کام است\nسلطان جهانم به چنین روز غلام است",
            english: "Rose in hand, wine in cup, the beloved willing —\nthe sultan of the world would envy such a day.",
            culturalNote: "Under the tyrants of 14th-century Shiraz, saying an ordinary afternoon outranks a sultan was quietly dangerous.",
            reflection: "Power always envies presence. The king on his throne would trade it all for one real afternoon of being fully alive, fully here, fully with someone he loves. You already have what power is trying to buy. Don't let anyone convince you otherwise."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000003")!,
            poet: "Hafez",
            persian: "بلبلی خون‌دلی خورد و گلی حاصل کرد\nباد غیرت به صدش خار پریشان می‌کرد",
            english: "The nightingale drank heart's blood and earned a rose,\nwhile jealous winds scattered a hundred thorns.",
            culturalNote: "The nightingale-and-rose is Persian poetry's oldest love story — the bird sings until it bleeds against the thorns.",
            reflection: "Devotion always meets resistance. The thorns don't mean you chose wrong. They mean you chose something real. Anything worth loving will cost you something. The jealous winds will blow, the obstacles will come — but the rose you earned through your own heart's blood is yours in a way that nothing easy could ever be."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000004")!,
            poet: "Hafez",
            persian: "دلم جز مهر مه‌رویان طریقی بر نمی‌گیرد\nز هر در می‌دهم پندش ولیکن در نمی‌گیرد",
            english: "My heart takes no path but love of the moon-faced;\nI counsel it from every door, yet it will not listen.",
            culturalNote: "A double wordplay: 'dar' means both 'door' and 'to accept.' Hafez plays the helpless rational mind watching his heart do as it pleases.",
            reflection: "You can argue with yourself forever. The heart already knows where it's going. All those careful reasons you build for staying safe — the heart hears them, nods politely, and walks right past. Maybe that's not a flaw. Maybe the heart sees something the mind is too cautious to admit."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000005")!,
            poet: "Hafez",
            persian: "مرا تا عشق تعلیم سخن کرد\nحدیثم نکته‌ی هر انجمن کرد",
            english: "Since love taught me to speak,\nmy words became the talk of every gathering.",
            culturalNote: "In Persian tradition, the poet doesn't choose poetry — poetry chooses the poet through an experience of overwhelming love.",
            reflection: "The most honest things you'll ever say come from what you didn't plan to feel. Before love, you had words. After love, you had something to say. That's the difference between speaking and truly being heard — not eloquence, not cleverness, but the raw truth of something that moved through you and demanded to be spoken."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000006")!,
            poet: "Hafez",
            persian: "شب تاریک و بیم موج و گردابی چنین هائل\nکجا دانند حال ما سبکباران ساحل‌ها",
            english: "Dark night, the dread of waves, a whirlpool so terrible —\nhow could those light-footed ones on shore know our state?",
            culturalNote: "Perhaps Hafez's most quoted couplet. The 'dark night' is a real storm, a dark night of the soul, and the political danger of 14th-century Shiraz — all at once.",
            reflection: "The people who haven't been through it can't understand it. That's okay. You're not doing it for them. You're out on the water because something in you knew that the shore, for all its safety, wasn't where you belonged. The darkness and the waves are the price of the journey. And the journey is yours."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000007")!,
            poet: "Hafez",
            persian: "رسید مژده که ایام غم نخواهد ماند\nچنان نماند و چنین نیز هم نخواهد ماند",
            english: "Glad tidings — the days of sorrow shall not last.\nAs it did not remain so, neither shall this.",
            culturalNote: "The full couplet of the landing page verse. The second line is the key: neither sorrow nor joy lasts. For Hafez, that's not grim — it's liberation.",
            reflection: "This too shall pass. All of it — the grief, the joy, the confusion, the clarity. Nothing you're feeling right now is permanent. Let that free you instead of frightening you. You don't need to cling to the good moments or drown in the hard ones. They're all passing through. And so are you, beautifully."
        )
    ]
}
