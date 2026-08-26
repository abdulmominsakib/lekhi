//
//  KeyboardPreviewScreen.swift
//  Lekhi
//
//  Playground screen: a native iOS text editor that lets the user
//  type Bengali with the Lekhi keyboard extension (or any other keyboard).
//  The user taps "Tap to start writing Bangla…" and the real iOS
//  keyboard appears.
//

import SwiftUI
import UIKit

// MARK: - Main View

struct KeyboardPreviewScreen: View {

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats bar
                if !text.isEmpty {
                    statsBar
                }

                // Full-screen native editor
                nativeEditor
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !text.isEmpty {
                            Button("Clear") {
                                text = ""
                            }
                            .foregroundStyle(.red)
                        }
                        if isFocused {
                            Button("Done") {
                                isFocused = false
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }

    // MARK: - Native Editor

    private var nativeEditor: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tap to start writing Bangla…")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.top, 16)
                        .padding(.horizontal, 16)

                    instructionBanner
                        .padding(.horizontal, 12)

                    Spacer()
                }
            }

            // Actual text editor
            TextEditor(text: $text)
                .font(.system(size: 22, design: .rounded))
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(8)
                .opacity(text.isEmpty ? 0.05 : 1.0)  // keep it tappable even when "empty-looking"
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(16)
        .onTapGesture {
            isFocused = true
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        let words = text.split { $0.isWhitespace }.count
        let chars = text.count

        return HStack(spacing: 20) {
            statPill(label: "Words", value: "\(words)", icon: "text.word.spacing")
            statPill(label: "Characters", value: "\(chars)", icon: "character.cursor.ibeam")
            Spacer()
            Button {
                UIPasteboard.general.string = text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    private func statPill(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Instruction Banner

    private var instructionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Enable the Lekhi Keyboard", systemImage: "keyboard")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Settings → General → Keyboard → Keyboards → Add New Keyboard → Lekhi")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Label("Then switch keyboards with 🌐 while typing", systemImage: "globe")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Text("Type **ami** and Lekhi will write **আমি**")
                .font(.system(size: 13))
                .foregroundStyle(.primary)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.blue.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        )
    }
}