//
//  GridLayout.swift
//  Gridly
//

import Foundation
import CoreGraphics

/// Defines a grid with a specific number of columns and rows.
public struct GridLayout: Equatable, Hashable {
    public let columns: Int
    public let rows: Int

    public var totalCells: Int {
        return columns * rows
    }

    public init(columns: Int, rows: Int) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
    }

    /// Calculates the specific frame for a cell at (column, row) inside the given screen bounds,
    /// taking padding and spacing into account.
    /// Note: `bounds` can be either in NSScreen or AX coordinates. Cell rect is computed consistently.
    public func cellRect(
        col: Int,
        row: Int,
        in bounds: CGRect,
        screenPadding: CGFloat = 8,
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8
    ) -> CGRect {
        let usableWidth = bounds.width - (screenPadding * 2) - (CGFloat(columns - 1) * horizontalSpacing)
        let usableHeight = bounds.height - (screenPadding * 2) - (CGFloat(rows - 1) * verticalSpacing)

        let cellWidth = max(50, usableWidth / CGFloat(columns))
        let cellHeight = max(50, usableHeight / CGFloat(rows))

        let originX = bounds.minX + screenPadding + CGFloat(col) * (cellWidth + horizontalSpacing)
        let originY = bounds.minY + screenPadding + CGFloat(row) * (cellHeight + verticalSpacing)

        return CGRect(x: originX, y: originY, width: cellWidth, height: cellHeight)
    }
}
