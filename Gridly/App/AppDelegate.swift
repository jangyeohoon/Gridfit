//
//  AppDelegate.swift
//  Gridfit
//

import AppKit
import SwiftUI
import os

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?

    private var settingsWindowController: NSWindowController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Register Global HotKey from user settings
        HotKeyManager.shared.registerFromSettings()

        // Check Accessibility permissions
        if !AccessibilityManager.shared.checkTrust() {
            AppLogger.accessibility.notice("Accessibility permissions not granted on startup.")
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }

    /// Opens or brings forward the Settings window
    public func openSettingsWindow() {
        if let existingController = settingsWindowController, let window = existingController.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Gridfit Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        self.settingsWindowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
