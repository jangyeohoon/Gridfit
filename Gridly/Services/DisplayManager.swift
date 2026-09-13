//
//  DisplayManager.swift
//  Gridify
//

import AppKit
import CoreGraphics

/// Handles display enumeration, screen bounds calculation, and coordinate space conversions
/// between Cocoa (bottom-left origin) and Accessibility API (top-left origin).
public final class DisplayManager {
    public static let shared = DisplayManager()

    public init() {}

    /// Returns the primary screen (which defines the global coordinate origin in macOS).
    public var primaryScreen: NSScreen? {
        return NSScreen.screens.first
    }

    /// Returns the height of the primary screen, used for vertical coordinate inversion.
    public var primaryScreenHeight: CGFloat {
        return primaryScreen?.frame.height ?? 1080.0
    }

    /// Converts a CGRect from Cocoa coordinates (bottom-left origin) to Accessibility coordinates (top-left origin).
    public func cocoaToAX(rect: CGRect) -> CGRect {
        let axY = primaryScreenHeight - (rect.origin.y + rect.height)
        return CGRect(x: rect.origin.x, y: axY, width: rect.width, height: rect.height)
    }

    /// Returns the usable bounds (visibleFrame, accounting for Dock and Menu Bar) of a screen in AX coordinates.
    public func usableBoundsAX(for screen: NSScreen) -> CGRect {
        return cocoaToAX(rect: screen.visibleFrame)
    }

    /// Returns the full frame of a screen in AX coordinates.
    public func frameAX(for screen: NSScreen) -> CGRect {
        return cocoaToAX(rect: screen.frame)
    }

    /// Determines which screen a window belongs to based on its frame (in AX coordinates).
    /// Uses center-point containment first, falling back to maximum intersection area.
    public func screen(forWindowFrameAX frame: CGRect) -> NSScreen {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return NSScreen.main ?? NSScreen()
        }

        let center = CGPoint(x: frame.midX, y: frame.midY)

        // 1. Try center-point containment
        for screen in screens {
            let screenAX = frameAX(for: screen)
            if screenAX.contains(center) {
                return screen
            }
        }

        // 2. Fall back to maximum intersection area
        var bestScreen = screens[0]
        var maxArea: CGFloat = 0.0

        for screen in screens {
            let screenAX = frameAX(for: screen)
            let intersection = screenAX.intersection(frame)
            if !intersection.isNull {
                let area = intersection.width * intersection.height
                if area > maxArea {
                    maxArea = area
                    bestScreen = screen
                }
            }
        }

        return bestScreen
    }

    /// Returns the active screen where the user is currently working (based on mouse cursor location).
    /// Falls back to the main screen or first available screen.
    public func activeScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        if let screenUnderCursor = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screenUnderCursor
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
}
