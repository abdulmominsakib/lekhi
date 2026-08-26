//
//  TestTextFieldView.swift
//  Lekhi
//
//  Quick test sheet with a Bangla-friendly text editor.
//

import SwiftUI

struct TestTextFieldView: View {

    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tap the text field below to summon the keyboard. If needed, switch to Lekhi via the 🌐 globe key.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                TextEditor(text: $text)
                    .font(.system(size: 22))
                    .padding(8)
                    .frame(minHeight: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                examples
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Try Lekhi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var examples: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Examples to try")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            ForEach([
                ("ami banglay gan gai", "আমি বাংলায় গান গাই"),
                ("amar sonar bangla", "আমার সোনার বাংলা"),
                ("tumi kemon acho", "তুমি কেমন আছো"),
                ("shuvo noboborsho", "শুভ নববর্ষ")
            ], id: \.0) { latin, bangla in
                HStack {
                    Text(latin)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("→")
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(bangla)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }
}
