//
//  AccessibilityManager.swift
//  Gridly
//

import AppKit
import ApplicationServices
import Combine

/// Manages and observes macOS Accessibility permissions required for window inspection and manipulation.
public final class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()

    @Published public private(set) var isTrusted: Bool = false

    private var checkTimer: Timer?

    private init() {
        checkTrust()
        startPolling()
    }

    deinit {
        checkTimer?.invalidate()
    }

    /// Checks whether the current application is trusted for Accessibility.
    @discardableResult
    public func checkTrust() -> Bool {
        let trusted = AXIsProcessTrusted()
        if self.isTrusted != trusted {
            DispatchQueue.main.async {
                self.isTrusted = trusted
            }
        }
        return trusted
    }

    /// Prompts the user with the system dialog to grant Accessibility permissions.
    public func promptForPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.async {
            self.isTrusted = trusted
        }
    }

    /// Opens macOS System Settings directly to Privacy & Security > Accessibility.
    public func openSystemSettings() {
        // macOS Ventura (13) and newer settings URL
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startPolling() {
        // Periodically verify trust so UI updates automatically if user enables it in Settings
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkTrust()
        }
    }
}
