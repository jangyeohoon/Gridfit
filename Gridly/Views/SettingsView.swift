//
//  SettingsView.swift
//  Gridify
//

import SwiftUI
import ServiceManagement
import os

struct SettingsView: View {
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var accessibility = AccessibilityManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var selectedAppToAdd: String = ""

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case layout = "Layout"
        case behavior = "Behavior"
        case shortcuts = "Shortcuts"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .general: return "gearshape"
            case .layout: return "square.grid.2x2"
            case .behavior: return "slider.horizontal.3"
            case .shortcuts: return "command"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            layoutTab
                .tabItem {
                    Label("Layout", systemImage: "square.grid.2x2")
                }
                .tag(SettingsTab.layout)

            behaviorTab
                .tabItem {
                    Label("Behavior", systemImage: "slider.horizontal.3")
                }
                .tag(SettingsTab.behavior)

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(SettingsTab.shortcuts)
        }
        .padding(20)
        .frame(width: 500, height: 440)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch Gridify at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(enabled: newValue)
                    }
            } header: {
                Text("Startup")
            }

            Section {
                HStack {
                    Image(systemName: accessibility.isTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(accessibility.isTrusted ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(accessibility.isTrusted ? "Accessibility Granted" : "Accessibility Required")
                            .font(.headline)
                        Text(accessibility.isTrusted
                             ? "Gridify can control and tile windows."
                             : "Window manipulation requires macOS Accessibility permissions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(accessibility.isTrusted ? "Settings" : "Grant Access") {
                        accessibility.openSystemSettings()
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Permissions")
            }

            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gridify")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Native macOS Window Auto-Tiler")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Layout Tab

    private var layoutTab: some View {
        Form {
            Section {
                HStack {
                    Text("Screen Padding:")
                    Spacer()
                    Slider(value: $settings.screenPadding, in: 0...32, step: 2)
                        .frame(width: 140)
                    Text("\(Int(settings.screenPadding)) pt")
                        .frame(width: 45, alignment: .trailing)
                }

                HStack {
                    Text("Window Spacing:")
                    Spacer()
                    Slider(value: $settings.horizontalSpacing, in: 0...32, step: 2)
                        .frame(width: 140)
                        .onChange(of: settings.horizontalSpacing) { _, val in
                            settings.verticalSpacing = val
                        }
                    Text("\(Int(settings.horizontalSpacing)) pt")
                        .frame(width: 45, alignment: .trailing)
                }

                Toggle("Consider window aspect ratio", isOn: $settings.considerAspectRatio)
            } header: {
                Text("Spacing & Sizing")
            }

            Section {
                HStack {
                    Text("Minimum Window Width:")
                    Spacer()
                    TextField("Width", value: $settings.minWindowWidth, format: .number)
                        .frame(width: 70)
                        .textFieldStyle(.roundedBorder)
                    Text("pt")
                }

                HStack {
                    Text("Minimum Window Height:")
                    Spacer()
                    TextField("Height", value: $settings.minWindowHeight, format: .number)
                        .frame(width: 70)
                        .textFieldStyle(.roundedBorder)
                    Text("pt")
                }
            } header: {
                Text("Minimum Dimensions")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Behavior Tab

    private var behaviorTab: some View {
        Form {
            Section {
                Toggle("Group windows by application", isOn: $settings.groupByApplication)
                Toggle("Exclude minimized windows", isOn: $settings.excludeMinimizedWindows)
                Toggle("Exclude full-screen windows", isOn: $settings.excludeFullScreenWindows)
                Toggle("Auto-arrange when displays change", isOn: $settings.autoArrangeOnDisplayChange)
            } header: {
                Text("Arrangement Rules")
            } footer: {
                Text("When enabled, windows belonging to the same application are kept adjacent, and arrangements automatically adapt when monitors are connected or disconnected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                let runningApps = getRunningUserApps()
                if runningApps.isEmpty {
                    Text("No running applications detected")
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Picker("Exclude App", selection: $selectedAppToAdd) {
                            Text("Select an app to exclude...").tag("")
                            ForEach(runningApps, id: \.bundleIdentifier) { app in
                                Text(app.localizedName ?? "App")
                                    .tag(app.bundleIdentifier ?? "")
                            }
                        }

                        Button("Add") {
                            if !selectedAppToAdd.isEmpty {
                                settings.addExcludedApp(bundleID: selectedAppToAdd)
                                selectedAppToAdd = ""
                            }
                        }
                        .disabled(selectedAppToAdd.isEmpty)
                    }
                }

                if !settings.excludedBundleIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(settings.excludedBundleIDs).sorted(), id: \.self) { bundleID in
                            HStack {
                                Text(displayName(for: bundleID))
                                    .font(.subheadline)
                                Spacer()
                                Text(bundleID)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Button {
                                    settings.removeExcludedApp(bundleID: bundleID)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } header: {
                Text("Excluded Applications")
            } footer: {
                Text("Excluded applications will keep their current dimensions and screen position without being arranged into the grid.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Shortcuts Tab

    private var shortcutsTab: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Arrange Windows:")
                            .font(.body)
                        Text("Click the shortcut to record a new key combination")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ShortcutRecorderView(
                        keyCode: $settings.hotkeyKeyCode,
                        modifiers: $settings.hotkeyModifiers,
                        onShortcutChanged: {
                            HotKeyManager.shared.registerFromSettings()
                        }
                    )
                }
                .padding(.vertical, 4)

                if !settings.isDefaultHotkey {
                    HStack {
                        Spacer()
                        Button("Reset to Default (⌘⇧G)") {
                            settings.resetHotkeyToDefault()
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
            } header: {
                Text("Global Hotkey")
            } footer: {
                Text("Current shortcut: \(settings.hotkeyDisplayString). Press this key combination from any application to immediately arrange all visible windows into an optimal grid.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack(spacing: 8) {
                    PresetShortcutButton(label: "⌘⇧G (Default)", keyCode: 5, modifiers: 0x0100 | 0x0200)
                    PresetShortcutButton(label: "⌥Space", keyCode: 49, modifiers: 0x0800)
                    PresetShortcutButton(label: "⌘⌥G", keyCode: 5, modifiers: 0x0100 | 0x0800)
                    PresetShortcutButton(label: "⌃⌥G", keyCode: 5, modifiers: 0x1000 | 0x0800)
                }
                .padding(.vertical, 2)
            } header: {
                Text("Quick Presets")
            } footer: {
                Text("Click any preset above to instantly switch to a popular window tiling shortcut.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func displayName(for bundleID: String) -> String {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }),
           let name = app.localizedName {
            return name
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url.deletingPathExtension().lastPathComponent
        }
        return bundleID
    }

    private func getRunningUserApps() -> [NSRunningApplication] {
        let ownPID = NSRunningApplication.current.processIdentifier
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != ownPID && $0.bundleIdentifier != nil }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                AppLogger.general.error("Failed to update launch at login: \(error)")
            }
        }
    }
}

struct PresetShortcutButton: View {
    let label: String
    let keyCode: Int
    let modifiers: Int
    @ObservedObject var settings = UserSettings.shared

    var isSelected: Bool {
        settings.hotkeyKeyCode == keyCode && settings.hotkeyModifiers == modifiers
    }

    var body: some View {
        Button {
            settings.hotkeyKeyCode = keyCode
            settings.hotkeyModifiers = modifiers
            HotKeyManager.shared.registerFromSettings()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ShortcutRecorderView: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    var onShortcutChanged: () -> Void

    @State private var isRecording: Bool = false
    @State private var liveModifiers: [String] = []
    @State private var eventMonitor: Any? = nil
    @State private var isHovered: Bool = false

    var currentBadges: [String] {
        var badges = ShortcutFormatter.modifierBadges(for: UInt32(modifiers))
        badges.append(ShortcutFormatter.keyString(for: UInt16(keyCode)))
        return badges
    }

    var body: some View {
        HStack(spacing: 6) {
            if isRecording {
                HStack(spacing: 4) {
                    if liveModifiers.isEmpty {
                        Image(systemName: "record.circle")
                            .foregroundColor(.accentColor)
                        Text("Type shortcut...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                    } else {
                        ForEach(liveModifiers, id: \.self) { mod in
                            KeyBadge(label: mod, isRecording: true)
                        }
                        Text("...")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.12))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                )

                Button {
                    stopRecording()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Cancel recording (Esc)")
            } else {
                HStack(spacing: 4) {
                    ForEach(currentBadges, id: \.self) { badge in
                        KeyBadge(label: badge, isRecording: false)
                    }
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .opacity(isHovered ? 1.0 : 0.4)
                        .padding(.leading, 2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isHovered ? Color(nsColor: .controlColor) : Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isHovered ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.25), lineWidth: 1)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .onTapGesture {
                    startRecording()
                }
                .help("Click to record a new shortcut")
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        liveModifiers = []

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .flagsChanged {
                let carbonMods = ShortcutFormatter.carbonModifiers(from: event.modifierFlags)
                DispatchQueue.main.async {
                    self.liveModifiers = ShortcutFormatter.modifierBadges(for: carbonMods)
                }
                return nil
            }

            if event.type == .keyDown {
                // Escape key (53): cancel
                if event.keyCode == 53 {
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                    return nil
                }

                let carbonMods = ShortcutFormatter.carbonModifiers(from: event.modifierFlags)
                let isFunctionKey = (event.keyCode >= 0x7A && event.keyCode <= 0x83) // F1...F12

                // Require at least one modifier key or a function key
                guard carbonMods != 0 || isFunctionKey else {
                    return nil
                }

                DispatchQueue.main.async {
                    self.keyCode = Int(event.keyCode)
                    self.modifiers = Int(carbonMods)
                    self.onShortcutChanged()
                    self.stopRecording()
                }
                return nil
            }

            return event
        }
    }

    private func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isRecording = false
        liveModifiers = []
    }
}

struct KeyBadge: View {
    let label: String
    var isRecording: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(isRecording ? Color.accentColor.opacity(0.2) : Color(nsColor: .windowBackgroundColor))
            .foregroundColor(isRecording ? .accentColor : .primary)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isRecording ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
