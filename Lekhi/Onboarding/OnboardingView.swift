//
//  OnboardingView.swift
//  Lekhi
//
//  Interactive introduction shown on first launch.
//

import SwiftUI
import UIKit

struct OnboardingView: View {

    let onComplete: () -> Void

    @State private var step: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.54, blue: 1.0),
                    Color(red: 0.04, green: 0.32, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                TabView(selection: $step) {
                    OnboardingCard(
                        customImage: "AppLogo",
                        title: "Welcome to Lekhi",
                        subtitle: "The 3D Mechanical Avro Phonetic Bangla Keyboard for iOS. Type `ami` and Lekhi writes আমি.",
                        accent: .white
                    )
                    .tag(0)

                    OnboardingCard(
                        icon: "gearshape.fill",
                        title: "Enable Lekhi",
                        subtitle: "Open Settings → General → Keyboard → Keyboards → Add New Keyboard → Lekhi.",
                        accent: .white,
                        action: openSettings,
                        buttonLabel: "Open Settings"
                    )
                    .tag(1)

                    OnboardingCard(
                        icon: "globe",
                        title: "Switch to Lekhi",
                        subtitle: "In any app, tap and hold the 🌐 globe key on your keyboard and pick Lekhi to start typing Bangla.",
                        accent: .white
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                Spacer()

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(step == i ? Color.white : Color.white.opacity(0.35))
                            .frame(width: step == i ? 28 : 8, height: 8)
                            .animation(.easeInOut, value: step)
                    }
                }
                .padding(.bottom, 12)

                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        if step < 2 {
            Button {
                withAnimation { step += 1 }
            } label: {
                Text("Next")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(red: 0.08, green: 0.54, blue: 1.0))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
            }
        } else {
            Button {
                onComplete()
            } label: {
                Text("Start Typing Bangla")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(red: 0.08, green: 0.54, blue: 1.0))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct OnboardingCard: View {
    let icon: String?
    let customImage: String?
    let title: String
    let subtitle: String
    let accent: Color
    let action: (() -> Void)?
    let buttonLabel: String?

    init(
        icon: String? = nil,
        customImage: String? = nil,
        title: String,
        subtitle: String,
        accent: Color,
        action: (() -> Void)? = nil,
        buttonLabel: String? = nil
    ) {
        self.icon = icon
        self.customImage = customImage
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.action = action
        self.buttonLabel = buttonLabel
    }

    var body: some View {
        VStack(spacing: 20) {
            if let customImage {
                Image(customImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .regular))
                    .foregroundStyle(accent)
                    .padding(28)
                    .background(
                        Circle().fill(Color.white.opacity(0.18))
                    )
            }

            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            if let action, let buttonLabel {
                Button(buttonLabel, action: action)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().stroke(Color.white, lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, 24)
    }
}
