//
//  AccessibilityManager.swift
//  Gridfit
//

import AppKit
import ApplicationServices
import Combine
import os

/// Manages and observes macOS Accessibility permissions required for window inspection and manipulation.
public final class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()

    @Published public private(set) var isTrusted: Bool = false

    private var checkTimer: Timer?
    private var activeObserver: NSObjectProtocol?

    private init() {
        checkTrust()
        if !isTrusted {
            startPolling()
        }
        setupActiveObserver()
    }

    deinit {
        stopPolling()
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Checks whether the current application is trusted for Accessibility.
    @discardableResult
    public func checkTrust() -> Bool {
        let trusted = AXIsProcessTrusted()
        let updateBlock = { [weak self] in
            guard let self = self else { return }
            if self.isTrusted != trusted {
                self.isTrusted = trusted
                if trusted {
                    AppLogger.accessibility.info("Accessibility trust granted.")
                    self.stopPolling()
                } else {
                    AppLogger.accessibility.notice("Accessibility trust revoked or missing.")
                }
            }
        }
        if Thread.isMainThread {
            updateBlock()
        } else {
            DispatchQueue.main.async(execute: updateBlock)
        }
        return trusted
    }

    /// Prompts the user with the system dialog to grant Accessibility permissions.
    public func promptForPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        let updateBlock = { [weak self] in
            guard let self = self else { return }
            self.isTrusted = trusted
            if !trusted {
                self.startPolling()
            }
        }
        if Thread.isMainThread {
            updateBlock()
        } else {
            DispatchQueue.main.async(execute: updateBlock)
        }
    }

    /// Opens macOS System Settings directly to Privacy & Security > Accessibility.
    public func openSystemSettings() {
        startPolling()
        // macOS Ventura (13) and newer settings URL
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startPolling() {
        guard checkTimer == nil && !isTrusted else { return }
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkTrust()
        }
    }

    private func stopPolling() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func setupActiveObserver() {
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkTrust()
        }
    }
}
