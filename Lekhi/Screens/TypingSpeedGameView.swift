//
//  TypingSpeedGameView.swift
//  Lekhi
//
//  Interactive Bangla typing speed & practice module with real-time WPM,
//  accuracy tracking, and satisfying feedback.
//

import SwiftUI

struct TypingPrompt: Identifiable {
    let id = UUID()
    let text: String
    let phoneticHint: String
    let difficulty: String
}

struct TypingSpeedGameView: View {

    private let prompts: [TypingPrompt] = [
        TypingPrompt(text: "আমার সোনার বাংলা আমি তোমায় ভালোবাসি", phoneticHint: "amar sonar bangla ami tomay bhalobasi", difficulty: "Medium"),
        TypingPrompt(text: "বাংলা আমার মাতৃভাষা", phoneticHint: "bangla amar matribhasha", difficulty: "Easy"),
        TypingPrompt(text: "সবার উপরে মানুষ সত্য তাহার উপরে নাই", phoneticHint: "sobar upore manush shotyo tahar upore nai", difficulty: "Medium"),
        TypingPrompt(text: "মোদের গরব মোদের আশা আ মরি বাংলা ভাষা", phoneticHint: "moder gorob moder asha a mori bangla bhasha", difficulty: "Hard"),
        TypingPrompt(text: "তুমি কেমন আছো", phoneticHint: "tumi kemon acho", difficulty: "Easy"),
        TypingPrompt(text: "বাংলাদেশ একটি সুন্দর দেশ", phoneticHint: "bangladesh ekti sundor desh", difficulty: "Easy"),
        TypingPrompt(text: "জ্ঞান যেখানে সীমাবদ্ধ যুক্তি সেখানে আড়ষ্ট", phoneticHint: "gyan jekhane shimaboddho jukti shekhane aroshto", difficulty: "Hard")
    ]

    @State private var currentPromptIndex: Int = 0
    @State private var inputString: String = ""
    @State private var isRunning: Bool = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var completedWords: Int = 0
    @State private var accuracy: Double = 100.0
    @State private var wpm: Int = 0
    @State private var timer: Timer?

    var currentPrompt: TypingPrompt {
        prompts[currentPromptIndex % prompts.count]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    statsHeader

                    // Target Sentence Card
                    targetSentenceCard

                    // Input Field
                    inputArea

                    // Next / Reset Buttons
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Typing Practice")
            .onDisappear {
                stopTimer()
            }
        }
    }

    // MARK: - Views

    private var statsHeader: some View {
        HStack(spacing: 12) {
            statBadge(title: "WPM", value: "\(wpm)", color: .blue)
            statBadge(title: "Accuracy", value: String(format: "%.0f%%", accuracy), color: .green)
            statBadge(title: "Time", value: String(format: "%.1fs", elapsedTime), color: .orange)
        }
    }

    private func statBadge(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
        )
    }

    private var targetSentenceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Target Text")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currentPrompt.difficulty)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.15)))
                    .foregroundStyle(.blue)
            }

            Text(currentPrompt.text)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.primary)
                .lineSpacing(6)

            Divider()

            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
                Text("Phonetic: ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(currentPrompt.phoneticHint)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
        )
    }

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type Here")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Start typing Bangla...", text: $inputString, axis: .vertical)
                .font(.system(size: 20))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isRunning ? Color.blue : Color.clear, lineWidth: 1.5)
                        )
                )
                .onChange(of: inputString) { _, newValue in
                    handleTypingUpdate(newValue)
                }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                resetTest()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }

            Button {
                nextPrompt()
            } label: {
                Label("Next Text", systemImage: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.08, green: 0.54, blue: 1.0))
                    )
            }
        }
    }

    // MARK: - Logic

    private func startTimerIfNeeded() {
        guard !isRunning else { return }
        isRunning = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
                calculateStats()
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func handleTypingUpdate(_ text: String) {
        if !isRunning && !text.isEmpty {
            startTimerIfNeeded()
        }

        calculateStats()

        // Check if finished
        if text.trimmingCharacters(in: .whitespacesAndNewlines) == currentPrompt.text.trimmingCharacters(in: .whitespacesAndNewlines) {
            stopTimer()
            HapticManager.shared.keyPress(isAction: true)
        }
    }

    private func calculateStats() {
        guard elapsedTime > 0 else { return }

        let target = currentPrompt.text
        let typed = inputString

        // Calculate accuracy
        var matchCount = 0
        let minLength = min(target.count, typed.count)
        let targetChars = Array(target)
        let typedChars = Array(typed)

        for i in 0..<minLength {
            if targetChars[i] == typedChars[i] {
                matchCount += 1
            }
        }

        if !typed.isEmpty {
            accuracy = max(0, min(100.0, (Double(matchCount) / Double(typed.count)) * 100.0))
        }

        // Calculate WPM (5 characters = 1 word)
        let words = Double(matchCount) / 5.0
        let minutes = elapsedTime / 60.0
        if minutes > 0 {
            wpm = Int(words / minutes)
        }
    }

    private func resetTest() {
        stopTimer()
        inputString = ""
        elapsedTime = 0
        wpm = 0
        accuracy = 100.0
    }

    private func nextPrompt() {
        resetTest()
        currentPromptIndex = (currentPromptIndex + 1) % prompts.count
    }
}
