//
//  ShortcutFormatterTests.swift
//  Gridify
//

import Carbon
import AppKit

public final class ShortcutFormatterTests {
    public static func runAllTests() -> Bool {
        print("=== Running ShortcutFormatter Tests ===")
        var passed = 0
        var failed = 0

        func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
            if actual == expected {
                passed += 1
                print("  [PASS] \(message)")
            } else {
                failed += 1
                print("  [FAIL] \(message) - Expected '\(expected)', got '\(actual)'")
            }
        }

        // Test 1: Default ⌘⇧G formatting
        let defaultStr = ShortcutFormatter.displayString(keyCode: UInt16(kVK_ANSI_G), modifiers: UInt32(cmdKey | shiftKey))
        assertEqual(defaultStr, "⌘⇧G", "Default shortcut displays as ⌘⇧G")

        // Test 2: Modifier badges order
        let badges = ShortcutFormatter.modifierBadges(for: UInt32(cmdKey | shiftKey | optionKey | controlKey))
        assertEqual(badges, ["⌘", "⇧", "⌥", "⌃"], "All modifiers displayed in standard badge order")

        // Test 3: Special key Space
        let spaceStr = ShortcutFormatter.displayString(keyCode: UInt16(kVK_Space), modifiers: UInt32(optionKey))
        assertEqual(spaceStr, "⌥Space", "Option+Space displays correctly")

        // Test 4: Arrow keys
        let leftStr = ShortcutFormatter.keyString(for: UInt16(kVK_LeftArrow))
        assertEqual(leftStr, "←", "Left arrow displays as ←")

        // Test 5: Function keys
        let f1Str = ShortcutFormatter.keyString(for: UInt16(kVK_F1))
        assertEqual(f1Str, "F1", "F1 displays as F1")

        // Test 6: Carbon modifier conversion
        let carbon = ShortcutFormatter.carbonModifiers(from: [.command, .option])
        assertEqual(carbon, UInt32(cmdKey | optionKey), "NSEvent modifier conversion matches Carbon flags")

        print("=== ShortcutFormatter Summary: \(passed) passed, \(failed) failed ===\n")
        return failed == 0
    }
}
