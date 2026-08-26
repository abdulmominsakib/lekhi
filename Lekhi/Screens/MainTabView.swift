//
//  MainTabView.swift
//  Lekhi
//
//  Tab bar interface: Home, Playground, Cheat Sheet, Settings.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            KeyboardPreviewScreen()
                .tabItem {
                    Label("Playground", systemImage: "keyboard.fill")
                }
                .tag(1)

            CheatSheetView()
                .tabItem {
                    Label("Cheat Sheet", systemImage: "character.book.closed.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Color(red: 0.08, green: 0.54, blue: 1.0))
    }
}
