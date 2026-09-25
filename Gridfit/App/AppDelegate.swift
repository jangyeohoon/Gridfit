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
    private var onboardingWindowController: NSWindowController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Register Global HotKey from user settings
        HotKeyManager.shared.registerFromSettings()

        // Check Accessibility permissions and show onboarding if needed
        let isTrusted = AccessibilityManager.shared.checkTrust()
        if !isTrusted {
            AppLogger.accessibility.notice("Accessibility permissions not granted on startup.")
        }

        if !UserSettings.shared.hasCompletedOnboarding || !isTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.openOnboardingWindow()
            }
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

    /// Opens or brings forward the Onboarding & Permission Guide window
    public func openOnboardingWindow() {
        if let existingController = onboardingWindowController, let window = existingController.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            self?.onboardingWindowController?.window?.close()
            self?.onboardingWindowController = nil
        }

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to Gridfit"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        self.onboardingWindowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
