//
//  WindowSnapActionTests.swift
//  Gridfit
//

import Foundation
import CoreGraphics

public struct WindowSnapActionTests {
    public static func runAllTests() -> Bool {
        print("=== Running WindowSnapAction Tests ===")
        var passed = 0
        var failed = 0

        func assertCondition(_ condition: Bool, _ testName: String) {
            if condition {
                print("  [PASS] \(testName)")
                passed += 1
            } else {
                print("  [FAIL] \(testName)")
                failed += 1
            }
        }

        func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ testName: String) {
            if actual == expected {
                print("  [PASS] \(testName)")
                passed += 1
            } else {
                print("  [FAIL] \(testName): Expected \(expected), got \(actual)")
                failed += 1
            }
        }

        let usableBounds = CGRect(x: 0, y: 25, width: 1920, height: 1055)
        let pad: CGFloat = 8.0
        let spacing: CGFloat = 8.0
        let currentFrame = CGRect(x: 200, y: 200, width: 800, height: 600)

        // Test 1: Left Half
        let leftRect = WindowSnapAction.leftHalf.calculateFrame(
            in: usableBounds,
            currentFrame: currentFrame,
            screenPadding: pad,
            horizontalSpacing: spacing,
            verticalSpacing: spacing
        )
        let expectedLeftW = floor(((1920.0 - (pad * 2)) - spacing) / 2.0)
        let expectedH = 1055.0 - (pad * 2)
        assertEqual(leftRect.origin.x, usableBounds.minX + pad, "Left Half Origin X")
        assertEqual(leftRect.origin.y, usableBounds.minY + pad, "Left Half Origin Y")
        assertEqual(leftRect.width, expectedLeftW, "Left Half Width")
        assertEqual(leftRect.height, expectedH, "Left Half Height")

        // Test 2: Right Half
        let rightRect = WindowSnapAction.rightHalf.calculateFrame(
            in: usableBounds,
            currentFrame: currentFrame,
            screenPadding: pad,
            horizontalSpacing: spacing,
            verticalSpacing: spacing
        )
        assertEqual(rightRect.origin.x, usableBounds.minX + pad + expectedLeftW + spacing, "Right Half Origin X")
        assertEqual(rightRect.width, expectedLeftW, "Right Half Width")
        assertEqual(rightRect.height, expectedH, "Right Half Height")

        // Test 3: Left + Spacing + Right fills the screen exactly (ignoring 1pt flooring tolerance)
        let totalSpan = (rightRect.maxX - leftRect.minX) + pad * 2
        assertCondition(abs(totalSpan - usableBounds.width) <= 2.0, "Left and Right halves span screen width")

        // Test 4: Top Half
        let topRect = WindowSnapAction.topHalf.calculateFrame(
            in: usableBounds,
            currentFrame: currentFrame,
            screenPadding: pad,
            horizontalSpacing: spacing,
            verticalSpacing: spacing
        )
        let expectedTopH = floor(((1055.0 - (pad * 2)) - spacing) / 2.0)
        let expectedW = 1920.0 - (pad * 2)
        assertEqual(topRect.origin.x, usableBounds.minX + pad, "Top Half Origin X")
        assertEqual(topRect.origin.y, usableBounds.minY + pad, "Top Half Origin Y")
        assertEqual(topRect.width, expectedW, "Top Half Width")
        assertEqual(topRect.height, expectedTopH, "Top Half Height")

        // Test 5: Bottom Half
        let bottomRect = WindowSnapAction.bottomHalf.calculateFrame(
            in: usableBounds,
            currentFrame: currentFrame,
            screenPadding: pad,
            horizontalSpacing: spacing,
            verticalSpacing: spacing
        )
        assertEqual(bottomRect.origin.y, usableBounds.minY + pad + expectedTopH + spacing, "Bottom Half Origin Y")
        assertEqual(bottomRect.width, expectedW, "Bottom Half Width")
        assertEqual(bottomRect.height, expectedTopH, "Bottom Half Height")

        // Test 6: Maximize
        let maxRect = WindowSnapAction.maximize.calculateFrame(
            in: usableBounds,
            currentFrame: currentFrame,
            screenPadding: pad,
            horizontalSpacing: spacing,
            verticalSpacing: spacing
        )
        assertEqual(maxRect.origin.x, usableBounds.minX + pad, "Maximize Origin X")
        assertEqual(maxRect.origin.y, usableBounds.minY + pad, "Maximize Origin Y")
        assertEqual(maxRect.width, expectedW, "Maximize Width")
        assertEqual(maxRect.height, expectedH, "Maximize Height")

        // Test 7: Center
        let centerRect = WindowSnapAction.center.calculateFrame(
            in: usableBounds,
            currentFrame: currentFrame,
            screenPadding: pad,
            horizontalSpacing: spacing,
            verticalSpacing: spacing
        )
        assertEqual(centerRect.width, currentFrame.width, "Center retains width")
        assertEqual(centerRect.height, currentFrame.height, "Center retains height")
        assertEqual(centerRect.origin.x, usableBounds.minX + (usableBounds.width - currentFrame.width) / 2.0, "Center Origin X")
        assertEqual(centerRect.origin.y, usableBounds.minY + (usableBounds.height - currentFrame.height) / 2.0, "Center Origin Y")

        print("=== WindowSnapAction Summary: \(passed) passed, \(failed) failed ===\n")
        return failed == 0
    }
}
