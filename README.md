# Nocturne — Hyprland desktop with a GNOME safety net

This machine now has two independent desktop sessions:

- **Hyprland (uwsm-managed):** keyboard-first Tokyo Night tiling, compact
  Waybar, no compositor title bars, notification history, clipboard history,
  Caffeine, Pomodoro, media controls, audio/network/Bluetooth controls,
  resource tools, a session-local neutral dark app theme, and a matching
  terminal setup.
- **Ubuntu / GNOME:** restored to the original MacTahoeCompact-Dark setup,
  including its MacTahoe icons, left-side window controls, extensions, and
  SolidForest wallpaper.

Steam, VS Code, ChatGPT, browsers, PipeWire audio, and the Intel/NVIDIA gaming
stack were not replaced. They run as ordinary applications in either session.

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
- SwayNotificationCenter for application-independent notification history and
  do-not-disturb mode.
- Cliphist clipboard picker; screenshot-to-file-and-clipboard actions.
- Caffeine toggle backed by Hypridle, with 10-minute lock and 15-minute screen
  sleep when Caffeine is off.
- A 25/5 Pomodoro timer in the bar.
- A minimal Omarchy-style bar with MPRIS, audio, network, Bluetooth, grouped
  system health, microphone-use, notification, clock, and collapsed background
  apps. Audio, Wi-Fi, Bluetooth, media, KDE Connect, and power open compact
  click-to-toggle cards directly beneath their buttons. A themed clock card
  combines every saved world time, live weather, Pomodoro, and caffeine. The
  Hyprland-native Nocturne Settings card replaces GNOME Settings, which cannot
  run outside GNOME. Audio includes per-app volume; KDE Connect uses a matching
  dark Qt6 theme. Detailed process data lives in the resource dashboard.
- The tiled Nocturne visualizer includes Cyberdisc: a flat terminal frequency
  ring around a rotating record with a pickup-fed waveform trace. Five lighter Cava
  designs—Obsidian, Matrix, Amber, Ice, and Wave—remain available. The Nocturne
  dashboard combines btop, nvtop, and a live audio spectrum in one sharp grid.
- App shortcuts for ChatGPT, VS Code, Steam, browser, files, Iotas notes, and
  Kitty.
- Steam opens tiled, its utility dialogs float centered, and its launcher
  focuses an existing window instead of starting redundant client work. The
  hybrid-GPU path uses native NVIDIA PRIME while background shader compilation
  stays paused so the desktop remains responsive.
- Live weather and local times for BLR, Hoodi Circle, NRI Layout, Vizag, NYC,
  Potsdam NY, and Milan. Weather refreshes every 15 minutes and retries partial
  API responses.
- Oh My Zsh + Powerlevel10k, Kitty, tmux, btop, Fastfetch, Cava, and the
  Nocturne dashboard from the earlier terminal setup.

## Reapply or edit

The source configuration is under `config/hypr`, `config/waybar`,
`config/swaync`, and `config/wofi`. Reapply it with:

```bash
./apply-hyprland.sh
```

The script checks for required programs, snapshots any existing Hypr-related
configuration, installs these files, and keeps the Hyprland-only services from
leaking into GNOME. Hyprland's parser currently reports `config ok`.

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
