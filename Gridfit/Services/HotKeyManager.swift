//
//  HotKeyManager.swift
//  Gridfit
//

import AppKit
import Carbon
import os

/// Registers and handles system-wide global hotkeys using Carbon Event API.
public final class HotKeyManager {
    public static let shared = HotKeyManager()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeySignature: OSType = 0x47524944 // 'GRID'
    private let hotKeyIDValue: UInt32 = 1

    private init() {}

    deinit {
        unregister()
    }

    /// Registers the global shortcut using the current settings in UserSettings.
    public func registerFromSettings() {
        let settings = UserSettings.shared
        register(keyCode: UInt32(settings.hotkeyKeyCode), modifiers: UInt32(settings.hotkeyModifiers))
    }

    /// Registers the global shortcut with the specified keyCode and Carbon modifiers.
    public func register(keyCode: UInt32 = UInt32(kVK_ANSI_G), modifiers: UInt32 = UInt32(cmdKey | shiftKey)) {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                guard let theEvent = theEvent else { return noErr }

                let err = GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if err == noErr && hotKeyID.signature == 0x47524944 && hotKeyID.id == 1 {
                    DispatchQueue.main.async {
                        WindowManager.shared.arrangeAllWindows()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else {
            AppLogger.hotKey.error("Failed to install Carbon event handler: \(status)")
            return
        }

        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: hotKeyIDValue)
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        let shortcutName = ShortcutFormatter.displayString(keyCode: UInt16(keyCode), modifiers: modifiers)
        if regStatus != noErr {
            AppLogger.hotKey.error("Failed to register global hotkey \(shortcutName): \(regStatus)")
        } else {
            AppLogger.hotKey.info("Registered global hotkey: \(shortcutName)")
        }
    }

    /// Unregisters the current global hotkey and removes the event handler.
    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}
