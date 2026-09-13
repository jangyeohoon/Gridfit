//
//  UserSettings.swift
//  Gridify
//

import SwiftUI
import Combine

public enum LayoutPreset: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case twoByOne = "2 × 1"
    case twoByTwo = "2 × 2"
    case threeByTwo = "3 × 2"
    case threeByThree = "3 × 3"
    case fourByThree = "4 × 3"

    public var id: String { rawValue }

    public var layout: GridLayout? {
        switch self {
        case .auto: return nil
        case .twoByOne: return GridLayout(columns: 2, rows: 1)
        case .twoByTwo: return GridLayout(columns: 2, rows: 2)
        case .threeByTwo: return GridLayout(columns: 3, rows: 2)
        case .threeByThree: return GridLayout(columns: 3, rows: 3)
        case .fourByThree: return GridLayout(columns: 4, rows: 3)
        }
    }
}

public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()

    // MARK: - Layout Settings
    @AppStorage("screenPadding") public var screenPadding: Double = 8.0
    @AppStorage("horizontalSpacing") public var horizontalSpacing: Double = 8.0
    @AppStorage("verticalSpacing") public var verticalSpacing: Double = 8.0
    @AppStorage("minWindowWidth") public var minWindowWidth: Double = 200.0
    @AppStorage("minWindowHeight") public var minWindowHeight: Double = 100.0
    @AppStorage("considerAspectRatio") public var considerAspectRatio: Bool = true
    @AppStorage("layoutPreset") public var layoutPreset: LayoutPreset = .auto

    // MARK: - Behavior Settings
    @AppStorage("groupByApplication") public var groupByApplication: Bool = true
    @AppStorage("excludeMinimizedWindows") public var excludeMinimizedWindows: Bool = true
    @AppStorage("excludeFullScreenWindows") public var excludeFullScreenWindows: Bool = true
    @AppStorage("autoArrangeOnDisplayChange") public var autoArrangeOnDisplayChange: Bool = false
    @AppStorage("excludedBundleIDsRaw") public var excludedBundleIDsRaw: String = ""

    /// Set of bundle identifiers excluded from grid auto-tiling
    public var excludedBundleIDs: Set<String> {
        get {
            let list = excludedBundleIDsRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            return Set(list.filter { !$0.isEmpty })
        }
        set {
            excludedBundleIDsRaw = newValue.sorted().joined(separator: ",")
            objectWillChange.send()
        }
    }

    public func isExcluded(bundleID: String?) -> Bool {
        guard let bundleID = bundleID, !bundleID.isEmpty else { return false }
        return excludedBundleIDs.contains(bundleID)
    }

    public func toggleExclusion(bundleID: String) {
        var current = excludedBundleIDs
        if current.contains(bundleID) {
            current.remove(bundleID)
        } else {
            current.insert(bundleID)
        }
        excludedBundleIDs = current
    }

    public func addExcludedApp(bundleID: String) {
        var current = excludedBundleIDs
        current.insert(bundleID)
        excludedBundleIDs = current
    }

    public func removeExcludedApp(bundleID: String) {
        var current = excludedBundleIDs
        current.remove(bundleID)
        excludedBundleIDs = current
    }

    // MARK: - General Settings
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false

    // MARK: - Shortcut Settings
    @AppStorage("hotkeyKeyCode") public var hotkeyKeyCode: Int = 5 // 'G' key in Carbon (kVK_ANSI_G)
    @AppStorage("hotkeyModifiers") public var hotkeyModifiers: Int = 0x0100 | 0x0200 // cmdKey | shiftKey

    /// Human-readable display string for the current hotkey (e.g. "⌘⇧G", "⌥Space").
    public var hotkeyDisplayString: String {
        ShortcutFormatter.displayString(
            keyCode: UInt16(hotkeyKeyCode),
            modifiers: UInt32(hotkeyModifiers)
        )
    }

    /// List of badge labels representing the current hotkey (e.g. ["⌘", "⇧", "G"]).
    public var hotkeyBadges: [String] {
        var badges = ShortcutFormatter.modifierBadges(for: UInt32(hotkeyModifiers))
        badges.append(ShortcutFormatter.keyString(for: UInt16(hotkeyKeyCode)))
        return badges
    }

    /// Returns true if the hotkey matches the default ⌘⇧G.
    public var isDefaultHotkey: Bool {
        return hotkeyKeyCode == 5 && hotkeyModifiers == (0x0100 | 0x0200)
    }

    /// Resets the global hotkey to the default ⌘⇧G.
    public func resetHotkeyToDefault() {
        hotkeyKeyCode = 5
        hotkeyModifiers = 0x0100 | 0x0200
        HotKeyManager.shared.registerFromSettings()
    }

    private init() {}
}
