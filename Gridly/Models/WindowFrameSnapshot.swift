//
//  WindowFrameSnapshot.swift
//  Gridly
//

import Foundation
import CoreGraphics

/// Stores a snapshot of a window's frame prior to arrangement to support Undo operations.
public struct WindowFrameSnapshot: Equatable {
    public let window: AppWindow
    public let frame: CGRect

    public init(window: AppWindow, frame: CGRect) {
        self.window = window
        self.frame = frame
    }
}

/// Represents an undoable batch of window arrangements.
public struct ArrangementSnapshot {
    public let snapshots: [WindowFrameSnapshot]

    public init(snapshots: [WindowFrameSnapshot]) {
        self.snapshots = snapshots
    }
}
