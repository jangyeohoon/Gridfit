//
//  ShortcutFormatter.swift
//  Gridly
//

import Carbon
import AppKit

/// Formats and parses Carbon keycodes and modifiers into readable macOS shortcut strings and badges.
public struct ShortcutFormatter {
    
    /// Returns the human-readable string for a virtual key code (e.g., "G", "Space", "F1", "↩").
    public static func keyString(for keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            // Use ASCII capable layout so letters remain A-Z even on international keyboards
            if let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
               let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) {
                let dataRef = unsafeBitCast(layoutData, to: CFData.self)
                let keyLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<UCKeyboardLayout>.self)
                var deadKeyState: UInt32 = 0
                var length: Int = 0
                var chars = [UniChar](repeating: 0, count: 4)
                let status = UCKeyTranslate(
                    keyLayout,
                    keyCode,
                    UInt16(kUCKeyActionDisplay),
                    0,
                    UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysBit),
                    &deadKeyState,
                    chars.count,
                    &length,
                    &chars
                )
                if status == noErr && length > 0 {
                    let key = String(utf16CodeUnits: chars, count: length).uppercased()
                    if !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return key
                    }
                }
            }
            return "Key #\(keyCode)"
        }
    }

    /// Returns the modifier badge symbols in standard macOS display order (⌘, ⇧, ⌥, ⌃).
    public static func modifierBadges(for modifiers: UInt32) -> [String] {
        var badges: [String] = []
        if (modifiers & UInt32(cmdKey)) != 0 { badges.append("⌘") }
        if (modifiers & UInt32(shiftKey)) != 0 { badges.append("⇧") }
        if (modifiers & UInt32(optionKey)) != 0 { badges.append("⌥") }
        if (modifiers & UInt32(controlKey)) != 0 { badges.append("⌃") }
        return badges
    }

    /// Returns the full formatted display string (e.g. "⌘⇧G", "⌥Space").
    public static func displayString(keyCode: UInt16, modifiers: UInt32) -> String {
        let mods = modifierBadges(for: modifiers).joined()
        let key = keyString(for: keyCode)
        return "\(mods)\(key)"
    }
    
    /// Converts NSEvent.ModifierFlags to Carbon modifier flags.
    public static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
        if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
        return carbonMods
    }
}
