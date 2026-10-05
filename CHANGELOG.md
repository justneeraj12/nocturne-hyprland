# Changelog

## 0.4.0 - 2026-10-05

- Rebuilt Nocturne Settings as a responsive control center with a collapsible,
  self-revealing sidebar, global search and keyboard-first section navigation.
- Added a real overview, wallpaper library and preview, day-cycle state, visible
  accent swatches, guarded theme previews and a wallpaper-derived theme studio.
- Added live touchpad, pointer, keyboard, default-application, file-location,
  timezone and network-time controls backed by the active system configuration.
- Added honest hardware, account and service health pages plus direct maintenance,
  privacy, gaming, display, audio and connectivity entry points.
- Added hardware-aware usage profiles, portable settings export and guarded
  last-known-good rollback without including credentials or personal files.
- Unified the settings visual language around compact Nocturne cards and terminal
  glyphs, and fixed default file-manager discovery when the desktop cache is stale.

## 0.3.3 - 2026-10-05

- Replaced the dated primary file-manager surface with a compact Dolphin-based
  Nocturne Files profile: dark palette, tabs, split view and rich previews.
- Scoped KDE platform styling to Files without installing or launching Plasma,
  KDE Settings or another desktop shell.
- Disabled Baloo background indexing, hid the PCManFM fallback from the launcher
  and made Files the default folder handler and `Super + E` destination.
- Added reversible Dolphin preferences and data handling to install, health-check
  and rollback paths.

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
