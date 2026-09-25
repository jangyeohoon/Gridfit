# Gridfit

A lightweight macOS menu bar app for tiling and snapping windows with keyboard shortcuts.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

Gridfit arranges open windows into a clean, non-overlapping grid with a single shortcut, similar to tiling window managers, but without replacing the default macOS window manager.

---

## Features

- **Auto-Tiling (`⌥G`)**: Tiles visible windows into a balanced grid based on your screen aspect ratio.
- **Quick Snap**: Snap the focused window to left/right/top/bottom halves, maximize, or center from the menu bar.
- **Multi-Monitor**: Move windows between displays while preserving relative proportions.
- **App Exclusions**: Exclude background apps (Slack, Spotify, etc.) from being tiled.
- **Undo (`⌘Z`)**: Revert the last arrangement back to original window positions.
- **Sound Feedback**: Optional system click sound when windows are moved or tiled.

---

## Installation

### Download DMG

1. Download the latest `Gridfit.dmg` from [Releases](https://github.com/jangyeohoon/Gridfit/releases/latest).
2. Drag **Gridfit** into `/Applications`.
3. Launch the app from Applications or Spotlight.

### Permissions

Gridfit requires macOS Accessibility permissions to read window sizes and reposition them via `AXUIElement` APIs.

On first launch, follow the onboarding prompt or go to:
> **System Settings** > **Privacy & Security** > **Accessibility** > enable **Gridfit**.

---

## Default Shortcuts

| Action | Shortcut |
| :--- | :--- |
| Tile windows (all screens) | `⌥G` |
| Tile windows (active screen only) | Menu Bar > Arrange Active Screen |
| Undo last arrangement | Menu Bar > Undo (`⌘Z`) |
| Snap focused window | Menu Bar > Snap Active Window |
| Move to next display | Menu Bar > Move to Next Display |

*The global shortcut can be customized in **Settings > Shortcuts**.*

---

## Building from Source

Requirements: macOS 13.0+, Xcode 15.0+

```bash
git clone https://github.com/jangyeohoon/Gridfit.git
cd Gridfit
./build_dmg.sh
```

The output will be placed at `./Gridfit.dmg`.

---

<a name="privacy-policy"></a>
## Privacy Policy

Gridfit runs entirely locally on your Mac:
- **No Network Activity**: The app does not make network requests, track analytics, or send telemetry.
- **No Keystroke / Screen Logging**: Accessibility permissions are used strictly to query and update window bounding boxes (`kAXPositionAttribute`, `kAXSizeAttribute`). Window contents, keystrokes, and screen buffers are never accessed.

---

## License

[MIT](LICENSE) © 2026 Yeohoon Jang