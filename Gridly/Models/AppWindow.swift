//
//  AppWindow.swift
//  Gridify
//

import Foundation
import CoreGraphics
import ApplicationServices

/// Represents an application window on macOS detected via Accessibility / CoreGraphics APIs.
public struct AppWindow: Identifiable, Equatable {
    public let id: String
    public let applicationPID: pid_t
    public let applicationName: String
    public let windowTitle: String
    public let windowID: CGWindowID?
    public var frame: CGRect
    public var axElement: AXUIElement?

    public init(
        applicationPID: pid_t,
        applicationName: String,
        windowTitle: String,
        windowID: CGWindowID?,
        frame: CGRect,
        axElement: AXUIElement? = nil
    ) {
        let elementHash = axElement.map { String(CFHash($0)) } ?? String(abs(windowTitle.hashValue))
        self.id = "\(applicationPID)_\(windowID ?? 0)_\(elementHash)"
        self.applicationPID = applicationPID
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.windowID = windowID
        self.frame = frame
        self.axElement = axElement
    }

    public static func == (lhs: AppWindow, rhs: AppWindow) -> Bool {
        return lhs.applicationPID == rhs.applicationPID &&
               lhs.windowID == rhs.windowID &&
               lhs.windowTitle == rhs.windowTitle
    }
}
