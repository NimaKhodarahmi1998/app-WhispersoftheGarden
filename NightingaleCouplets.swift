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
            culturalNote: "The 'stations of the spirit' are Sufi stages of awakening — Hafez puts the whole curriculum in a bird's song.",
            reflection: "The teacher you need might not look like a teacher. Wisdom sometimes comes from a bird on a branch. Stay open."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000002")!,
            poet: "Hafez",
            persian: "گل در بر و می در کف و معشوق به کام است\nسلطان جهانم به چنین روز غلام است",
            english: "Rose in hand, wine in cup, the beloved willing —\nthe sultan of the world would envy such a day.",
            culturalNote: "Under Shiraz's tyrants, saying an ordinary afternoon outranks a sultan was quietly dangerous.",
            reflection: "Power always envies presence. You already have what kings are trying to buy. Don't let anyone convince you otherwise."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000003")!,
            poet: "Hafez",
            persian: "بلبلی خون‌دلی خورد و گلی حاصل کرد\nباد غیرت به صدش خار پریشان می‌کرد",
            english: "The nightingale drank heart's blood and earned a rose,\nwhile jealous winds scattered a hundred thorns.",
            culturalNote: "The nightingale-and-rose is Persian poetry's oldest love story — the bird sings until it bleeds.",
            reflection: "The thorns don't mean you chose wrong — they mean you chose something real. The rose earned through heart's blood is truly yours."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000004")!,
            poet: "Hafez",
            persian: "دلم جز مهر مه‌رویان طریقی بر نمی‌گیرد\nز هر در می‌دهم پندش ولیکن در نمی‌گیرد",
            english: "My heart takes no path but love of the moon-faced;\nI counsel it from every door, yet it will not listen.",
            culturalNote: "A double wordplay: 'dar' means both 'door' and 'to accept.' The mind watches helplessly as the heart decides.",
            reflection: "The heart already knows where it's going. All your careful reasons for staying safe — it hears them, nods, and walks right past."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000005")!,
            poet: "Hafez",
            persian: "مرا تا عشق تعلیم سخن کرد\nحدیثم نکته‌ی هر انجمن کرد",
            english: "Since love taught me to speak,\nmy words became the talk of every gathering.",
            culturalNote: "In Persian tradition, the poet doesn't choose poetry — poetry chooses the poet through love.",
            reflection: "Before love, you had words. After love, you had something to say. That's the difference between speaking and being heard."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000006")!,
            poet: "Hafez",
            persian: "شب تاریک و بیم موج و گردابی چنین هائل\nکجا دانند حال ما سبکباران ساحل‌ها",
            english: "Dark night, the dread of waves, a whirlpool so terrible —\nhow could those light-footed ones on shore know our state?",
            culturalNote: "Hafez's most quoted couplet. The 'dark night' is a storm, a dark night of the soul, and political danger — all at once.",
            reflection: "Those on the shore can't understand. You're on the water because something in you knew safety wasn't where you belonged."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000007")!,
            poet: "Hafez",
            persian: "رسید مژده که ایام غم نخواهد ماند\nچنان نماند و چنین نیز هم نخواهد ماند",
            english: "Glad tidings — the days of sorrow shall not last.\nAs it did not remain so, neither shall this.",
            culturalNote: "The second line is the key: neither sorrow nor joy lasts. For Hafez, that's liberation.",
            reflection: "This too shall pass — the grief, the joy, all of it. Let that free you instead of frightening you."
        )
    ]
}
