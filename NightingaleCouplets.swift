//
//  NightingaleCouplets.swift
//  WhispersoftheGardenApp
//
//  Bonus Hafez couplets about the nightingale and rose.
//  Separate from PoemLibrary — does not interfere with
//  the main 12-poem progression. Uses fixed UUIDs for persistence.
//

import Foundation

struct NightingaleCouplets {

    static let couplets: [Poem] = [

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000001")!,
            poet: "Hafez",
            persian: "بلبل ز شاخ سرو به گلبانگ پهلوی\nمی‌خواند دوش درس مقامات معنوی",
            english: "From the cypress bough the nightingale sang\na lesson in the stations of the spirit.",
            culturalNote: "The 'stations of the spirit' are Sufi stages of awakening. Hafez puts the whole curriculum in a bird's song.",
            reflection: "The teacher you need might not look like a teacher. Wisdom sometimes comes from a bird on a branch. Stay open."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000002")!,
            poet: "Hafez",
            persian: "گل در بر و می در کف و معشوق به کام است\nسلطان جهانم به چنین روز غلام است",
            english: "Rose in hand, wine in cup, the beloved willing,\nthe sultan of the world would envy such a day.",
            culturalNote: "Under Shiraz's tyrants, saying an ordinary afternoon outranks a sultan was quietly dangerous.",
            reflection: "Power always envies presence. You already have what kings are trying to buy. Don't let anyone convince you otherwise."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000003")!,
            poet: "Hafez",
            persian: "بلبلی خون‌دلی خورد و گلی حاصل کرد\nباد غیرت به صدش خار پریشان می‌کرد",
            english: "The nightingale drank heart's blood and earned a rose,\nwhile jealous winds scattered a hundred thorns.",
            culturalNote: "The nightingale-and-rose is Persian poetry's oldest love story. The bird sings until it bleeds.",
            reflection: "The thorns don't mean you chose wrong. They mean you chose something real. The rose earned through heart's blood is truly yours."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000004")!,
            poet: "Hafez",
            persian: "دلم جز مهر مه‌رویان طریقی بر نمی‌گیرد\nز هر در می‌دهم پندش ولیکن در نمی‌گیرد",
            english: "My heart takes no path but love of the moon-faced;\nI counsel it from every door, yet it will not listen.",
            culturalNote: "A double wordplay: 'dar' means both 'door' and 'to accept.' The mind watches helplessly as the heart decides.",
            reflection: "The heart already knows where it's going. All your careful reasons for staying safe, it hears them, nods, and walks right past."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000005")!,
            poet: "Hafez",
            persian: "مرا تا عشق تعلیم سخن کرد\nحدیثم نکته‌ی هر انجمن کرد",
            english: "Since love taught me to speak,\nmy words became the talk of every gathering.",
            culturalNote: "In Persian tradition, the poet doesn't choose poetry. Poetry chooses the poet through love.",
            reflection: "Before love, you had words. After love, you had something to say. That's the difference between speaking and being heard."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000006")!,
            poet: "Hafez",
            persian: "شب تاریک و بیم موج و گردابی چنین هائل\nکجا دانند حال ما سبکباران ساحل‌ها",
            english: "Dark night, the dread of waves, a whirlpool so terrible,\nhow could those light-footed ones on shore know our state?",
            culturalNote: "Hafez's most quoted couplet. The 'dark night' is a storm, a dark night of the soul, and political danger, all at once.",
            reflection: "Those on the shore can't understand. You're on the water because something in you knew safety wasn't where you belonged."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000007")!,
            poet: "Hafez",
            persian: "رسید مژده که ایام غم نخواهد ماند\nچنان نماند و چنین نیز هم نخواهد ماند",
            english: "Glad tidings, the days of sorrow shall not last.\nAs it did not remain so, neither shall this.",
            culturalNote: "The second line is the key: neither sorrow nor joy lasts. For Hafez, that's liberation.",
            reflection: "This too shall pass. The grief, the joy, all of it. Let that free you instead of frightening you."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000008")!,
            poet: "Hafez",
            persian: "اگر آن ترک شیرازی به دست آرد دل ما را\nبه خال هندویش بخشم سمرقند و بخارا را",
            english: "If that Shirazi Turk would take my heart in hand,\nfor the dark mole on that cheek I'd give Samarkand and Bukhara.",
            culturalNote: "The most famous opening in Persian poetry. Legend says Tamerlane summoned Hafez and demanded to know how he dared give away the conqueror's greatest cities for a mole. Hafez replied: 'It is through such generosity, Sire, that I have fallen into such poverty.'",
            reflection: "Love makes you reckless with everything the world considers valuable. And that recklessness might be the most honest thing about you."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000009")!,
            poet: "Hafez",
            persian: "بیا که قصر امل سخت سست بنیاد است\nبیار باده که بنیاد عمر بر باد است",
            english: "Come, for the castle of hope stands on weak foundations.\nBring wine, for the foundation of life is wind.",
            culturalNote: "Hafez pairs architectural imagery with impermanence. The 'castle of hope' is every plan you make assuming tomorrow is guaranteed.",
            reflection: "Stop building castles in a future that doesn't exist yet. The wine is here. The friend is here. What are you waiting for?"
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000010")!,
            poet: "Hafez",
            persian: "نیست بر لوح دلم جز الف قامت یار\nچه کنم حرف دگر یاد نداد استادم",
            english: "On the tablet of my heart is nothing but the alif of the beloved's form.\nWhat can I do? My teacher taught me no other letter.",
            culturalNote: "Alif is the first letter of Persian script, a single vertical stroke. Hafez says his entire education reduced to one shape: the beloved standing upright.",
            reflection: "When something truly claims you, it simplifies everything. All the complexity you thought mattered dissolves into one clear note."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000012")!,
            poet: "Hafez",
            persian: "الا یا ایها الساقی ادر کأساً و ناولها\nکه عشق آسان نمود اول ولی افتاد مشکل‌ها",
            english: "O cupbearer, pass the cup and hand it round,\nfor love seemed easy at first, but then the troubles came.",
            culturalNote: "The opening of Hafez's Divan. The shift from Arabic to Persian in mid-couplet mirrors the shift from expectation to reality. Every reader remembers the moment love stopped being simple.",
            reflection: "Everyone signs up for the easy part. The question is whether you stay when the troubles come. And they always come."
        ),

        Poem(
            id: UUID(uuidString: "B0B00000-0000-0000-0000-000000000013")!,
            poet: "Hafez",
            persian: "مزرع سبز فلک دیدم و داس مه نو\nیادم از کشته‌ی خویش آمد و هنگام درو",
            english: "I saw the green fields of the sky and the sickle of the new moon.\nI remembered my own harvest, and the time of reaping.",
            culturalNote: "Hafez turns an agricultural metaphor into an existential one. The new moon is a cosmic sickle, and your life is what's planted in the field.",
            reflection: "Everything you've sown is growing. The harvest is coming whether you're ready or not. What have you been planting?"
        )
    ]
}
