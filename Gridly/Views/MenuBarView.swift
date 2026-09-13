//
//  MenuBarView.swift
//  Gridify
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var windowManager = WindowManager.shared
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var accessibility = AccessibilityManager.shared
    var openSettingsAction: () -> Void

    var body: some View {
        VStack {
            // Header / Status
            if let summary = windowManager.lastResultSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Primary Actions
            Button {
                windowManager.arrangeAllWindows()
            } label: {
                HStack {
                    Text("Arrange All Screens")
                    Spacer()
                    Text(settings.hotkeyDisplayString).foregroundStyle(.secondary)
                }
            }

            Button {
                windowManager.arrangeActiveScreen()
            } label: {
                Text("Arrange Current Screen")
            }

            Button {
                windowManager.undoLastArrangement()
            } label: {
                Text("Undo Last Arrangement")
            }
            .disabled(!windowManager.canUndo)
            .keyboardShortcut("z", modifiers: [.command])

            Divider()

            // Layout Picker
            Menu("Layout") {
                ForEach(LayoutPreset.allCases) { preset in
                    Button {
                        settings.layoutPreset = preset
                    } label: {
                        HStack {
                            Text(preset.rawValue)
                            if settings.layoutPreset == preset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            // Accessibility Warning if not granted
            if !accessibility.isTrusted {
                Button {
                    accessibility.promptForPermission()
                    accessibility.openSystemSettings()
                } label: {
                    Label("Grant Accessibility Access...", systemImage: "exclamationmark.triangle.fill")
                }

                Divider()
            }

            // App Settings & Termination
            Button("Settings...") {
                openSettingsAction()
            }
            .keyboardShortcut(",", modifiers: [.command])

            Button("Quit Gridify") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }
}
