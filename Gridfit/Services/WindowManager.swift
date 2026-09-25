//
//  WindowManager.swift
//  Gridfit
//

import AppKit
import ApplicationServices
import Combine
import os

/// Discovers, filters, arranges, and restores application windows across displays.
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()

    @Published public private(set) var lastArrangementSnapshot: ArrangementSnapshot?
    @Published public private(set) var lastResultSummary: String?
    private var isArranging: Bool = false

    public var canUndo: Bool {
        return lastArrangementSnapshot != nil
    }

    private let settings = UserSettings.shared
    private let displayManager = DisplayManager.shared
    private let layoutCalculator = GridLayoutCalculator.shared
    private var screenChangeObserver: NSObjectProtocol?

    private init() {
        setupScreenChangeObserver()
    }

    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupScreenChangeObserver() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.settings.autoArrangeOnDisplayChange {
                // Debounce slightly to allow macOS window server to finish reconfiguration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.arrangeAllWindows()
                }
            }
        }
    }

    // MARK: - Window Discovery

    /// Scans for all valid, visible, non-minimized GUI windows currently open on macOS.
    /// If targetScreen is provided, only windows belonging to that screen are returned.
    public func findManageableWindows(targetScreen: NSScreen? = nil) -> [AppWindow] {
        var result: [AppWindow] = []
        let ownPID = NSRunningApplication.current.processIdentifier

        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular &&
            $0.processIdentifier != ownPID &&
            (!$0.isHidden || !settings.excludeMinimizedWindows) &&
            !settings.isExcluded(bundleID: $0.bundleIdentifier)
        }

        for app in runningApps {
            let pid = app.processIdentifier
            let appName = app.localizedName ?? "Unknown App"
            let appElement = AXUIElementCreateApplication(pid)

            var windowsRef: AnyObject?
            let axError = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

            guard axError == .success, let axWindows = windowsRef as? [AXUIElement] else {
                continue
            }

            for axWindow in axWindows {
                guard isValidManageableWindow(axWindow) else {
                    continue
                }

                // Window Title
                var titleRef: AnyObject?
                _ = AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
                let title = (titleRef as? String) ?? ""

                // Get Current Frame in AX Coordinates
                guard let frame = getWindowFrame(axWindow) else {
                    continue
                }

                // Exclude fullscreen background overlays (e.g. Finder Desktop with empty title)
                if app.bundleIdentifier == "com.apple.finder" && title.isEmpty {
                    continue
                }

                // Minimum size filter
                if frame.width < CGFloat(settings.minWindowWidth) || frame.height < CGFloat(settings.minWindowHeight) {
                    continue
                }

                // Target screen filter (if specified)
                if let target = targetScreen {
                    let winScreen = displayManager.screen(forWindowFrameAX: frame)
                    if winScreen != target {
                        continue
                    }
                }

                let window = AppWindow(
                    applicationPID: pid,
                    applicationName: appName,
                    windowTitle: title,
                    windowID: nil,
                    frame: frame,
                    axElement: axWindow
                )

                result.append(window)
            }
        }

        return result
    }

    /// Verifies if a given AXUIElement window qualifies for arrangement.
    private func isValidManageableWindow(_ axWindow: AXUIElement) -> Bool {
        // 1. Role check: Must strictly be an AXWindow (filters out Finder Desktop AXScrollArea, status bars, menus)
        var roleRef: AnyObject?
        guard AXUIElementCopyAttributeValue(axWindow, kAXRoleAttribute as CFString, &roleRef) == .success,
              let role = roleRef as? String,
              role == (kAXWindowRole as String) else {
            return false
        }

        // 2. Settability check: Both Size and Position must be settable by Accessibility API
        var isSizeSettable: DarwinBoolean = false
        var isPosSettable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(axWindow, kAXSizeAttribute as CFString, &isSizeSettable)
        AXUIElementIsAttributeSettable(axWindow, kAXPositionAttribute as CFString, &isPosSettable)
        guard isSizeSettable.boolValue && isPosSettable.boolValue else {
            return false
        }

        // 3. Subrole check: standard windows only (ignore toolbars, status items, popups, palettes)
        var subroleRef: AnyObject?
        let subroleError = AXUIElementCopyAttributeValue(axWindow, kAXSubroleAttribute as CFString, &subroleRef)
        if subroleError == .success, let subrole = subroleRef as? String {
            let excludedSubroles = [
                "AXSystemDialog",
                "AXSheet",
                "AXDrawer",
                "AXFloatingWindow",
                "AXSystemFloatingWindow"
            ]
            if excludedSubroles.contains(subrole) {
                return false
            }
        }

        // 4. Minimized check
        if settings.excludeMinimizedWindows {
            var minimizedRef: AnyObject?
            let minError = AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minimizedRef)
            if minError == .success, let isMinimized = minimizedRef as? Bool, isMinimized {
                return false
            }
        }

        // 5. Full screen check
        if settings.excludeFullScreenWindows {
            var fullScreenRef: AnyObject?
            let fsError = AXUIElementCopyAttributeValue(axWindow, "AXFullScreen" as CFString, &fullScreenRef)
            if fsError == .success, let isFullScreen = fullScreenRef as? Bool, isFullScreen {
                return false
            }
        }

        return true
    }

    // MARK: - Frame Retrieval and Application

    /// Gets the current frame of an AXUIElement window in AX coordinates safely.
    private func getWindowFrame(_ axWindow: AXUIElement) -> CGRect? {
        var posRef: AnyObject?
        var sizeRef: AnyObject?

        guard AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posVal = posRef, CFGetTypeID(posVal) == AXValueGetTypeID(),
              let sizeVal = sizeRef, CFGetTypeID(sizeVal) == AXValueGetTypeID() else {
            return nil
        }

        let posAX = posVal as! AXValue
        let sizeAX = sizeVal as! AXValue

        var origin = CGPoint.zero
        var size = CGSize.zero

        guard AXValueGetValue(posAX, .cgPoint, &origin),
              AXValueGetValue(sizeAX, .cgSize, &size) else {
            return nil
        }

        return CGRect(origin: origin, size: size)
    }

    /// Sets the frame of an AXUIElement window in AX coordinates.
    @discardableResult
    private func setWindowFrame(_ axWindow: AXUIElement, to targetRect: CGRect) -> Bool {
        var origin = targetRect.origin
        var size = targetRect.size

        // Step 1: Set size first so repositioning won't clamp against screen borders
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeValue)
        }

        // Step 2: Set position
        var posSuccess = false
        if let posValue = AXValueCreate(.cgPoint, &origin) {
            let err = AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, posValue)
            posSuccess = (err == .success)
        }

        // Step 3: Re-apply size in case original bounds forced constraint
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            _ = AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeValue)
        }

        // Step 4: Re-apply position in case size adjustment shifted coordinates
        if let posValue = AXValueCreate(.cgPoint, &origin) {
            let err = AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, posValue)
            if err == .success {
                posSuccess = true
            }
        }

        return posSuccess
    }

    // MARK: - Feedback & Audio

    /// Plays a subtle system feedback sound when enabled in settings.
    public func triggerFeedbackSound() {
        guard settings.playFeedbackSound else { return }
        DispatchQueue.main.async {
            NSSound(named: "Tink")?.play()
        }
    }

    // MARK: - Active Window Snapping

    /// Retrieves the currently focused/active window on macOS.
    public func getActiveFocusedWindow() -> (AppWindow, AXUIElement)? {
        let ownPID = NSRunningApplication.current.processIdentifier

        // 1. Identify the active application (excluding Gridfit itself)
        var targetApp = NSWorkspace.shared.frontmostApplication
        if targetApp == nil || targetApp?.processIdentifier == ownPID {
            targetApp = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && $0.processIdentifier != ownPID && $0.isActive }
                .first ?? NSWorkspace.shared.runningApplications.first(where: { $0.activationPolicy == .regular && $0.processIdentifier != ownPID })
        }

        guard let app = targetApp else { return nil }
        let pid = app.processIdentifier
        let appName = app.localizedName ?? "Active App"
        let appElement = AXUIElementCreateApplication(pid)

        // 2. Try to get the focused window
        var focusedWindowRef: AnyObject?
        var status = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef)

        if status != .success || focusedWindowRef == nil {
            status = AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &focusedWindowRef)
        }

        if status != .success || focusedWindowRef == nil {
            var windowsRef: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
               let axWindows = windowsRef as? [AXUIElement] {
                for axWin in axWindows {
                    if isValidManageableWindow(axWin), let frame = getWindowFrame(axWin) {
                        let win = AppWindow(
                            applicationPID: pid,
                            applicationName: appName,
                            windowTitle: getWindowTitle(axWin),
                            windowID: nil,
                            frame: frame,
                            axElement: axWin
                        )
                        return (win, axWin)
                    }
                }
            }
            return nil
        }

        guard let focusedRef = focusedWindowRef,
              CFGetTypeID(focusedRef) == AXUIElementGetTypeID() else {
            return nil
        }
        let axWindow = focusedRef as! AXUIElement
        guard isValidManageableWindow(axWindow),
              let frame = getWindowFrame(axWindow) else {
            return nil
        }

        let win = AppWindow(
            applicationPID: pid,
            applicationName: appName,
            windowTitle: getWindowTitle(axWindow),
            windowID: nil,
            frame: frame,
            axElement: axWindow
        )
        return (win, axWindow)
    }

    private func getWindowTitle(_ axWindow: AXUIElement) -> String {
        var titleRef: AnyObject?
        _ = AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
        return (titleRef as? String) ?? ""
    }

    /// Snaps the currently active window according to the specified snap action.
    public func snapActiveWindow(to action: WindowSnapAction) {
        if action == .nextDisplay {
            moveActiveWindowToNextDisplay()
            return
        }

        guard let (appWindow, axElement) = getActiveFocusedWindow() else {
            DispatchQueue.main.async {
                self.lastResultSummary = "No active window found to snap"
            }
            return
        }

        // Save pre-snap snapshot for Undo
        let snapshot = WindowFrameSnapshot(window: appWindow, frame: appWindow.frame)
        DispatchQueue.main.async {
            self.lastArrangementSnapshot = ArrangementSnapshot(snapshots: [snapshot])
        }

        let screen = displayManager.screen(forWindowFrameAX: appWindow.frame)
        let usableBounds = displayManager.usableBoundsAX(for: screen)

        let targetRect = action.calculateFrame(
            in: usableBounds,
            currentFrame: appWindow.frame,
            screenPadding: CGFloat(settings.screenPadding),
            horizontalSpacing: CGFloat(settings.horizontalSpacing),
            verticalSpacing: CGFloat(settings.verticalSpacing)
        )

        let success = setWindowFrame(axElement, to: targetRect)
        raiseWindow(axElement)

        if success {
            triggerFeedbackSound()
            DispatchQueue.main.async {
                let summary = "Snapped \(appWindow.applicationName) to \(action.rawValue)"
                self.lastResultSummary = summary
                AppLogger.windowManager.info("\(summary)")
            }
        }
    }

    /// Moves the active window to the next connected display while maintaining relative proportions.
    public func moveActiveWindowToNextDisplay() {
        guard let (appWindow, axElement) = getActiveFocusedWindow() else {
            DispatchQueue.main.async {
                self.lastResultSummary = "No active window found to move"
            }
            return
        }

        let screens = NSScreen.screens
        guard screens.count > 1 else {
            DispatchQueue.main.async {
                self.lastResultSummary = "Only 1 display connected"
            }
            return
        }

        let currentScreen = displayManager.screen(forWindowFrameAX: appWindow.frame)
        guard let currentIndex = screens.firstIndex(of: currentScreen) else { return }

        let nextIndex = (currentIndex + 1) % screens.count
        let targetScreen = screens[nextIndex]

        // Save snapshot for Undo
        let snapshot = WindowFrameSnapshot(window: appWindow, frame: appWindow.frame)
        DispatchQueue.main.async {
            self.lastArrangementSnapshot = ArrangementSnapshot(snapshots: [snapshot])
        }

        let currentUsable = displayManager.usableBoundsAX(for: currentScreen)
        let targetUsable = displayManager.usableBoundsAX(for: targetScreen)

        let relX = (appWindow.frame.origin.x - currentUsable.origin.x) / max(1.0, currentUsable.width)
        let relY = (appWindow.frame.origin.y - currentUsable.origin.y) / max(1.0, currentUsable.height)
        let relW = appWindow.frame.width / max(1.0, currentUsable.width)
        let relH = appWindow.frame.height / max(1.0, currentUsable.height)

        let screenPad = CGFloat(settings.screenPadding)
        let targetW = max(100.0, min(targetUsable.width - (screenPad * 2), targetUsable.width * relW))
        let targetH = max(100.0, min(targetUsable.height - (screenPad * 2), targetUsable.height * relH))

        var targetX = targetUsable.origin.x + (targetUsable.width * relX)
        var targetY = targetUsable.origin.y + (targetUsable.height * relY)

        // Clamp inside target usable bounds
        if targetX + targetW > targetUsable.maxX - screenPad {
            targetX = max(targetUsable.minX + screenPad, targetUsable.maxX - screenPad - targetW)
        }
        if targetX < targetUsable.minX + screenPad {
            targetX = targetUsable.minX + screenPad
        }
        if targetY + targetH > targetUsable.maxY - screenPad {
            targetY = max(targetUsable.minY + screenPad, targetUsable.maxY - screenPad - targetH)
        }
        if targetY < targetUsable.minY + screenPad {
            targetY = targetUsable.minY + screenPad
        }

        let targetRect = CGRect(x: targetX, y: targetY, width: targetW, height: targetH)
        let success = setWindowFrame(axElement, to: targetRect)
        raiseWindow(axElement)

        if success {
            triggerFeedbackSound()
            DispatchQueue.main.async {
                let summary = "Moved \(appWindow.applicationName) to next display"
                self.lastResultSummary = summary
                AppLogger.windowManager.info("\(summary)")
            }
        }
    }

    // MARK: - Arrangement & Tiling

    /// Arranges all manageable windows across all connected displays.
    public func arrangeAllWindows() {
        arrangeWindows(targetScreen: nil)
    }

    /// Arranges manageable windows strictly on the currently active display (where mouse cursor is located).
    public func arrangeActiveScreen() {
        let activeScreen = displayManager.activeScreen()
        arrangeWindows(targetScreen: activeScreen)
    }

    /// Internal arrangement pipeline. If targetScreen is non-nil, only windows on that display are arranged.
    private func arrangeWindows(targetScreen: NSScreen?) {
        guard !isArranging else { return }
        isArranging = true
        defer { isArranging = false }

        let windows = findManageableWindows(targetScreen: targetScreen)
        guard !windows.isEmpty else {
            DispatchQueue.main.async {
                self.lastResultSummary = "No manageable windows found"
            }
            return
        }

        // Save pre-arrangement frames for Undo
        var snapshots: [WindowFrameSnapshot] = []
        for win in windows {
            snapshots.append(WindowFrameSnapshot(window: win, frame: win.frame))
        }
        DispatchQueue.main.async {
            self.lastArrangementSnapshot = ArrangementSnapshot(snapshots: snapshots)
        }

        // Group windows by display
        var windowsByScreen: [NSScreen: [AppWindow]] = [:]
        for win in windows {
            let targetScreen = displayManager.screen(forWindowFrameAX: win.frame)
            windowsByScreen[targetScreen, default: []].append(win)
        }

        var totalSuccess = 0
        var totalFailed = 0

        for (screen, screenWindows) in windowsByScreen {
            let usableAXBounds = displayManager.usableBoundsAX(for: screen)
            let count = screenWindows.count

            // Determine layout
            let layout: GridLayout
            if let presetLayout = settings.layoutPreset.layout, presetLayout.totalCells >= count {
                layout = presetLayout
            } else {
                layout = layoutCalculator.calculate(
                    windowCount: count,
                    screenRect: usableAXBounds,
                    screenPadding: CGFloat(settings.screenPadding),
                    horizontalSpacing: CGFloat(settings.horizontalSpacing),
                    verticalSpacing: CGFloat(settings.verticalSpacing),
                    considerAspectRatio: settings.considerAspectRatio
                )
            }

            // Order windows: group windows by application so windows of the same app are clustered together
            let orderedWindows: [AppWindow]
            if settings.groupByApplication {
                let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
                let grouped = Dictionary(grouping: screenWindows, by: { $0.applicationName })

                let sortedGroups = grouped.values.sorted { g1, g2 in
                    let isFront1 = (g1.first?.applicationPID == frontmostPID)
                    let isFront2 = (g2.first?.applicationPID == frontmostPID)

                    // 1. Larger window clusters first to fill rows/blocks cleanly
                    if g1.count != g2.count {
                        return g1.count > g2.count
                    }
                    // 2. Active app prioritized if equal cluster size
                    if isFront1 != isFront2 {
                        return isFront1
                    }
                    // 3. Alphabetical tie-breaker for deterministic layout
                    let name1 = g1.first?.applicationName ?? ""
                    let name2 = g2.first?.applicationName ?? ""
                    return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
                }

                orderedWindows = sortedGroups.flatMap { group in
                    // Within each app group, sort by current horizontal position (left to right)
                    // so the user's existing spatial relationship is preserved
                    group.sorted { $0.frame.minX < $1.frame.minX }
                }
            } else {
                orderedWindows = screenWindows
            }

            // Partition windows into rows to balance each row and eliminate awkward gaps
            let rowGroups = partitionWindowsIntoRows(windows: orderedWindows, rows: layout.rows, columns: layout.columns)
            let actualRows = max(1, rowGroups.count)
            let totalVSpacing = CGFloat(actualRows - 1) * CGFloat(settings.verticalSpacing)
            let rowHeight = max(50, (usableAXBounds.height - (CGFloat(settings.screenPadding) * 2) - totalVSpacing) / CGFloat(actualRows))

            for (rowIndex, rowWindows) in rowGroups.enumerated() {
                let targetRowY = usableAXBounds.minY + CGFloat(settings.screenPadding) + CGFloat(rowIndex) * (rowHeight + CGFloat(settings.verticalSpacing))
                let rowCount = rowWindows.count
                let totalHSpacing = CGFloat(rowCount - 1) * CGFloat(settings.horizontalSpacing)
                let usableRowWidth = usableAXBounds.width - (CGFloat(settings.screenPadding) * 2) - totalHSpacing
                let idealCellWidth = max(50, floor(usableRowWidth / CGFloat(rowCount)))

                // Phase 1: Probe actual dimensions and constraints for each window in this row
                var allocatedWidths: [CGFloat] = Array(repeating: idealCellWidth, count: rowCount)
                var isConstrained: [Bool] = Array(repeating: false, count: rowCount)

                for (colIndex, window) in rowWindows.enumerated() {
                    guard let axElement = window.axElement else { continue }
                    // Probe ideal size
                    var testSize = CGSize(width: idealCellWidth, height: rowHeight)
                    if let val = AXValueCreate(.cgSize, &testSize) {
                        AXUIElementSetAttributeValue(axElement, kAXSizeAttribute as CFString, val)
                    }
                    if let actualFrame = getWindowFrame(axElement) {
                        let actualW = actualFrame.width
                        // If window is constrained (wider than ideal, or capped narrower like System Settings)
                        if abs(actualW - idealCellWidth) > 15 {
                            allocatedWidths[colIndex] = actualW
                            isConstrained[colIndex] = true
                        }
                    }
                }

                // Phase 2: Redistribute remaining row width among unconstrained windows
                let unconstrainedCount = isConstrained.filter { !$0 }.count
                if unconstrainedCount > 0 {
                    let constrainedTotalW = zip(allocatedWidths, isConstrained)
                        .filter { $0.1 }
                        .map { $0.0 }
                        .reduce(0, +)
                    let remainingW = usableRowWidth - constrainedTotalW
                    if remainingW > 50 {
                        let redistributedW = max(50, floor(remainingW / CGFloat(unconstrainedCount)))
                        for i in 0..<rowCount where !isConstrained[i] {
                            allocatedWidths[i] = redistributedW
                        }
                    }
                }

                // Phase 3: Place windows sequentially across the row with zero overlap
                var currentX = usableAXBounds.minX + CGFloat(settings.screenPadding)
                let maxAllowedX = usableAXBounds.maxX - CGFloat(settings.screenPadding)

                for (colIndex, window) in rowWindows.enumerated() {
                    guard let axElement = window.axElement else {
                        totalFailed += 1
                        continue
                    }

                    let cellW = allocatedWidths[colIndex]
                    let targetCellRect = CGRect(x: currentX, y: targetRowY, width: cellW, height: rowHeight)

                    if setWindowFrame(axElement, to: targetCellRect) {
                        totalSuccess += 1
                    } else {
                        totalFailed += 1
                    }

                    raiseWindow(axElement)

                    let actualW = getWindowFrame(axElement)?.width ?? cellW
                    currentX += actualW + CGFloat(settings.horizontalSpacing)
                }

                // Phase 4: If row extends past right screen boundary, pull back leftward
                if currentX - CGFloat(settings.horizontalSpacing) > maxAllowedX {
                    var rightEdge = maxAllowedX
                    for colIndex in stride(from: rowCount - 1, through: 0, by: -1) {
                        guard let ax = rowWindows[colIndex].axElement, let frame = getWindowFrame(ax) else { continue }
                        if frame.maxX > rightEdge {
                            let newX = max(usableAXBounds.minX + CGFloat(settings.screenPadding), rightEdge - frame.width)
                            setWindowFrame(ax, to: CGRect(x: newX, y: frame.minY, width: frame.width, height: frame.height))
                            rightEdge = newX - CGFloat(settings.horizontalSpacing)
                        } else {
                            rightEdge = frame.minX - CGFloat(settings.horizontalSpacing)
                        }
                    }
                }
            }

            // Strictly clamp all windows inside screen usable bounds
            clampAllWindowsToScreen(windows: orderedWindows, in: usableAXBounds)
        }

        if totalSuccess > 0 {
            triggerFeedbackSound()
        }

        DispatchQueue.main.async {
            let scope = (targetScreen != nil) ? "active screen: " : ""
            let summary: String
            if totalFailed == 0 {
                summary = "Arranged \(scope)\(totalSuccess) window\(totalSuccess == 1 ? "" : "s")"
            } else {
                summary = "Arranged \(scope)\(totalSuccess) window\(totalSuccess == 1 ? "" : "s"), \(totalFailed) skipped"
            }
            self.lastResultSummary = summary
            AppLogger.windowManager.info("\(summary)")
        }
    }

    // MARK: - Undo

    /// Restores windows to their frames recorded in the last snapshot.
    public func undoLastArrangement() {
        guard let snapshot = lastArrangementSnapshot else { return }

        var restored = 0
        for item in snapshot.snapshots {
            guard let axElement = item.window.axElement else { continue }
            if setWindowFrame(axElement, to: item.frame) {
                restored += 1
            }
            raiseWindow(axElement)
        }

        if restored > 0 {
            triggerFeedbackSound()
        }

        DispatchQueue.main.async {
            self.lastArrangementSnapshot = nil
            let summary = "Restored \(restored) window\(restored == 1 ? "" : "s")"
            self.lastResultSummary = summary
            AppLogger.windowManager.info("\(summary)")
        }
    }

    // MARK: - Helper Actions

    /// Brings an application window to the front.
    private func raiseWindow(_ axWindow: AXUIElement) {
        AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
    }

    // MARK: - Row Partitioning & Boundary Clamping

    /// Distributes windows across rows so that each row is balanced and completely filled without empty gaps.
    private func partitionWindowsIntoRows(windows: [AppWindow], rows: Int, columns: Int) -> [[AppWindow]] {
        guard rows > 1 && !windows.isEmpty else { return [windows] }

        var result: [[AppWindow]] = []
        let total = windows.count
        var remaining = total
        var startIndex = 0

        for r in 0..<rows {
            let remainingRows = rows - r
            let countForThisRow = min(columns, max(1, Int(ceil(Double(remaining) / Double(remainingRows)))))
            let endIndex = min(total, startIndex + countForThisRow)

            let rowWindows = Array(windows[startIndex..<endIndex])
            if !rowWindows.isEmpty {
                result.append(rowWindows)
            }

            startIndex = endIndex
            remaining = max(0, total - startIndex)
            if remaining == 0 { break }
        }

        if startIndex < total {
            if !result.isEmpty {
                result[result.count - 1].append(contentsOf: windows[startIndex..<total])
            } else {
                result.append(Array(windows[startIndex..<total]))
            }
        }

        return result
    }

    /// Strictly clamps every window to ensure its entire frame is completely within the usable screen area.
    private func clampAllWindowsToScreen(
        windows: [AppWindow],
        in bounds: CGRect
    ) {
        let screenPadding = CGFloat(settings.screenPadding)
        let minAllowedX = bounds.minX + screenPadding
        let maxAllowedX = bounds.maxX - screenPadding
        let minAllowedY = bounds.minY + screenPadding
        let maxY = bounds.maxY - screenPadding

        for win in windows {
            guard let ax = win.axElement, let frame = getWindowFrame(ax) else { continue }

            var clampedX = frame.origin.x
            var clampedY = frame.origin.y
            var clampedW = frame.width
            var clampedH = frame.height

            // Clamp width and height to fit on screen
            if clampedW > (maxAllowedX - minAllowedX) {
                clampedW = max(100, maxAllowedX - minAllowedX)
            }
            if clampedH > (maxY - minAllowedY) {
                clampedH = max(100, maxY - minAllowedY)
            }

            // Clamp right edge
            if clampedX + clampedW > maxAllowedX {
                clampedX = max(minAllowedX, maxAllowedX - clampedW)
            }
            // Clamp left edge
            if clampedX < minAllowedX {
                clampedX = minAllowedX
            }

            // Clamp bottom edge
            if clampedY + clampedH > maxY {
                clampedY = max(minAllowedY, maxY - clampedH)
            }
            // Clamp top edge
            if clampedY < minAllowedY {
                clampedY = minAllowedY
            }

            let clampedRect = CGRect(x: clampedX, y: clampedY, width: clampedW, height: clampedH)
            if clampedRect != frame {
                setWindowFrame(ax, to: clampedRect)
            }
        }
    }
}
