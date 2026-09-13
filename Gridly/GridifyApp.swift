//
//  GridifyApp.swift
//  Gridify
//

import SwiftUI

@main
struct GridifyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var settings = UserSettings.shared

    var body: some Scene {
        MenuBarExtra("Gridify", systemImage: "squareshape.split.2x2") {
            MenuBarView {
                appDelegate.openSettingsWindow()
            }
        }

        Settings {
            SettingsView()
        }
    }
}
