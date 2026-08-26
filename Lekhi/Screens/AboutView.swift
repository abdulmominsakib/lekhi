//
//  AboutView.swift
//  Lekhi
//
//  About, credits, and privacy information for Lekhi.
//

import SwiftUI

struct AboutView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    group(title: "Open Source & License") {
                        CreditRow(
                            title: "GitHub Repository",
                            subtitle: "github.com/abdulmominsakib/lekhi (MIT License)",
                            url: URL(string: "https://github.com/abdulmominsakib/lekhi")
                        )
                        CreditRow(
                            title: "Developer Website",
                            subtitle: "momin.pro",
                            url: URL(string: "https://momin.pro")
                        )
                        CreditRow(
                            title: "Privacy Policy",
                            subtitle: "momin.pro/lekhi-privacy-policy",
                            url: URL(string: "https://momin.pro/lekhi-privacy-policy")
                        )
                    }

                    group(title: "Credits & Upstream") {
                        CreditRow(
                            title: "OpenBangla / riti",
                            subtitle: "Transliteration engine, MPL-2.0",
                            url: URL(string: "https://github.com/OpenBangla/riti")
                        )
                        CreditRow(
                            title: "Lekho (macOS)",
                            subtitle: "Original macOS reference keyboard by Abdur Rahim",
                            url: URL(string: "https://github.com/ARahim3/Lekho")
                        )
                    }

                    group(title: "Privacy & Security") {
                        InfoRow(
                            icon: "lock.shield.fill",
                            text: "**100% Offline & Private**. Lekhi is free and open-source under the MIT License. It does not require Open Access, network access, or tracking. What you type stays on your device."
                        )
                    }

                    group(title: "Version & License") {
                        LabeledContent("App") {
                            Text(Bundle.main.appVersion)
                        }
                        LabeledContent("Build") {
                            Text(Bundle.main.buildNumber)
                        }
                        LabeledContent("License") {
                            Text("MIT License")
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Lekhi (লেখী)")
                    .font(.system(size: 24, weight: .bold))
                Text("3D Mechanical Avro Phonetic Bangla Keyboard for iOS.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func group<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

private struct CreditRow: View {
    let title: String
    let subtitle: String
    let url: URL?

    var body: some View {
        if let url {
            Link(destination: url) {
                row
            }
        } else {
            row
        }
    }

    private var row: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.08, green: 0.54, blue: 1.0))
                .frame(width: 24)
            Text(.init(text))
                .font(.system(size: 14))
                .foregroundStyle(.primary)
        }
        .padding(14)
    }
}

private extension Bundle {
    var appVersion: String {
        (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }
    var buildNumber: String {
        (object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
    }
}
