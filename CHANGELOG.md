# Changelog

## 1.2.0 - 2026-10-06

- Added five accent-aware lock-screen compositions with persistent selection and a one-unlock safe preview.
- Added a responsive Lock Screen Style selector to Appearance and regression coverage for every rendered layout.
- Added the zero-idle NOC Operations Deck with health scoring, resource, network, power and control-plane telemetry.
- Moved essential Wayland session components into one systemd-supervised target with bounded restart and clean shutdown behavior.
- Added an explicit native-shell performance budget, CLI benchmark, doctor integration and release regression checks.

## 1.1.0 - 2026-10-06

- Added Storage Center with bounded cleanup, protected-data declarations and on-demand large-duplicate discovery.
- Added reversible Meeting Mode, Permission Center, startup ownership, NOC Guard, scoped checkpoint diff and private NOC Pulse.
- Added a bounded trigger/action Automation Builder that reuses the existing context timer and records explainable trace events.
- Added Power Lab, monitor refresh/VRR controls, Hyprland 0.56 input gestures, Wi-Fi sharing, hotspot and richer Bluetooth detail.
- Added sensitive clipboard filtering and expiry, private pinned text, screenshot annotation and local screen OCR.
- Added schema 8 migration, zero-idle diagnostics and end-to-end contracts for the new native controls.
- Published a precise [fifty-feature release manifest](docs/RELEASE-1.1.md).

## 1.0.0 - 2026-10-06

- Added NOC Habits, a native private weekly habit and streak tracker with pacing, filtering, archive, undo, export, and keyboard control.
- Added NOC Vault, a native private snippet and link library with tags, pinning, usage sorting, safe URL opening, clipboard capture, undo, and export.
- Added `++`, `::`, `note`, `copy`, and `open` Command Center grammars plus searchable Habits and Vault actions.
- Added schema 7 migration, doctor privacy checks, zero-daemon checks, and comprehensive state/clipboard/UI contracts.
- Published a precise [fifty-feature release manifest](docs/RELEASE-1.0.md).

## 0.9.0 - 2026-10-06

- Added NOC Desk: a zero-daemon native task inbox with priority, due dates,
  filters, search, pinning, inline editing, guarded deletion, undo and clear.
- Added an autosaved private scratch note, Markdown export and a count-only daily
  brief without introducing an account, sync backend or content telemetry.
- Linked a selected task to Pomodoro and notification focus, persisted the timer
  across shell restarts, and recorded local focus blocks/minutes automatically.
- Added event-driven Desk state to the adaptive bar, a `Super+Shift+N` shortcut,
  Bar Studio control and Settings integration.
- Added safe `+` task capture and deterministic Command Center controls for
  volume, brightness, focus, timer, power, Wi-Fi, Bluetooth, Night Shift and mute.
- Added schema migration, private-file and zero-process diagnostics, shell data
  contracts and runtime query coverage for the new workflow surfaces.

## 0.8.0 - 2026-10-05

- Added Nocturne Trace, a privacy-limited local timeline that explains context
  decisions without recording applications, window titles, networks or content.
- Added two-stage scene previews and confirmations showing application launches,
  window placements, displays and settings impact before restore.
- Restored saved design presets as part of scenes and recorded manual or automatic
  scene changes through the same explainable history.
- Eliminated context polling while automation is paused and made diagnostics
  distinguish intentional zero-cost state from a failed timer.
- Added runtime instantiation coverage for 23 on-demand QML pages plus permanent
  installer/rollback manifest symmetry checks.
- Changed Settings to instantiate only its visible section, releasing inactive
  wallpaper, hardware and diagnostics pages instead of retaining all 14 at once.
- Fixed rollback coverage for the `nocturne-support` helper and made the context
  engine's decision interface explicit and testable.

## 0.7.0 - 2026-10-05

- Shipped fifty interaction, accessibility, safety and navigation improvements
  across shared controls, Command Center, clipboard, notifications, minimized
  windows, power and Settings.
- Added structured and one-line diagnostics plus a privacy-limited support
  archive that deliberately excludes configs, logs, networks and user content.
- Added zero-idle UVC camera profiles with sensor ownership protection,
  automatic exposure/white balance/focus, backlight modes and local anti-flicker.
- Added accessible audio state, persistent Settings navigation and global card
  refresh/help shortcuts.

## 0.6.1 - 2026-10-05

- Gave brightness a dedicated sun/radiance glyph across the bar, OSD and
  command output so it cannot be confused with the resource-dashboard chip.
- Replaced the dated repository captures with privacy-reviewed images from the
  installed release and added Overview and Efficiency Center coverage.
- Reworked the README release story and four-panel desktop showcase around the
  current native shell rather than historical UI.

## 0.6.0 - 2026-10-05

- Added a compact pinned screen-share chooser and a live red capture indicator.
- Fixed false idle-camera privacy reports and added read-only capture diagnostics.
- Added the on-demand Efficiency Center with proportional memory reporting,
  grouped consumers, startup health and guarded cache cleanup.
- Preserved app attribution with lazy desktop indexing, reduced irrelevant
  PipeWire event churn and improved ordinary left-click tray controls.

## 0.5.1 - 2026-10-05

- Fixed a reboot race where the wallpaper service inherited no Wayland display,
  repeatedly failed to start Hyprpaper and left every output without a background.
- Moved wallpaper startup ownership to Hyprland after session-environment import,
  removed historical `default.target` enablement and added monitor-aware recovery.
- Capped repetitive Hyprpaper diagnostics so a failed renderer cannot grow its
  login log indefinitely.

## 0.5.0 - 2026-10-05

- Replaced frequent bar polling with native Hyprland, PipeWire, MPRIS,
  NetworkManager, BlueZ, UPower, backlight and StatusNotifier event updates,
  retaining slow recovery timers instead of treating timers as primary state.
- Added Bar Studio with live preview, global and per-display density, module
  visibility overrides, icon scaling, separators and tray-count controls.
- Added native DBusMenu rendering for background apps, keyboard navigation and
  real per-application tray actions without opening foreign toolkit menus.
- Upgraded notifications with search, progress, keyboard actions and calmer
  refresh behavior, and upgraded Media Hub with player tabs, seek, artwork and
  per-player MPRIS volume.
- Extended context automation with meeting, focus and gaming detection plus
  settings-only scene mappings, hidden baseline snapshots and exact rollback.
- Added shared panel keyboard controls, versioned configuration migrations,
  isolated interaction-contract tests, crash-loop backoff and automatic
  last-known-good shell recovery.

## 0.4.1 - 2026-10-05

- Rebuilt the background-app panel as a compact, scroll-safe application list
  with live status, process identity and clear open/menu interactions.
- Fixed left-click activation by dismissing the overlay after success and added
  reliable fallbacks for Ayatana-only tray apps such as Steam.
- Removed the three-item tray truncation, added a live background-app count and
  application summary to the bar, and retained support for up to twelve items.
- Added sharp visual grouping, hover feedback and accent focus lines across all
  bar buttons without increasing bar height or idle process count.

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
