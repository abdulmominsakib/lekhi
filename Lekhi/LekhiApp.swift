//
//  LekhiApp.swift
//  Lekhi
//
//  App entry point.
//

import SwiftUI

@main
struct LekhiApp: App {

    @AppStorage("LekhiOnboardingCompleted")
    private var onboardingCompleted: Bool = true

    init() {
        // Copy data files so both host and keyboard extension have them
        try? DataPaths.ensureDataFilesCopied()
    }

    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                MainTabView()
            } else {
                OnboardingView {
                    onboardingCompleted = true
                }
            }
        }
    }
}
