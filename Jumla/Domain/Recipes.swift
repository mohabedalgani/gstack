import Foundation

enum ContentCatalog {
    static let recipes: [SentenceRecipe] = [
        SentenceRecipe(
            id: "read_student_book",
            words: ["قَرَأَ", "الطَّالِبُ", "الْكِتَابَ"],
            irab: [
                .init(word: "قَرَأَ", label: "فعل ماضٍ"),
                .init(word: "الطَّالِبُ", label: "فاعل مرفوع"),
                .init(word: "الْكِتَابَ", label: "مفعول به منصوب"),
            ]
        ),
        SentenceRecipe(
            id: "wrote_girl_lesson",
            words: ["كَتَبَتْ", "الْبِنْتُ", "الدَّرْسَ"],
            irab: [
                .init(word: "كَتَبَتْ", label: "فعل ماضٍ"),
                .init(word: "الْبِنْتُ", label: "فاعل مرفوع"),
                .init(word: "الدَّرْسَ", label: "مفعول به منصوب"),
            ]
        ),
        SentenceRecipe(
            id: "opened_teacher_door",
            words: ["فَتَحَ", "الْمُعَلِّمُ", "الْبَابَ"],
            irab: [
                .init(word: "فَتَحَ", label: "فعل ماضٍ"),
                .init(word: "الْمُعَلِّمُ", label: "فاعل مرفوع"),
                .init(word: "الْبَابَ", label: "مفعول به منصوب"),
            ]
        ),
        SentenceRecipe(
            id: "drank_child_milk",
            words: ["شَرِبَ", "الطِّفْلُ", "الْحَلِيبَ"],
            irab: [
                .init(word: "شَرِبَ", label: "فعل ماضٍ"),
                .init(word: "الطِّفْلُ", label: "فاعل مرفوع"),
                .init(word: "الْحَلِيبَ", label: "مفعول به منصوب"),
            ]
        ),
        SentenceRecipe(
            id: "ate_boy_apple",
            words: ["أَكَلَ", "الْوَلَدُ", "التُّفَّاحَةَ"],
            irab: [
                .init(word: "أَكَلَ", label: "فعل ماضٍ"),
                .init(word: "الْوَلَدُ", label: "فاعل مرفوع"),
                .init(word: "التُّفَّاحَةَ", label: "مفعول به منصوب"),
            ]
        ),
        SentenceRecipe(
            id: "drew_artist_picture",
            words: ["رَسَمَ", "الرَّسَّامُ", "الصُّورَةَ"],
            irab: [
                .init(word: "رَسَمَ", label: "فعل ماضٍ"),
                .init(word: "الرَّسَّامُ", label: "فاعل مرفوع"),
                .init(word: "الصُّورَةَ", label: "مفعول به منصوب"),
            ]
        ),
    ]

    static let distractors: [String] = [
        "فِي", "عَلَى", "مِنْ", "إِلَى", "ثُمَّ", "وَ",
        "الْقَلَمَ", "الْمَدْرَسَةَ", "الْحَدِيقَةَ", "الْمَاءَ",
        "سَافَرَ", "لَعِبَ", "جَلَسَ", "نَامَ", "قَالَ",
        "الْأُمُّ", "الْأَبُ", "الصَّدِيقُ", "الْأُسْتَاذُ",
    ]
}
