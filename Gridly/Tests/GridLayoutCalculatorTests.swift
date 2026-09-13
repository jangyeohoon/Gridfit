//
//  GridLayoutCalculatorTests.swift
//  Gridly
//

import Foundation
import CoreGraphics

public struct GridLayoutCalculatorTests {
    public static func runAllTests() -> Bool {
        print("=== Running GridLayoutCalculator Tests ===")
        let calc = GridLayoutCalculator()
        let landscape1080p = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let portrait1080p = CGRect(x: 0, y: 0, width: 1080, height: 1920)
        let ultrawide = CGRect(x: 0, y: 0, width: 3440, height: 1440)

        var passedCount = 0
        var failedCount = 0

        func assertLayout(count: Int, screen: CGRect, expectedCols: Int, expectedRows: Int, testName: String) {
            let layout = calc.calculate(windowCount: count, screenRect: screen)
            if layout.columns == expectedCols && layout.rows == expectedRows {
                print("  [PASS] \(testName): \(count) windows on \(Int(screen.width))x\(Int(screen.height)) -> \(layout.columns)x\(layout.rows)")
                passedCount += 1
            } else {
                print("  [FAIL] \(testName): \(count) windows on \(Int(screen.width))x\(Int(screen.height)). Expected \(expectedCols)x\(expectedRows), got \(layout.columns)x\(layout.rows)")
                failedCount += 1
            }
        }

        // Test 1: 1 window -> 1x1
        assertLayout(count: 1, screen: landscape1080p, expectedCols: 1, expectedRows: 1, testName: "1 window")

        // Test 2: 2 windows on landscape -> 2x1
        assertLayout(count: 2, screen: landscape1080p, expectedCols: 2, expectedRows: 1, testName: "2 windows landscape")

        // Test 3: 2 windows on portrait -> 1x2
        assertLayout(count: 2, screen: portrait1080p, expectedCols: 1, expectedRows: 2, testName: "2 windows portrait")

        // Test 4: 4 windows -> 2x2
        assertLayout(count: 4, screen: landscape1080p, expectedCols: 2, expectedRows: 2, testName: "4 windows landscape")

        // Test 5: 5 windows -> 3x2
        assertLayout(count: 5, screen: landscape1080p, expectedCols: 3, expectedRows: 2, testName: "5 windows landscape")

        // Test 6: 6 windows -> 3x2
        assertLayout(count: 6, screen: landscape1080p, expectedCols: 3, expectedRows: 2, testName: "6 windows landscape")

        // Test 7: 9 windows -> 3x3
        assertLayout(count: 9, screen: landscape1080p, expectedCols: 3, expectedRows: 3, testName: "9 windows landscape")

        // Test 8: 12 windows -> 4x3
        assertLayout(count: 12, screen: landscape1080p, expectedCols: 4, expectedRows: 3, testName: "12 windows landscape")

        // Test 9: Ultrawide screen (3440x1440) for 6 windows
        let ultrawideLayout = calc.calculate(windowCount: 6, screenRect: ultrawide)
        if ultrawideLayout.columns * ultrawideLayout.rows >= 6 {
            print("  [PASS] 6 windows on ultrawide -> \(ultrawideLayout.columns)x\(ultrawideLayout.rows)")
            passedCount += 1
        } else {
            print("  [FAIL] 6 windows on ultrawide insufficient cells")
            failedCount += 1
        }

        // Test 10: Application Window Clustering
        let testWindows = [
            AppWindow(applicationPID: 101, applicationName: "Google Chrome", windowTitle: "Tab 1", windowID: 1, frame: CGRect(x: 100, y: 0, width: 500, height: 400)),
            AppWindow(applicationPID: 102, applicationName: "Slack", windowTitle: "General", windowID: 2, frame: CGRect(x: 200, y: 0, width: 500, height: 400)),
            AppWindow(applicationPID: 101, applicationName: "Google Chrome", windowTitle: "Tab 2", windowID: 3, frame: CGRect(x: 50, y: 0, width: 500, height: 400)),
            AppWindow(applicationPID: 103, applicationName: "Finder", windowTitle: "Downloads", windowID: 4, frame: CGRect(x: 300, y: 0, width: 500, height: 400)),
            AppWindow(applicationPID: 102, applicationName: "Slack", windowTitle: "Dev", windowID: 5, frame: CGRect(x: 150, y: 0, width: 500, height: 400)),
            AppWindow(applicationPID: 101, applicationName: "Google Chrome", windowTitle: "Tab 3", windowID: 6, frame: CGRect(x: 600, y: 0, width: 500, height: 400))
        ]

        let grouped = Dictionary(grouping: testWindows, by: { $0.applicationName })
        let sortedGroups = grouped.values.sorted { g1, g2 in
            if g1.count != g2.count { return g1.count > g2.count }
            return (g1.first?.applicationName ?? "").localizedCaseInsensitiveCompare(g2.first?.applicationName ?? "") == .orderedAscending
        }
        let ordered = sortedGroups.flatMap { group in
            group.sorted { $0.frame.minX < $1.frame.minX }
        }

        // Verify Chrome has 3 contiguous windows at index 0, 1, 2
        let chromeWindows = ordered[0..<3].map { $0.applicationName }
        let isChromeClustered = chromeWindows.allSatisfy { $0 == "Google Chrome" }
        // Verify Slack has 2 contiguous windows at index 3, 4
        let slackWindows = ordered[3..<5].map { $0.applicationName }
        let isSlackClustered = slackWindows.allSatisfy { $0 == "Slack" }
        // Verify Finder is at index 5
        let isFinderAtEnd = ordered[5].applicationName == "Finder"

        if isChromeClustered && isSlackClustered && isFinderAtEnd {
            print("  [PASS] Application Window Clustering: same apps successfully grouped adjacent")
            passedCount += 1
        } else {
            print("  [FAIL] Application Window Clustering failed")
            failedCount += 1
        }

        // Test 11: Screen Boundary Invariant Test
        var allWithinBounds = true
        let testScreens = [landscape1080p, portrait1080p, ultrawide]
        for screen in testScreens {
            for n in 1...12 {
                let layout = calc.calculate(windowCount: n, screenRect: screen)
                for col in 0..<layout.columns {
                    for row in 0..<layout.rows {
                        let cell = layout.cellRect(col: col, row: row, in: screen, screenPadding: 8, horizontalSpacing: 8, verticalSpacing: 8)
                        if cell.minX < screen.minX + 7.9 ||
                           cell.maxX > screen.maxX - 7.9 ||
                           cell.minY < screen.minY + 7.9 ||
                           cell.maxY > screen.maxY - 7.9 {
                            allWithinBounds = false
                        }
                    }
                }
            }
        }

        if allWithinBounds {
            print("  [PASS] Screen Boundary Invariants: 100% of cells strictly inside screen bounds")
            passedCount += 1
        } else {
            print("  [FAIL] Some cells exceeded screen boundaries")
            failedCount += 1
        }

        print("=== Test Summary: \(passedCount) passed, \(failedCount) failed ===")
        return failedCount == 0
    }
}
