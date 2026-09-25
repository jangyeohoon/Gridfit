//
//  WindowSnapAction.swift
//  Gridfit
//

import AppKit
import CoreGraphics

/// Defines single-window snapping actions for quick layout arrangement.
public enum WindowSnapAction: String, CaseIterable, Identifiable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case maximize = "Maximize"
    case center = "Center"
    case nextDisplay = "Next Display"

    public var id: String { rawValue }

    /// SF Symbol icon name corresponding to the snap action.
    public var iconName: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .maximize: return "arrow.up.left.and.arrow.down.right"
        case .center: return "plus.viewfinder"
        case .nextDisplay: return "display.2"
        }
    }

    /// Computes the target frame in Accessibility coordinates (top-left origin)
    /// based on the usable screen bounds and configured paddings.
    public func calculateFrame(
        in usableBounds: CGRect,
        currentFrame: CGRect,
        screenPadding: CGFloat = 8.0,
        horizontalSpacing: CGFloat = 8.0,
        verticalSpacing: CGFloat = 8.0
    ) -> CGRect {
        let padX = screenPadding
        let padY = screenPadding
        let totalW = max(100.0, usableBounds.width - (padX * 2))
        let totalH = max(100.0, usableBounds.height - (padY * 2))

        switch self {
        case .leftHalf:
            let w = floor((totalW - horizontalSpacing) / 2.0)
            let x = usableBounds.minX + padX
            let y = usableBounds.minY + padY
            return CGRect(x: x, y: y, width: w, height: totalH)

        case .rightHalf:
            let w = floor((totalW - horizontalSpacing) / 2.0)
            let x = usableBounds.minX + padX + w + horizontalSpacing
            let y = usableBounds.minY + padY
            return CGRect(x: x, y: y, width: w, height: totalH)

        case .topHalf:
            let h = floor((totalH - verticalSpacing) / 2.0)
            let x = usableBounds.minX + padX
            let y = usableBounds.minY + padY
            return CGRect(x: x, y: y, width: totalW, height: h)

        case .bottomHalf:
            let h = floor((totalH - verticalSpacing) / 2.0)
            let x = usableBounds.minX + padX
            let y = usableBounds.minY + padY + h + verticalSpacing
            return CGRect(x: x, y: y, width: totalW, height: h)

        case .maximize:
            let x = usableBounds.minX + padX
            let y = usableBounds.minY + padY
            return CGRect(x: x, y: y, width: totalW, height: totalH)

        case .center:
            let targetW = min(currentFrame.width, totalW)
            let targetH = min(currentFrame.height, totalH)
            let x = usableBounds.minX + (usableBounds.width - targetW) / 2.0
            let y = usableBounds.minY + (usableBounds.height - targetH) / 2.0
            return CGRect(x: x, y: y, width: targetW, height: targetH)

        case .nextDisplay:
            // Handled separately by multi-display migration logic
            return currentFrame
        }
    }
}
