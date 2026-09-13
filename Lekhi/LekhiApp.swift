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
        // Both targets embed the engine's data files, so nothing needs to be
        // copied at launch. Reclaim the 4 MB duplicate older builds wrote into
        // the App Group (and with it any half-written file a terminated
        // keyboard extension left behind).
        DispatchQueue.global(qos: .utility).async {
            DataPaths.removeLegacyAppGroupCopy()
        }
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
