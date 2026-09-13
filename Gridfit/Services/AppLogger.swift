//
//  AppLogger.swift
//  Gridfit
//

import Foundation
@_exported import os

/// Centralized unified logging subsystem for Gridfit.
/// Integrated with Console.app and zero-cost in release builds when inactive.
public enum AppLogger {
    private static let subsystem = "yeohoon-jang.Gridfit"

    public static let general = Logger(subsystem: subsystem, category: "General")
    public static let windowManager = Logger(subsystem: subsystem, category: "WindowManager")
    public static let hotKey = Logger(subsystem: subsystem, category: "HotKey")
    public static let accessibility = Logger(subsystem: subsystem, category: "Accessibility")
}
