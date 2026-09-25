# Gridfit

<p align="center">
  <strong>Intelligent, Native Window Auto-Tiler & Manager for macOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0%2B-blue?logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/release-v1.0.0-purple" alt="Release" />
</p>

---

**Gridfit** is a lightweight, high-performance macOS menu bar utility designed to bring instant order to your messy workspace. With a single customizable keystroke or a click, Gridfit tiles all visible application windows into an aesthetically balanced grid layout without overlaps.

---

## ✨ Key Features

- **⚡️ One-Key Auto-Tiling**: Instantly calculates the optimal grid layout based on screen aspect ratio and window count, clamping perfectly inside your usable display bounds.
- **🪟 Quick Snap Active Window**: Snap the focused window to Left Half, Right Half, Top Half, Bottom Half, Maximize, or Center directly from the menu bar.
- **🖥️ Multi-Display Support**: Automatically detects monitor configurations and supports moving active windows across displays while preserving relative proportions.
- **🎯 App Exclusion**: Exclude persistent windows or background apps (e.g., Slack, Spotify) from auto-arrangement with one click.
- **↩️ Instant Undo (`⌘Z`)**: Made a mistake? Seamlessly restore windows back to their previous coordinates and sizes.
- **🔔 Tactile Audio Feedback**: Subtle system sound feedback confirms window movement and tiling actions.
- **🔒 100% Privacy & Security**: Operates completely offline. Never captures keystrokes, personal information, window contents, or telemetry.

---

## 🚀 Installation

### Download DMG
1. Download the latest `Gridfit.dmg` from [GitHub Releases](https://github.com/jangyeohoon/Gridfit/releases/latest).
2. Open the DMG and drag **Gridfit** into your `Applications` folder.
3. Launch Gridfit from Spotlight or Applications.

### Accessibility Permission Setup
Gridfit uses the native macOS Accessibility API (`AXUIElement`) to reposition and resize windows.
1. On first launch, the **Welcome Guide** will appear automatically.
2. Click **Open System Settings** to navigate to `Privacy & Security > Accessibility`.
3. Toggle the switch next to **Gridfit** to `ON`.

---

## ⌨️ Shortcuts & Usage

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **Auto-Tile All Screens** | `⌥ G` (Option + G) | Instantly tiles all manageable windows on all displays |
| **Auto-Tile Current Screen** | Menu Bar | Tiles only windows located on the display under cursor |
| **Undo Last Arrangement** | Menu Bar (`⌘Z`) | Restores windows to pre-tiling positions |
| **Quick Snap** | Menu Bar | Snap focused window to halves, center, or maximize |
| **Move to Next Display** | Menu Bar | Moves focused window to the next connected monitor |

> *Note: The global auto-tile shortcut can be customized to any key combination in **Gridfit Settings > Shortcuts**.*

---

## 🛠️ Build from Source

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0+ or Command Line Tools

```bash
# Clone the repository
git clone https://github.com/jangyeohoon/Gridfit.git
cd Gridfit

# Build Release application & package DMG
chmod +x build_dmg.sh
./build_dmg.sh
```

The resulting `Gridfit.dmg` will be saved directly in the project root directory.

---

<a name="privacy-policy"></a>
## 🔒 Privacy Policy

Gridfit was built with strict privacy and security standards:
- **No Data Collection**: Gridfit does not track, collect, store, or transmit any user data, telemetry, analytics, or identifier tokens.
- **Local Execution**: All window calculations and Accessibility API calls run 100% locally on your Mac without any network connections.
- **Accessibility Scope**: Accessibility privileges are used solely to query window bounding boxes (`kAXPositionAttribute`, `kAXSizeAttribute`) and move/resize windows. Keystrokes, screen recordings, and application contents are never read.

For inquiries or feedback, please visit [GitHub Issues](https://github.com/jangyeohoon/Gridfit/issues).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.