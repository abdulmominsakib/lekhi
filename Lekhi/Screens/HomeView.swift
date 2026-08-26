//
//  HomeView.swift
//  Lekhi
//
//  Landing dashboard. Features keyboard enablement status, mechanical
//  keyboard playground launcher, cheat sheet, and typing practice.
//

import SwiftUI
import UIKit

struct HomeView: View {

    @State private var isEnabled = false
    @State private var showTestField = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    statusCard

                    heroPlaygroundCard

                    navigationGrid

                    quickPhoneticGuide

                    openSourceCard

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lekhi")
            .sheet(isPresented: $showTestField) {
                TestTextFieldView()
            }
            .onAppear { isEnabled = checkKeyboardEnabled() }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("লেখী")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(Color(red: 0.08, green: 0.54, blue: 1.0))
                    Text("• Lekhi")
                        .font(.system(size: 24, weight: .bold))
                }
                Text("Tactile 3D Mechanical Avro Phonetic Bangla Keyboard")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: isEnabled
                      ? "checkmark.circle.fill"
                      : "exclamationmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(isEnabled ? .green : .orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEnabled ? "Lekhi is enabled & ready" : "Enable Lekhi in Settings")
                        .font(.system(size: 17, weight: .semibold))
                    Text(isEnabled
                         ? "Switch to Lekhi with the globe key in any iOS app."
                         : "Open Settings → General → Keyboard → Keyboards → Add New Keyboard → Lekhi.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            if !isEnabled {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.08, green: 0.54, blue: 1.0))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
        )
    }

    private var heroPlaygroundCard: some View {
        NavigationLink {
            KeyboardPreviewScreen()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mechanical Playground")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("Experience tactile 3D switches, audio clicks & live transliteration")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(red: 0.08, green: 0.54, blue: 1.0))
                }

                // Mini preview keycap row
                HStack(spacing: 8) {
                    miniKeycap(label: "a", bangla: "া")
                    miniKeycap(label: "m", bangla: "ম")
                    miniKeycap(label: "i", bangla: "ি")
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    miniKeycap(label: "আমি", isAccent: true)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.08, green: 0.54, blue: 1.0).opacity(0.2), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func miniKeycap(label: String, bangla: String? = nil, isAccent: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: isAccent ? 14 : 15, weight: .bold))
                .foregroundStyle(isAccent ? .white : .primary)
            if let bangla {
                Text(bangla)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: isAccent ? 54 : 38, height: 38)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isAccent ? Color(red: 0.08, green: 0.54, blue: 1.0) : Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 1, y: 1.5)
        )
    }

    private var navigationGrid: some View {
        HStack(spacing: 12) {
            NavigationLink {
                CheatSheetView()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                    Text("Avro Cheat Sheet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Learn shortcuts")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                TypingSpeedGameView()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.purple)
                    Text("Typing Speed Test")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Practice & test WPM")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var quickPhoneticGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phonetic Examples")
                .font(.system(size: 18, weight: .semibold))

            ExampleRow(latin: "ami", bangla: "আমি")
            ExampleRow(latin: "bangla", bangla: "বাংলা")
            ExampleRow(latin: "tumi kemon acho", bangla: "তুমি কেমন আছো")
            ExampleRow(latin: "amar sonar bangla", bangla: "আমার সোনার বাংলা")
        }
    }

    private var openSourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 0.08, green: 0.54, blue: 1.0))
                        Text("Open Source")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("MIT")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.12)))
                            .foregroundStyle(.blue)
                    }
                    Text("Lekhi is free and open-source software under the MIT License.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let url = URL(string: "https://github.com/abdulmominsakib/lekhi") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "arrow.up.right.circle.fill")
                        Text("View on GitHub (abdulmominsakib/lekhi)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
        )
    }

    private func checkKeyboardEnabled() -> Bool {
        return UITextInputMode.activeInputModes.contains { mode in
            mode.primaryLanguage != nil
                && (mode.value(forKey: "identifier") as? String)?
                    .lowercased()
                    .contains("lekhi") == true
        }
    }
}

private struct ExampleRow: View {
    let latin: String
    let bangla: String

    var body: some View {
        HStack {
            Text(latin)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 180, alignment: .leading)
            Text("→")
                .foregroundStyle(.tertiary)
            Text(bangla)
                .font(.system(size: 18))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
