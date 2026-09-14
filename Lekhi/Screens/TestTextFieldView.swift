//
//  TestTextFieldView.swift
//  Lekhi
//
//  Quick test sheet with Bangla text, numeric pads, and email fields.
//

import SwiftUI

struct TestTextFieldView: View {

    @State private var text: String = ""
    @State private var numberText: String = ""
    @State private var decimalText: String = ""
    @State private var emailText: String = ""
    @State private var phoneText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tap a field below to summon the keyboard. If needed, switch to Lekhi via the 🌐 globe key.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    TextEditor(text: $text)
                        .font(.system(size: 22))
                        .padding(8)
                        .frame(minHeight: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )

                    labeledField(
                        title: "Number Pad",
                        subtitle: "Digits only — system-style numpad."
                    ) {
                        TextField("PIN", text: $numberText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 22))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }

                    labeledField(
                        title: "Decimal Pad",
                        subtitle: "Digits plus decimal point."
                    ) {
                        TextField("Amount", text: $decimalText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 22))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }

                    labeledField(
                        title: "Phone Pad",
                        subtitle: "Digit pad with *."
                    ) {
                        TextField("Phone", text: $phoneText)
                            .keyboardType(.phonePad)
                            .font(.system(size: 22))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }

                    labeledField(
                        title: "Email",
                        subtitle: "Letters with @ and . on the bottom row."
                    ) {
                        TextField("name@example.com", text: $emailText)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 22))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }

                    examples
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Try Lekhi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func labeledField<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            content()
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
