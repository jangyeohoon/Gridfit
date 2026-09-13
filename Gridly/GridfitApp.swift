//
//  GridfitApp.swift
//  Gridfit
//

import SwiftUI

@main
struct GridfitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var settings = UserSettings.shared

    var body: some Scene {
        MenuBarExtra("Gridfit", systemImage: "squareshape.split.2x2") {
            MenuBarView {
                appDelegate.openSettingsWindow()
            }
        }

        Settings {
            SettingsView()
        }
    }
}
