//
//  CommonPhrases.swift
//  SharedKit
//
//  Everyday Bangla words and phrases the keyboard offers on its own: in the
//  idle suggestion bar after the user's favourites, and as completions of the
//  word being typed after the engine's own candidates.
//
//  Kept apart from `PinnedKeywordsStore` on purpose. Favourites are the user's
//  list to curate; these are built in, so they never clutter it and every
//  user gets them, including anyone who has already edited their favourites.
//

import Foundation

public enum CommonPhrases {

    /// Most completions offered for one word, so a short prefix like আ doesn't
    /// bury the engine's candidates under a long tail.
    public static let maxCompletions = 6

    /// Ordered roughly by how often they're typed — the first few are what
    /// shows in the idle bar without scrolling.
    public static let bangla: [String] = [
        // Greetings and courtesy
        "আসসালামু আলাইকুম",
        "ওয়ালাইকুম আসসালাম",
        "ধন্যবাদ",
        "অনেক ধন্যবাদ",
        "দুঃখিত",
        "মাফ করবেন",
        "স্বাগতম",
        "অভিনন্দন",

        // Religious expressions in everyday use
        "আলহামদুলিল্লাহ",
        "ইনশাআল্লাহ",
        "মাশাআল্লাহ",
        "সুবহানাল্লাহ",
        "আমিন",

        // Conversation
        "কেমন আছেন?",
        "কেমন আছো?",
        "ভালো আছি",
        "আমি ভালো আছি",
        "কী করছো?",
        "কোথায় আছো?",
        "কখন আসবে?",
        "খেয়েছো?",
        "ঠিক আছে",
        "আচ্ছা",
        "হ্যাঁ",
        "না",
        "জি",
        "এখনই আসছি",
        "একটু পরে",
        "একটু অপেক্ষা করুন",
        "পরে কথা হবে",
        "আবার দেখা হবে",
        "ভালো থাকবেন",
        "ভালো থেকো",
        "ফোন দিও",
        "মিস করছি",
        "ভালোবাসি",
        "আমি তোমাকে ভালোবাসি",

        // Occasions
        "শুভ সকাল",
        "শুভ রাত্রি",
        "শুভ জন্মদিন",
        "ঈদ মোবারক",
        "শুভ নববর্ষ",

        // Everyday words
        "আমি",
        "তুমি",
        "আপনি",
        "আমরা",
        "সবাই",
        "কেন",
        "কখন",
        "কোথায়",
        "কীভাবে",
        "কত",
        "এখন",
        "আজ",
        "কাল",
        "অনেক",
        "খুব",
        "সত্যি",
        "অবশ্যই",
        "দারুণ",
        "চমৎকার",
        "সুন্দর",
        "বাংলাদেশ",
        "বাংলা",
        "ঢাকা"
    ]
}
