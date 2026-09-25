//
//  MenuBarView.swift
//  Gridfit
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

            // Quick Snap Active Window Actions
            Menu("Snap Active Window") {
                Button {
                    windowManager.snapActiveWindow(to: .leftHalf)
                } label: {
                    Label("Left Half", systemImage: "rectangle.lefthalf.filled")
                }

                Button {
                    windowManager.snapActiveWindow(to: .rightHalf)
                } label: {
                    Label("Right Half", systemImage: "rectangle.righthalf.filled")
                }

                Button {
                    windowManager.snapActiveWindow(to: .topHalf)
                } label: {
                    Label("Top Half", systemImage: "rectangle.tophalf.filled")
                }

                Button {
                    windowManager.snapActiveWindow(to: .bottomHalf)
                } label: {
                    Label("Bottom Half", systemImage: "rectangle.bottomhalf.filled")
                }

                Divider()

                Button {
                    windowManager.snapActiveWindow(to: .maximize)
                } label: {
                    Label("Maximize", systemImage: "arrow.up.left.and.arrow.down.right")
                }

                Button {
                    windowManager.snapActiveWindow(to: .center)
                } label: {
                    Label("Center", systemImage: "plus.viewfinder")
                }

                Divider()

                Button {
                    windowManager.moveActiveWindowToNextDisplay()
                } label: {
                    Label("Move to Next Display", systemImage: "display.2")
                }
            }

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

            Button("Quit Gridfit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }
}
