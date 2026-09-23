//
//  CheatSheetView.swift
//  Lekhi
//
//  Interactive & searchable Avro Phonetic Bangla typing reference guide.
//

import SwiftUI

struct CheatEntry: Identifiable {
    let id = UUID()
    let latin: String
    let bangla: String
    let category: String
    let tip: String?
}

struct CheatSheetView: View {

    @State private var searchText = ""
    @State private var selectedCategory: String = "All"

    static let categories = ["All", "Vowels (স্বরবর্ণ)", "Consonants (ব্যঞ্জনবর্ণ)", "Vowel Signs (কার)", "Folas & Signs (ফলা ও চিহ্ন)", "Conjuncts (যুক্তবর্ণ)", "Numbers (সংখ্যা)"]

    static let entries: [CheatEntry] = [
        // Vowels
        CheatEntry(latin: "o", bangla: "অ", category: "Vowels (স্বরবর্ণ)", tip: "Default vowel sound"),
        CheatEntry(latin: "a / A", bangla: "আ", category: "Vowels (স্বরবর্ণ)", tip: "A"),
        CheatEntry(latin: "i", bangla: "ই", category: "Vowels (স্বরবর্ণ)", tip: "Hroshwo I"),
        CheatEntry(latin: "I / ee", bangla: "ঈ", category: "Vowels (স্বরবর্ণ)", tip: "Dirgho I"),
        CheatEntry(latin: "u", bangla: "উ", category: "Vowels (স্বরবর্ণ)", tip: "Hroshwo U"),
        CheatEntry(latin: "U", bangla: "ঊ", category: "Vowels (স্বরবর্ণ)", tip: "Dirgho U"),
        CheatEntry(latin: "rri", bangla: "ঋ", category: "Vowels (স্বরবর্ণ)", tip: "Ri"),
        CheatEntry(latin: "e", bangla: "এ", category: "Vowels (স্বরবর্ণ)", tip: "E"),
        CheatEntry(latin: "OI", bangla: "ঐ", category: "Vowels (স্বরবর্ণ)", tip: "Oi"),
        CheatEntry(latin: "O", bangla: "ও", category: "Vowels (স্বরবর্ণ)", tip: "O"),
        CheatEntry(latin: "OU", bangla: "ঔ", category: "Vowels (স্বরবর্ণ)", tip: "Ou"),

        // Consonants
        CheatEntry(latin: "k", bangla: "ক", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "kh", bangla: "খ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "g", bangla: "গ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "gh", bangla: "ঘ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "Ng", bangla: "ঙ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Capital N"),
        CheatEntry(latin: "c", bangla: "চ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "ch", bangla: "ছ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "j", bangla: "জ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "jh", bangla: "ঝ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "NG", bangla: "ঞ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "T", bangla: "ট", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Capital T"),
        CheatEntry(latin: "Th", bangla: "ঠ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Capital T + h"),
        CheatEntry(latin: "D", bangla: "ড", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Capital D"),
        CheatEntry(latin: "Dh", bangla: "ঢ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Capital D + h"),
        CheatEntry(latin: "N", bangla: "ণ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Murdhonno N"),
        CheatEntry(latin: "t", bangla: "ত", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Soft dental t"),
        CheatEntry(latin: "th", bangla: "থ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "d", bangla: "দ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "dh", bangla: "ধ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "n", bangla: "ন", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Donto n"),
        CheatEntry(latin: "p", bangla: "প", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "ph / f", bangla: "ফ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "b", bangla: "ব", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "bh / v", bangla: "ভ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "m", bangla: "ম", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "z", bangla: "য", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Ontostho j"),
        CheatEntry(latin: "r", bangla: "র", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "l", bangla: "ল", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "sh / S", bangla: "শ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Talobyo sh"),
        CheatEntry(latin: "Sh", bangla: "ষ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Murdhonno sh"),
        CheatEntry(latin: "s", bangla: "স", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Donto s"),
        CheatEntry(latin: "h", bangla: "হ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "R", bangla: "ড়", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Dae bindu ro"),
        CheatEntry(latin: "Rh", bangla: "ঢ়", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Dhae bindu ro"),
        CheatEntry(latin: "Y", bangla: "য়", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Ontostho ya — or y after a vowel (bhoy → ভয়)"),
        CheatEntry(latin: "TH / t``", bangla: "ৎ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Khanda ta — hoTaTH → হটাৎ"),
        CheatEntry(latin: "ng", bangla: "ং", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Anusvara"),
        CheatEntry(latin: ":", bangla: "ঃ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Bisarga — the ঃ key on the 123 page, where the colon sits. The word keeps going through it: du + ঃ + kho → দুঃখ"),
        CheatEntry(latin: "qq / ^", bangla: "ঁ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Chandrabindu — caqqd → চাঁদ"),

        // Vowel Signs
        CheatEntry(latin: "ka", bangla: "কা", category: "Vowel Signs (কার)", tip: "A-kar (া)"),
        CheatEntry(latin: "ki", bangla: "কি", category: "Vowel Signs (কার)", tip: "I-kar (ি)"),
        CheatEntry(latin: "kI / kee", bangla: "কী", category: "Vowel Signs (কার)", tip: "EE-kar (ী)"),
        CheatEntry(latin: "ku", bangla: "কু", category: "Vowel Signs (কার)", tip: "U-kar (ু)"),
        CheatEntry(latin: "kU", bangla: "কূ", category: "Vowel Signs (কার)", tip: "OO-kar (ূ)"),
        CheatEntry(latin: "krri", bangla: "কৃ", category: "Vowel Signs (কার)", tip: "Rri-kar (ৃ)"),
        CheatEntry(latin: "ke", bangla: "কে", category: "Vowel Signs (কার)", tip: "E-kar (ে)"),
        CheatEntry(latin: "kOI", bangla: "কৈ", category: "Vowel Signs (কার)", tip: "OI-kar (ৈ)"),
        CheatEntry(latin: "kO", bangla: "কো", category: "Vowel Signs (কার)", tip: "O-kar (ো)"),
        CheatEntry(latin: "kOU", bangla: "কৌ", category: "Vowel Signs (কার)", tip: "OU-kar (ৌ)"),

        // Conjuncts
        CheatEntry(latin: "kkh / kSh", bangla: "ক্ষ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক + ষ"),
        CheatEntry(latin: "gg / jNG", bangla: "জ্ঞ", category: "Conjuncts (যুক্তবর্ণ)", tip: "জ + ঞ"),
        CheatEntry(latin: "kk", bangla: "ক্ক", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক + ক"),
        CheatEntry(latin: "kt", bangla: "ক্ত", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক + ত"),
        CheatEntry(latin: "cch", bangla: "চ্ছ", category: "Conjuncts (যুক্তবর্ণ)", tip: "চ + ছ"),
        CheatEntry(latin: "jj", bangla: "জ্জ", category: "Conjuncts (যুক্তবর্ণ)", tip: "জ + জ"),
        CheatEntry(latin: "TT", bangla: "ট্ট", category: "Conjuncts (যুক্তবর্ণ)", tip: "ট + ট"),
        CheatEntry(latin: "DD", bangla: "ড্ড", category: "Conjuncts (যুক্তবর্ণ)", tip: "ড + ড"),
        CheatEntry(latin: "nt", bangla: "ন্ত", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + ত"),
        CheatEntry(latin: "nd", bangla: "ন্দ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + দ"),
        CheatEntry(latin: "bd", bangla: "ব্দ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ব + দ"),
        CheatEntry(latin: "bb", bangla: "ব্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "ব + ব"),
        CheatEntry(latin: "mm", bangla: "ম্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "ম + ম"),
        CheatEntry(latin: "st", bangla: "স্ত", category: "Conjuncts (যুক্তবর্ণ)", tip: "স + ত"),
        CheatEntry(latin: "str", bangla: "স্ত্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "স + ত + র-ফলা"),
        CheatEntry(latin: "shc / Sc", bangla: "শ্চ", category: "Conjuncts (যুক্তবর্ণ)", tip: "শ + চ"),
        CheatEntry(latin: "ShTh", bangla: "ষ্ঠ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + ঠ"),
        CheatEntry(latin: "hn", bangla: "হ্ন", category: "Conjuncts (যুক্তবর্ণ)", tip: "হ + ন"),
        CheatEntry(latin: "hm", bangla: "হ্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "হ + ম"),
        CheatEntry(latin: "kkhN", bangla: "ক্ষ্ণ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক্ষ + ণ — lokkhNOU → লক্ষ্ণৌ"),
        CheatEntry(latin: "NGc / nc", bangla: "ঞ্চ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ঞ + চ"),
        CheatEntry(latin: "nj / NGj", bangla: "ঞ্জ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ঞ + জ"),
        CheatEntry(latin: "ShN", bangla: "ষ্ণ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + ণ — bOIShNb → বৈষ্ণব"),
        CheatEntry(latin: "Ngg", bangla: "ঙ্গ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ঙ + গ — oNggo → অঙ্গ"),
        CheatEntry(latin: "rri", bangla: "ঋ / ৃ", category: "Conjuncts (যুক্তবর্ণ)", tip: "rriN → ঋণ, brritto → বৃত্ত"),

        // Numbers
        // Folas & signs — grouped the way Ridmik teaches them.
        CheatEntry(latin: "rr", bangla: "র্", category: "Folas & Signs (ফলা ও চিহ্ন)", tip: "Reph — korrmo → কর্ম"),
        CheatEntry(latin: "r", bangla: "্র", category: "Folas & Signs (ফলা ও চিহ্ন)", tip: "Ro-fola after a consonant — promaN → প্রমাণ"),
        CheatEntry(latin: "w", bangla: "্ব", category: "Folas & Signs (ফলা ও চিহ্ন)", tip: "Bo-fola after a consonant — swamI → স্বামী, shwashwoto → শ্বাশ্বত"),
        CheatEntry(latin: "y / z / Z", bangla: "্য", category: "Folas & Signs (ফলা ও চিহ্ন)", tip: "Jo-fola after a consonant — bybohar → ব্যবহার. Use Z after a vowel: oZanimeshon → অ্যানিমেশন"),
        CheatEntry(latin: "hs", bangla: "্\u{200C}", category: "Folas & Signs (ফলা ও চিহ্ন)", tip: "Hasanta. Between two consonants it joins them — shsbamI → স্বামী. At the end of a word it shows the sign — allahhs → আল্লাহ্\u{200C}. After a vowel it stays হ + স (ahsan → আহসান)"),
        CheatEntry(latin: "kShm", bangla: "ক্ষ্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক্ষ + ম"),
        CheatEntry(latin: "tt", bangla: "ত্ত", category: "Conjuncts (যুক্তবর্ণ)", tip: "ত + ত"),
        CheatEntry(latin: "ttw", bangla: "ত্ত্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "ত + ত + ব-ফলা"),
        CheatEntry(latin: "tth", bangla: "ত্থ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ত + থ"),
        CheatEntry(latin: "tm", bangla: "ত্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "ত + ম"),
        CheatEntry(latin: "tr", bangla: "ত্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "ত + র-ফলা"),
        CheatEntry(latin: "kr", bangla: "ক্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক + র-ফলা"),
        CheatEntry(latin: "kl", bangla: "ক্ল", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক + ল"),
        CheatEntry(latin: "ks", bangla: "ক্স", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক + স"),
        CheatEntry(latin: "gr", bangla: "গ্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "গ + র-ফলা"),
        CheatEntry(latin: "gl", bangla: "গ্ল", category: "Conjuncts (যুক্তবর্ণ)", tip: "গ + ল"),
        CheatEntry(latin: "gm", bangla: "গ্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "গ + ম"),
        CheatEntry(latin: "gdh", bangla: "গ্ধ", category: "Conjuncts (যুক্তবর্ণ)", tip: "গ + ধ"),
        CheatEntry(latin: "Ngk", bangla: "ঙ্ক", category: "Conjuncts (যুক্তবর্ণ)", tip: "ঙ + ক"),
        CheatEntry(latin: "Ngkh", bangla: "ঙ্খ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ঙ + খ"),
        CheatEntry(latin: "jjw", bangla: "জ্জ্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "জ + জ + ব-ফলা"),
        CheatEntry(latin: "ddh", bangla: "দ্ধ", category: "Conjuncts (যুক্তবর্ণ)", tip: "দ + ধ"),
        CheatEntry(latin: "dv", bangla: "দ্ভ", category: "Conjuncts (যুক্তবর্ণ)", tip: "দ + ভ"),
        CheatEntry(latin: "dm", bangla: "দ্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "দ + ম"),
        CheatEntry(latin: "nTh", bangla: "ন্ঠ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + ঠ"),
        CheatEntry(latin: "nth", bangla: "ন্থ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + থ"),
        CheatEntry(latin: "ndh", bangla: "ন্ধ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + ধ"),
        CheatEntry(latin: "ndr", bangla: "ন্দ্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + দ + র-ফলা"),
        CheatEntry(latin: "ntr", bangla: "ন্ত্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + ত + র-ফলা"),
        CheatEntry(latin: "nm", bangla: "ন্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + ম"),
        CheatEntry(latin: "nw", bangla: "ন্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "ন + ব-ফলা"),
        CheatEntry(latin: "bdh", bangla: "ব্ধ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ব + ধ"),
        CheatEntry(latin: "vr", bangla: "ভ্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "ভ + র-ফলা"),
        CheatEntry(latin: "mn", bangla: "ম্ন", category: "Conjuncts (যুক্তবর্ণ)", tip: "ম + ন"),
        CheatEntry(latin: "shm", bangla: "শ্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "শ + ম"),
        CheatEntry(latin: "shw", bangla: "শ্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "শ + ব-ফলা"),
        CheatEntry(latin: "Shk", bangla: "ষ্ক", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + ক"),
        CheatEntry(latin: "Shp", bangla: "ষ্প", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + প"),
        CheatEntry(latin: "Shf", bangla: "ষ্ফ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + ফ"),
        CheatEntry(latin: "Shm", bangla: "ষ্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + ম"),
        CheatEntry(latin: "ShTr", bangla: "ষ্ট্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + ট + র-ফলা"),
        CheatEntry(latin: "sw", bangla: "স্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "স + ব-ফলা — swamI → স্বামী"),
        CheatEntry(latin: "sth", bangla: "স্থ", category: "Conjuncts (যুক্তবর্ণ)", tip: "স + থ"),
        CheatEntry(latin: "sf", bangla: "স্ফ", category: "Conjuncts (যুক্তবর্ণ)", tip: "স + ফ"),
        CheatEntry(latin: "skr", bangla: "স্ক্র", category: "Conjuncts (যুক্তবর্ণ)", tip: "স + ক + র-ফলা"),
        CheatEntry(latin: "spl", bangla: "স্প্ল", category: "Conjuncts (যুক্তবর্ণ)", tip: "স + প + ল"),
        CheatEntry(latin: "hw", bangla: "হ্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "হ + ব-ফলা"),
        CheatEntry(latin: "hrri", bangla: "হৃ", category: "Conjuncts (যুক্তবর্ণ)", tip: "হ + ঋ-কার"),
        CheatEntry(latin: "cchw", bangla: "চ্ছ্ব", category: "Conjuncts (যুক্তবর্ণ)", tip: "চ + ছ + ব-ফলা"),
        CheatEntry(latin: "0", bangla: "০", category: "Numbers (সংখ্যা)", tip: "Shunyo"),
        CheatEntry(latin: "1", bangla: "১", category: "Numbers (সংখ্যা)", tip: "Ek"),
        CheatEntry(latin: "2", bangla: "২", category: "Numbers (সংখ্যা)", tip: "Dui"),
        CheatEntry(latin: "3", bangla: "৩", category: "Numbers (সংখ্যা)", tip: "Tin"),
        CheatEntry(latin: "4", bangla: "৪", category: "Numbers (সংখ্যা)", tip: "Char"),
        CheatEntry(latin: "5", bangla: "৫", category: "Numbers (সংখ্যা)", tip: "Pach"),
        CheatEntry(latin: "6", bangla: "৬", category: "Numbers (সংখ্যা)", tip: "Chhoy"),
        CheatEntry(latin: "7", bangla: "৭", category: "Numbers (সংখ্যা)", tip: "Shat"),
        CheatEntry(latin: "8", bangla: "৮", category: "Numbers (সংখ্যা)", tip: "Aat"),
        CheatEntry(latin: "9", bangla: "৯", category: "Numbers (সংখ্যা)", tip: "Noy")
    ]

    var filteredEntries: [CheatEntry] {
        Self.entries.filter { entry in
            let matchesCategory = selectedCategory == "All" || entry.category == selectedCategory
            if searchText.isEmpty {
                return matchesCategory
            }
            let query = searchText.lowercased()
            return matchesCategory && (
                entry.latin.lowercased().contains(query) ||
                entry.bangla.contains(query) ||
                (entry.tip?.lowercased().contains(query) ?? false)
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPicker
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))

                List {
                    ForEach(filteredEntries) { entry in
                        HStack(spacing: 16) {
                            // Latin key badge
                            Text(entry.latin)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.tertiarySystemFill))
                                )
                                .frame(minWidth: 80, alignment: .leading)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)

                            // Bangla Letter / Glyph
                            Text(entry.bangla)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.primary)

                            Spacer()

                            if let tip = entry.tip {
                                Text(tip)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $searchText, prompt: "Search shortcuts e.g. 'ami', 'kkh', 'ka'")
            .navigationTitle("Avro Cheat Sheet")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Self.categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                    } label: {
                        Text(cat)
                            .font(.system(size: 13, weight: selectedCategory == cat ? .bold : .medium))
                            .foregroundStyle(selectedCategory == cat ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == cat ? Color(red: 0.08, green: 0.54, blue: 1.0) : Color(.secondarySystemFill))
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
