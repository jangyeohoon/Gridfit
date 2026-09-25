//
//  OnboardingView.swift
//  Gridfit
//

import SwiftUI
import ServiceManagement

struct OnboardingView: View {
    @ObservedObject var accessibility = AccessibilityManager.shared
    @ObservedObject var settings = UserSettings.shared
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // App Header
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Gridfit")
                        .font(.title2.bold())
                    Text("Intelligent, native window auto-tiling for macOS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.top, 8)

            Divider()

            // Accessibility Permission Status Card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: accessibility.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accessibility.isTrusted ? .green : .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(accessibility.isTrusted ? "Accessibility Access Granted" : "Accessibility Permission Required")
                            .font(.headline)

                        Text(accessibility.isTrusted
                             ? "Gridfit has the required permissions to detect and arrange application windows."
                             : "macOS requires Accessibility permissions for Gridfit to move and resize windows. Gridfit operates strictly on window coordinates and never captures keystrokes, personal data, or screen contents.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !accessibility.isTrusted {
                    HStack {
                        Spacer()
                        Button {
                            accessibility.promptForPermission()
                            accessibility.openSystemSettings()
                        } label: {
                            Label("Open System Settings", systemImage: "gearshape")
                                .padding(.horizontal, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(accessibility.isTrusted ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accessibility.isTrusted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
            )

            // Features Summary
            VStack(alignment: .leading, spacing: 14) {
                Text("How to Use Gridfit")
                    .font(.headline)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "command")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Global Auto-Arrange Shortcut: \(settings.hotkeyDisplayString)")
                            .font(.subheadline.weight(.semibold))
                        Text("Press anywhere to instantly tile all visible windows into a clean, balanced grid.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "squareshape.split.2x2")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Menu Bar & Quick Snap")
                            .font(.subheadline.weight(.semibold))
                        Text("Snap the active window to halves, maximize, or move across multiple monitors.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Instant Undo (⌘Z)")
                            .font(.subheadline.weight(.semibold))
                        Text("Restore windows back to their previous locations and sizes with one click.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer()

            Divider()

            // Footer / Actions
            HStack {
                Toggle("Launch Gridfit at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        if #available(macOS 13.0, *) {
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                AppLogger.general.error("Launch at login error: \(error)")
                            }
                        }
                    }

                Spacer()

                Button("Get Started") {
                    settings.hasCompletedOnboarding = true
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520, height: 500)
    }
}
