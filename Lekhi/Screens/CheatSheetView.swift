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

    private let categories = ["All", "Vowels (স্বরবর্ণ)", "Consonants (ব্যঞ্জনবর্ণ)", "Vowel Signs (কার)", "Conjuncts (যুক্তবর্ণ)", "Numbers (সংখ্যা)"]

    private let entries: [CheatEntry] = [
        // Vowels
        CheatEntry(latin: "a", bangla: "অ", category: "Vowels (স্বরবর্ণ)", tip: "Default vowel sound"),
        CheatEntry(latin: "A / aa", bangla: "আ", category: "Vowels (স্বরবর্ণ)", tip: "Short/long a"),
        CheatEntry(latin: "i", bangla: "ই", category: "Vowels (স্বরবর্ণ)", tip: "Hroshwo I"),
        CheatEntry(latin: "I / ee", bangla: "ঈ", category: "Vowels (স্বরবর্ণ)", tip: "Dirgho I"),
        CheatEntry(latin: "u", bangla: "উ", category: "Vowels (স্বরবর্ণ)", tip: "Hroshwo U"),
        CheatEntry(latin: "U / oo", bangla: "ঊ", category: "Vowels (স্বরবর্ণ)", tip: "Dirgho U"),
        CheatEntry(latin: "rri", bangla: "ঋ", category: "Vowels (স্বরবর্ণ)", tip: "Ri"),
        CheatEntry(latin: "e", bangla: "এ", category: "Vowels (স্বরবর্ণ)", tip: "E"),
        CheatEntry(latin: "OI", bangla: "ঐ", category: "Vowels (স্বরবর্ণ)", tip: "Oi"),
        CheatEntry(latin: "O / o", bangla: "ও", category: "Vowels (স্বরবর্ণ)", tip: "O"),
        CheatEntry(latin: "OU", bangla: "ঔ", category: "Vowels (স্বরবর্ণ)", tip: "Ou"),

        // Consonants
        CheatEntry(latin: "k", bangla: "ক", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "kh", bangla: "খ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "g", bangla: "গ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "gh", bangla: "ঘ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "Ng", bangla: "ঙ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Capital N"),
        CheatEntry(latin: "c / ch", bangla: "চ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
        CheatEntry(latin: "Ch / chh", bangla: "ছ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: nil),
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
        CheatEntry(latin: "y / Y", bangla: "য়", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Ontostho ya"),
        CheatEntry(latin: "t`", bangla: "ৎ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Khandata"),
        CheatEntry(latin: "ng", bangla: "ং", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Anusvara"),
        CheatEntry(latin: ":", bangla: "ঃ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Bisarga"),
        CheatEntry(latin: "^", bangla: "ঁ", category: "Consonants (ব্যঞ্জনবর্ণ)", tip: "Chandrabindu"),

        // Vowel Signs
        CheatEntry(latin: "ka", bangla: "কা", category: "Vowel Signs (কার)", tip: "A-kar (া)"),
        CheatEntry(latin: "ki", bangla: "কি", category: "Vowel Signs (কার)", tip: "I-kar (ি)"),
        CheatEntry(latin: "kI / kee", bangla: "কী", category: "Vowel Signs (কার)", tip: "EE-kar (ী)"),
        CheatEntry(latin: "ku", bangla: "কু", category: "Vowel Signs (কার)", tip: "U-kar (ু)"),
        CheatEntry(latin: "kU / koo", bangla: "কূ", category: "Vowel Signs (কার)", tip: "OO-kar (ূ)"),
        CheatEntry(latin: "krri", bangla: "কৃ", category: "Vowel Signs (কার)", tip: "Rri-kar (ৃ)"),
        CheatEntry(latin: "ke", bangla: "কে", category: "Vowel Signs (কার)", tip: "E-kar (ে)"),
        CheatEntry(latin: "kOI", bangla: "কৈ", category: "Vowel Signs (কার)", tip: "OI-kar (ৈ)"),
        CheatEntry(latin: "ko / kO", bangla: "কো", category: "Vowel Signs (কার)", tip: "O-kar (ো)"),
        CheatEntry(latin: "kOU", bangla: "কৌ", category: "Vowel Signs (কার)", tip: "OU-kar (ৌ)"),

        // Conjuncts
        CheatEntry(latin: "kkh / x", bangla: "ক্ষ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ক + ষ"),
        CheatEntry(latin: "jnh / G", bangla: "জ্ঞ", category: "Conjuncts (যুক্তবর্ণ)", tip: "জ + ঞ"),
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
        CheatEntry(latin: "shch", bangla: "শ্চ", category: "Conjuncts (যুক্তবর্ণ)", tip: "শ + চ"),
        CheatEntry(latin: "ShTh", bangla: "ষ্ঠ", category: "Conjuncts (যুক্তবর্ণ)", tip: "ষ + ঠ"),
        CheatEntry(latin: "hn", bangla: "হ্ন", category: "Conjuncts (যুক্তবর্ণ)", tip: "হ + ন"),
        CheatEntry(latin: "hm", bangla: "হ্ম", category: "Conjuncts (যুক্তবর্ণ)", tip: "হ + ম"),

        // Numbers
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
        entries.filter { entry in
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
                ForEach(categories, id: \.self) { cat in
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
