# Nocturne — Hyprland desktop with a GNOME safety net

This machine now has two independent desktop sessions:

- **Hyprland (uwsm-managed):** keyboard-first Tokyo Night tiling, compact
  Waybar, no compositor title bars, notification history, clipboard history,
  Caffeine, Pomodoro, media controls, audio/network/Bluetooth controls,
  resource tools, a native settings app, scheduled wallpapers, a session-local
  sharp dark app/file-manager theme, and a matching terminal setup.
- **Ubuntu / GNOME:** restored to the original MacTahoeCompact-Dark setup,
  including its MacTahoe icons, left-side window controls, extensions, and
  SolidForest wallpaper.

Steam, VS Code, ChatGPT, browsers, PipeWire audio, and the Intel/NVIDIA gaming
stack were not replaced. They run as ordinary applications in either session.

## NØX — Nocturne Agent

The repository now also contains `agent/`, a local-first desktop operator built
for this exact Hyprland setup. Common requests such as opening an approved app,
changing volume or brightness, moving to a workspace, controlling media, and
checking system health are handled without loading a language model. Every
action passes through a typed allowlist; raw shell, `sudo`, deletion, package
management, and messaging are not exposed to inference.

Its controller is activated by a private systemd user socket and exits after
five idle minutes. Prompt text and file contents are not written to its usage
database. Run `nox` or press `Super+X` for the full-screen terminal chat;
results also arrive through the existing themed notification center. It can
perform explicit read-only checks of processes, windows, services, downloads,
network, audio, and power. Its Tool Forge can propose policy-validated routines
from existing typed actions, but saves them disabled until the user explicitly
enables one. There is no floating agent control panel. See `agent/README.md`
for the architecture, tests, and install path.
Unmatched requests enter a three-step bounded agent loop that can discover
installed apps, chain typed actions, inspect compact results, recover from a
failed step, and stop repeated calls. Six ephemeral action receipts support
follow-ups without storing raw prompt text.
Installed-app requests are resolved from desktop entries and launched in
separate UWSM graphical scopes, so they tile normally without inheriting the
agent controller's read-only sandbox.

## Start Hyprland

1. Log out of GNOME.
2. Select your username on the login screen.
3. Use the gear menu and choose **Hyprland (uwsm-managed)**.
4. Sign in.

The first shortcuts to remember are:

```text
Super + Space       apps
Super + R           Nocturne Settings
Super + Enter       terminal
Super + /           complete key guide
Super + Q           close a window
Super + A           snap a floating window into the tiling layout
Super + drag        move/resize with the mouse
Super + P           lock, log out, suspend, reboot, or shut down
```

The Ubuntu logo in the bar is also clickable: left opens apps, right opens the
control center, and middle opens the key guide. The full guide is in
`config/hypr/KEYS.md`.

## Included desktop features

- Dual-screen layout: LG UltraGear at 1920×1080/180 Hz on the left and laptop
  panel at 1920×1080/144 Hz on the right.
- Sharp Obsidian borders, small gaps, workspace animation, mouse support,
  scratchpad, window groups, and three-finger workspace swipes.
- Compact per-design tiling gaps (1–2 px inner, 2–4 px outer) keep the layout
  dense without letting adjacent one-pixel borders visually merge.
- SwayNotificationCenter for application-independent notification history and
  do-not-disturb mode.
- Cliphist clipboard picker and a native bottom-center Nocturne capture overlay
  on Print Screen, following Ubuntu's Shot/Record → Area/Display/All/Window →
  Capture workflow.
  It captures all displays, one display, the active window, or a dragged area;
  it also records a display or selected area with a red bar indicator. Still
  images save to `~/Pictures/Screenshots` and copy to the clipboard, while
  recordings save to `~/Videos/Screencasts`. Opening capture freezes the
  pre-panel frame, so transient menus and dropdowns remain in the result.
- Caffeine toggle backed by Hypridle, with 10-minute lock and 15-minute screen
  sleep when Caffeine is off.
- A 25/5 Pomodoro timer in the bar.
- A minimal Omarchy-style bar with MPRIS, audio, network, Bluetooth, grouped
  system health, microphone-use, notification, clock, and native tray apps.
  Wi-Fi and Bluetooth stay permanently visible with matching compact panels.
- The compact audio card switches real PipeWire outputs, per-app volume, and
  physical microphones. Newly connected Bluetooth audio becomes the active
  output automatically while the laptop Digital Microphone stays preferred;
  choosing a headset mic temporarily enters HFP and switching back restores
  high-quality A2DP playback.
  Ordinary background-app icons live in a three-dot drawer at the far-right
  edge, while the hidden Blueman agent continues handling pairing and
  authentication without adding another icon. Audio, media, KDE Connect, and
  power use compact click-to-toggle cards. A themed clock card
  combines every saved world time, live weather, Pomodoro, and caffeine. The
  native Nocturne Settings app replaces the main GNOME Settings shell, which cannot run
  outside GNOME. It provides a sidebar for appearance, wallpapers,
  connectivity, sound, desktop, hardware, power and shortcut help. The
  standard Settings launcher routes intelligently to Nocturne under Hyprland
  and Ubuntu Settings under GNOME. Audio includes
  per-app volume; KDE Connect uses a matching dark Qt6 theme. Detailed process
  data lives in the resource dashboard.
  A Hyprland-session watchdog restarts the bar after an unexpected crash
  without allowing it to leak into the restored GNOME session.
- **Settings → Accounts + apps** opens the real GNOME Online Accounts Google
  login used by Ubuntu. Calendar uses that shared account; native GNOME
  Calendar and Iotas inherit the Nocturne GTK palette. This installed provider
  does not expose Drive or Keep to desktop apps, so those open through their
  official web apps; Iotas synchronizes with Nextcloud, not Google.
  Keep and Drive launch in signed-in Brave app mode—no tab strip or fake sync
  bridge—and are also searchable from the app launcher.
- Hyprlock uses a larger sharp authentication console over the active Nocturne
  wallpaper, with a 12-hour `+`/`−` clock, session identity, battery/network/
  power-profile status, visible password-dot feedback, and themed auth states.
  Masked shell prompts accept direct keyboard input while keeping menu-only
  cards protected from accidental custom commands.
- Hyprland follows the start time, static durations, transitions, and full
  local-day sequence authored inside any installed GNOME dynamic-wallpaper XML
  pack. The previous SolidForest pack is available directly; its day image is
  used from morning through afternoon and its night image after the encoded
  evening transition. A large current-phase preview and clear Apply/Follow/Stop
  controls live under **Settings → Appearance**. Choosing a static image with
  `Super+W` pauses the day cycle, so the two modes never conflict.
- **Settings → Appearance** presents static wallpapers as an Ubuntu-style
  thumbnail library, keeps the active image visibly marked, and separates the
  dynamic preview from its schedule details. Save new downloads in
  `~/Pictures/Wallpapers`; the picker also includes the existing Nocturne
  collection automatically.
- Eight coordinated surface designs—Obsidian Grid, Carbon Compact, Midnight
  Circuit, Phosphor Terminal, Crimson Relay, Copper Blue, Copper Deep Green,
  and Copper Deep Gold—change shell/app surfaces and layout density without
  changing workflow or shortcuts. Sixteen independent accent colors can be
  mixed with any design. The Settings sidebar toggles between full labels and
  a remembered compact icon-only rail.
- `nocturne-doctor` performs a read-only check of the compositor, wallpaper on
  every display, notification/idle services, network, Bluetooth, PipeWire,
  brightness, power profiles, KDE Connect, fonts, and essential configuration.
- Nautilus uses a session-only Nocturne GTK layer: compact sharp controls,
  list view, dark sidebar/content and a matching selection accent. Entering
  GNOME removes that layer and restores the saved MacTahoe stylesheet.
- The tiled Nocturne visualizer includes Cyberdisc: a flat terminal frequency
  ring around a rotating record with a pickup-fed waveform trace. Four additional
  native instruments—Black ICE, Datafall, Ghostscope, and Netrunner—provide
  distinct neo-hacker layouts. Ten more native decks—Razorwire, Mainframe,
  Pulsegrid, Signal Tower, Gridlock, Zero Day, Deep Trace, Synth City, Kernel
  Panic, and Void Scanner—cover mirrored traces, rack consoles, cell matrices,
  sonar, skyline, and sparse scanner layouts. Five lighter Cava designs remain
  available in a separate classics menu. The Nocturne dashboard combines btop,
  nvtop, and a live audio spectrum in one sharp grid.
- App shortcuts for ChatGPT, VS Code, Steam, browser, files, Iotas notes, and
  Kitty.
- A sharper, theme-aware app launcher with larger icons, fuzzy search, generic
  app descriptions, and remembered launch frequency.
- Steam opens tiled, its utility dialogs float centered, and its launcher
  focuses an existing window instead of starting redundant client work. The
  hybrid-GPU path uses native NVIDIA PRIME while background shader compilation
  stays paused so the desktop remains responsive.
- Minimized windows live in a compact bar-attached shell card with app icons,
  searchable title/app metadata, original-workspace restoration, and an
  auto-hiding bar button. It never opens as a normal app or occupies a tile.
  Left-click chooses one to restore; clicking again closes it; right-click
  restores all.
- Live weather and local times for BLR, Hoodi Circle, NRI Layout, Vizag, NYC,
  Potsdam NY, and Milan. Weather refreshes every 15 minutes and retries partial
  API responses.
- Oh My Zsh + Powerlevel10k, Kitty, tmux, btop, Fastfetch, Cava, and the
  Nocturne dashboard from the earlier terminal setup.
- Explicit ACPI S3 (`deep`) suspend through systemd, including the NVIDIA
  video-memory suspend/resume hooks required by the proprietary driver. Lid
  close suspends on battery and AC power; docked lid close remains ignored.
- Laptop action keys cover microphone mute, touchpad toggle, webcam privacy
  feedback, keyboard-light levels when exposed by MSI EC, and the F7 tools key
  opens the same guide as `Super+/`. Power-profile changes are verified and
  report the actual Intel CPU policy plus MSI firmware mode instead of failing
  silently.

## Reapply or edit

The source configuration is under `config/hypr`, `config/waybar`,
`config/swaync`, and `config/wofi`. Reapply it with:

```bash
./apply-hyprland.sh
```

The script checks for required programs, snapshots any existing Hypr-related
configuration, installs these files, and keeps the Hyprland-only services from
leaking into GNOME. Hyprland's parser currently reports `config ok`.

Deep sleep is a one-time system-level setup because its policy lives under
`/etc`. Apply it through the graphical administrator prompt with:

```bash
pkexec ./configure-deep-sleep.sh
```

The installer refuses to force S3 on hardware that does not expose `deep`,
enables the NVIDIA suspend/resume integration when required, and does not
automatically suspend the live session. Save open work, then test from the
Nocturne power card or by closing the lid.

MSI keyboard-light, webcam and firmware performance controls use Ubuntu's
signed in-kernel `msi_ec` driver. Enable it only when this firmware passes the
driver's own compatibility check:

```bash
pkexec ./configure-msi-controls.sh
```

The installer makes no persistent change when the kernel rejects the firmware.

To clear only generated crash reports, the APT download cache, and old journal
history after a large debugging session, run:

```bash
pkexec ./cleanup-generated-caches.sh
```

This preserves personal files, application profiles, installed packages,
Steam data, and current logs.

## GitHub sync

Machine-local backups are intentionally excluded from Git because they can
contain private desktop state. To commit and push safe project files after an
upgrade, run:

```bash
./sync-github.sh "Describe the upgrade"
```

The helper refuses to push staged content that resembles a credential.

## GNOME recovery and backups

The verified pre-change snapshot is:

```text
backups/pre-nocturne-20260929-223449
```

`backups/current-backup` points to it. Its dconf and home-configuration archive
both pass the SHA-256 manifest. GNOME has already been restored from this
snapshot. To restore only the original GNOME/macOS appearance again while
keeping Hyprland and terminal tooling, run:

```bash
./restore-gnome-macos.sh
```

For a broader rollback of the captured user configuration, run:

```bash
./restore-gnome-backup.sh backups/current-backup
```

The broad restore requires typing `RESTORE`. Neither restore uninstalls added
packages. After restoring GNOME settings, log out and back in so every Shell
component reloads cleanly.
