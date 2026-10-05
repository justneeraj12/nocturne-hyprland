# Changelog

## 0.3.2 - 2026-10-04

- Upgraded PCManFM-Qt into the Nocturne Files profile with compact tabs,
  restored sessions, larger local previews and lightweight search defaults.
- Added a single NOC Tools context menu for terminal, VS Code, path copying,
  SHA-256, safe archives, extraction, wallpaper changes and KDE Connect sharing.
- Added PDF previews, a clean Files launcher with location shortcuts and direct
  Files controls inside Nocturne System Settings.
- Replaced the GNOME archive integration with LXQt Archiver when available while
  retaining a safe fallback on existing systems.

## 0.3.1 - 2026-10-04

- Consolidated desktop configuration into one **System Settings** launcher and
  hid the non-functional GNOME, KDE, GTK, Qt and standalone PipeWire settings entries.
- Added native input controls for touchpad behavior, pointer speed and keyboard repeat.
- Added XDG default-application selectors and native timezone/network-time controls.
- Added a system/integrations page showing hardware, three preserved Google accounts,
  portal ownership, credentials, Google Drive, KDE Connect and advanced hardware tools.
- Made the launcher honor `OnlyShowIn` and `NotShowIn` desktop-entry rules and discover Snap exports.
- Documented compatibility backends explicitly instead of presenting them as shell components.

## 0.3.0 - 2026-10-04

- Added a native nine-workspace overview with focus, close and drag-to-workspace controls.
- Added session scenes for applications, workspaces, monitors, wallpaper, power and audio routing.
- Added zero-persistent dock, mobile, AC and battery context automation with settings-only restoration.
- Added audio scenes, a one-click laptop-microphone meeting profile and EasyEffects preset recall.
- Added a privacy dashboard for live microphone/camera clients with guarded process termination.
- Added a gaming dashboard with NVIDIA telemetry, automatic rollback, MangoHud and per-game power profiles.
- Added grouped notification history, one-hour application muting and one-click verification-code copying.
- Added 30-second theme previews, automatic rollback, wallpaper-derived accents and custom theme saves.
- Added last-known-good checkpoints, post-login health verification and a minimal recovery login session.
- Expanded Command Center with favorites, recent apps, file search (`~`) and calculator results (`=`).

## 0.2.0 - 2026-10-04

- Upgraded the launcher into a command center for apps, running windows and
  guarded desktop actions, with direct `@` and `>` search modes.
- Added timed notification focus modes with 30-minute, one-hour and
  until-morning presets and automatic expiry.
- Added event-driven Steam game detection that applies performance, caffeine
  and focus settings, then restores the previous session state.
- Added compact native volume, microphone and brightness OSD feedback for
  hardware keys.
- Added Flatpak-exported applications to launcher discovery.

## 0.1.0 - Unreleased

- Replaced custom GTK popovers with one Qt 6/Wayland layer-shell binary.
- Added live PipeWire graph discovery for native and compatibility app streams.
- Added continuous hardware-backlight synchronization while brightness is open.
- Replaced the unstable custom capture stack with upstream Hyprshot and Kooha.
- Added a reversible installer, read-only doctor, clean-build validation and CI.
- Added native Wi-Fi, Bluetooth, VPN, power, calendar, launcher and workflow cards.
- Added a public showcase, install guide, architecture notes and launch plan.
- Added native Night Shift, display layout and system-maintenance cards.
- Added captive-portal/metered-network state and hardware-aware setup profiles.
- Added validated portable preference export and restore.
- Removed compositor blur from ChatGPT XWayland context-menu subsurfaces.
- Added verified, fail-closed NVIDIA PRIME offload for Steam game processes.
- Added safe Signal profile routing and Hyprland-compatible libsecret startup.
