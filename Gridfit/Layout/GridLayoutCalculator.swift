//
//  GridLayoutCalculator.swift
//  Gridfit
//

import Foundation
import CoreGraphics

/// Calculates the optimal grid layout for arranging N windows on a given screen area.
public final class GridLayoutCalculator {
    public static let shared = GridLayoutCalculator()

    public init() {}

    /// Calculates the optimal grid layout for the given number of windows and screen rectangle.
    /// - Parameters:
    ///   - windowCount: The number of windows to arrange.
    ///   - screenRect: The usable screen rectangle (e.g. visibleFrame).
    ///   - screenPadding: Edge padding in points.
    ///   - horizontalSpacing: Spacing between columns in points.
    ///   - verticalSpacing: Spacing between rows in points.
    ///   - considerAspectRatio: Whether to prioritize golden/natural window aspect ratios.
    /// - Returns: The calculated optimal `GridLayout`.
    public func calculate(
        windowCount: Int,
        screenRect: CGRect,
        screenPadding: CGFloat = 8,
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        considerAspectRatio: Bool = true
    ) -> GridLayout {
        guard windowCount > 1 else {
            return GridLayout(columns: 1, rows: 1)
        }

        let screenWidth = max(100, screenRect.width)
        let screenHeight = max(100, screenRect.height)
        let isLandscape = screenWidth >= screenHeight

        // Target aspect ratio for ideal window usability (width / height)
        // Typical desktop apps are comfortable around 1.33 (4:3) ~ 1.5
        let targetAspectRatio: Double = isLandscape ? 1.35 : 1.10

        var bestLayout = GridLayout(columns: windowCount, rows: 1)
        var lowestCost = Double.greatestFiniteMagnitude

        // Evaluate reasonable candidate column counts
        let maxCols = min(windowCount, isLandscape ? 8 : 4)
        for cols in 1...maxCols {
            let rows = Int(ceil(Double(windowCount) / Double(cols)))
            guard rows >= 1 else { continue }

            let totalCells = cols * rows
            let emptyCells = totalCells - windowCount

            // Calculate cell width and height
            let totalHorizontalGaps = (screenPadding * 2) + (CGFloat(cols - 1) * horizontalSpacing)
            let totalVerticalGaps = (screenPadding * 2) + (CGFloat(rows - 1) * verticalSpacing)

            let cellWidth = max(10, (screenWidth - totalHorizontalGaps) / CGFloat(cols))
            let cellHeight = max(10, (screenHeight - totalVerticalGaps) / CGFloat(rows))

            let cellAspectRatio = Double(cellWidth / cellHeight)

            // Cost components:
            // 1. Aspect ratio penalty: measure logarithmic deviation from target ratio
            let ratioDeviation: Double
            if considerAspectRatio {
                let logDiff = log(max(0.01, cellAspectRatio) / targetAspectRatio)
                ratioDeviation = logDiff * logDiff
            } else {
                ratioDeviation = 0
            }

            // 2. Empty cell penalty: minimize wasted slots in the grid
            let emptyCellCost = Double(emptyCells) * 0.40

            // 3. Imbalance penalty: heavily penalize single-column on wide screens or single-row on tall screens
            var orientationMismatchCost = 0.0
            if isLandscape && cols == 1 && windowCount >= 2 {
                orientationMismatchCost += 3.0 // Stacking all windows vertically on wide screen is terrible
            }
            if !isLandscape && rows == 1 && windowCount >= 2 {
                orientationMismatchCost += 3.0 // Stacking all windows horizontally on tall screen is terrible
            }

            // 4. Realistic cell dimension penalty to prevent windows hitting app minimum size limits
            var dimensionPenalty = 0.0
            if cellWidth < 350 { dimensionPenalty += 3.0 }
            if cellWidth < 260 { dimensionPenalty += 8.0 }
            if cellHeight < 220 { dimensionPenalty += 3.0 }
            if cellHeight < 140 { dimensionPenalty += 8.0 }

            let totalCost = ratioDeviation + emptyCellCost + orientationMismatchCost + dimensionPenalty

            if totalCost < lowestCost {
                lowestCost = totalCost
                bestLayout = GridLayout(columns: cols, rows: rows)
            }
        }

        return bestLayout
    }
}
