# Gridfit

단축키로 창을 바둑판식으로 자동 정렬하고 화면을 분할하는 가벼운 macOS 메뉴바 유틸리티입니다.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

Gridfit은 복잡한 타일형 윈도우 매니저를 설치할 필요 없이, 단축키 하나로 현재 열린 창들을 화면에 맞게 균형 잡힌 격자로 자동 정렬해 줍니다.

---

## 주요 기능

- **창 자동 정렬 (`⌥G`)**: 화면 비율과 창 개수에 맞춰 열린 창들을 겹침 없이 바둑판식으로 배치합니다.
- **빠른 스냅**: 메뉴바에서 활성 창을 좌/우/상/하 반분할, 전체 화면, 중앙 정렬할 수 있습니다.
- **다중 모니터 지원**: 모니터 간 창 이동 시 화면 비율과 크기를 유지한 채 다음 디스플레이로 보냅니다.
- **특정 앱 정렬 제외**: 메신저나 음악 플레이어(Slack, 카카오톡, Spotify 등)를 정렬 대상에서 제외할 수 있습니다.
- **실행 취소 (`⌘Z`)**: 정렬 직후 바로 이전 위치와 크기로 창을 원상 복구합니다.
- **효과음 피드백**: 창 이동 및 정렬 시 미세한 클릭 사운드를 제공합니다 (설정에서 켜고 끄기 가능).

## 설치 방법

1. [Releases](https://github.com/jangyeohoon/Gridfit/releases/latest) 페이지에서 최신 `Gridfit.dmg`를 다운로드합니다.
2. `Gridfit`을 `/Applications` 폴더로 드래그합니다.
3. 앱을 실행합니다.

### 권한 설정
창 크기를 파악하고 위치를 조정하기 위해 macOS 손쉬운 사용(Accessibility) 권한이 필요합니다.

첫 실행 시 온보딩 창이 나타나며, 수동 설정 시 아래 경로에서 허용할 수 있습니다:
> **시스템 설정** > **개인정보 보호 및 보안** > **손쉬운 사용** > **Gridfit** 체크

## 기본 단축키

| 동작 | 단축키 |
| :--- | :--- |
| 모든 화면 창 자동 정렬 | `⌥G` |
| 마우스가 있는 화면만 정렬 | 메뉴바 > Arrange Active Screen |
| 마지막 정렬 되돌리기 | 메뉴바 > Undo (`⌘Z`) |
| 활성 창 분할/스냅 | 메뉴바 > Snap Active Window |
| 다음 모니터로 창 이동 | 메뉴바 > Move to Next Display |

*단축키는 **Gridfit 설정 > Shortcuts**에서 원하는 키 조합으로 변경할 수 있습니다.*

## 소스코드 빌드

요구 사항: macOS 13.0 이상, Xcode 15.0 이상

```bash
git clone https://github.com/jangyeohoon/Gridfit.git
cd Gridfit
./build_dmg.sh
```

빌드가 끝나면 프로젝트 루트에 `Gridfit.dmg`가 생성됩니다.

<a name="privacy-policy"></a>
## 개인정보 처리방침

Gridfit은 외부 서버와 통신하지 않고 사용자의 Mac에서 100% 로컬로 동작합니다:
- **네트워크 통신 없음**: 어떠한 데이터, 사용자 정보, 사용 통계(텔레메트리)도 외부로 전송하지 않습니다.
- **키로깅 및 화면 캡처 없음**: 손쉬운 사용 권한은 오직 창의 좌표와 크기(`kAXPositionAttribute`, `kAXSizeAttribute`)를 조회하고 조절하는 데만 사용됩니다. 창의 내용이나 키보드 입력을 기록하지 않습니다.

---

# Gridfit

A lightweight macOS menu bar app for tiling and snapping windows with keyboard shortcuts.

Gridfit arranges open windows into a clean, non-overlapping grid with a single shortcut, similar to tiling window managers, but without replacing the default macOS window manager.

---

## Features

- **Auto-Tiling (`⌥G`)**: Tiles visible windows into a balanced grid based on screen aspect ratio.
- **Quick Snap**: Snap the focused window to left/right/top/bottom halves, maximize, or center from the menu bar.
- **Multi-Monitor**: Move windows between displays while preserving relative proportions.
- **App Exclusions**: Exclude background apps (Slack, Spotify, etc.) from being tiled.
- **Undo (`⌘Z`)**: Revert the last arrangement back to original window positions.
- **Sound Feedback**: Optional system click sound when windows are moved or tiled.

## Installation

1. Download the latest `Gridfit.dmg` from [Releases](https://github.com/jangyeohoon/Gridfit/releases/latest).
2. Drag **Gridfit** into `/Applications`.
3. Launch the app from Applications or Spotlight.

### Permissions
Gridfit requires macOS Accessibility permissions to read window sizes and reposition them via `AXUIElement` APIs.

On first launch, follow the onboarding prompt or go to:
> **System Settings** > **Privacy & Security** > **Accessibility** > enable **Gridfit**.

## Default Shortcuts

| Action | Shortcut |
| :--- | :--- |
| Tile windows (all screens) | `⌥G` |
| Tile windows (active screen only) | Menu Bar > Arrange Active Screen |
| Undo last arrangement | Menu Bar > Undo (`⌘Z`) |
| Snap focused window | Menu Bar > Snap Active Window |
| Move to next display | Menu Bar > Move to Next Display |

*The global shortcut can be customized in **Settings > Shortcuts**.*

## Building from Source

Requirements: macOS 13.0+, Xcode 15.0+

```bash
git clone https://github.com/jangyeohoon/Gridfit.git
cd Gridfit
./build_dmg.sh
```

The output will be placed at `./Gridfit.dmg`.

## Privacy Policy

Gridfit runs entirely locally on your Mac:
- **No Network Activity**: The app does not make network requests, track analytics, or send telemetry.
- **No Keystroke / Screen Logging**: Accessibility permissions are used strictly to query and update window bounding boxes (`kAXPositionAttribute`, `kAXSizeAttribute`). Window contents, keystrokes, and screen buffers are never accessed.

---

## License

[MIT](LICENSE) © 2026 Yeohoon Jang