<p align="center">
  <img src="docs/screenshots/noc-banner.webp" alt="NOC — Nocturne Operations Console" width="100%">
</p>

<h1 align="center">NOC // NOCTURNE</h1>

<p align="center">
  A sharp, native control plane for Hyprland.<br>
  Tiling speed, desktop-grade controls, zero shell-framework sprawl.
</p>

<p align="center">
  <a href="https://github.com/justneeraj12/nocturne-hyprland/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/justneeraj12/nocturne-hyprland/ci.yml?branch=main&style=flat-square&label=build" alt="Build status"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-6d9578?style=flat-square" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/Hyprland-0.56%2B-6d9578?style=flat-square" alt="Hyprland 0.56 or newer">
  <img src="https://img.shields.io/badge/Ubuntu-26.04-cb8d62?style=flat-square" alt="Tested on Ubuntu 26.04">
</p>

**NOC**—the **Nocturne Operations Console**—turns a working Hyprland
installation into a coherent desktop without
turning it into a pile of unrelated widgets. Its bar, launcher, settings and
quick controls are built with Qt Quick and Wayland layer shell; the real work
stays with standard Linux services such as NetworkManager, BlueZ, PipeWire and
power-profiles-daemon.

It is designed for people who want a dark, compact rice and still expect
brightness keys, Bluetooth audio, per-app volume, notifications, clipboard
history, power modes, screenshots and screen recording to behave normally.

> **Reference platform:** Ubuntu 26.04, Hyprland 0.56.2 and Qt 6.10. The source
> requires Hyprland 0.56+ and Qt 6.6+. Other distributions are welcome, but the
> packaged dependency installer currently targets Ubuntu.

## Why this one?

| Difference | What it means in practice |
| --- | --- |
| **One native shell** | A single Qt 6 binary owns the bar and on-demand cards—no Waybar + Eww + AGS stack to theme and debug separately. |
| **Zero-idle popovers** | Audio, network, power and workflow cards exist only while visible, then exit cleanly. |
| **Event-driven state** | Hyprland, PipeWire, MPRIS, NetworkManager, BlueZ, UPower, backlight and tray events update one native shell core without a farm of polling widgets. |
| **Desktop muscle memory** | Click to open, click again or outside to dismiss, hardware keys show compact native OSD feedback, and ordinary apps tile normally. |
| **One searchable control center** | Appearance, hardware, defaults, accounts, automation and recovery live in one responsive Settings app with no dead control-center duplicates. |
| **Laptop-first details** | Bluetooth output auto-routing, laptop-mic preference, live brightness sync, caffeine, deep-sleep tooling and power profiles are included. |
| **Reversible by design** | The installer snapshots existing desktop config, diagnostics are read-only, and rollback is a supported path—not an afterthought. |

## The desktop

<p align="center">
  <img src="docs/screenshots/quick-controls.webp" alt="Nocturne launcher and quick controls" width="92%">
</p>

<details>
<summary><strong>See the launcher at full size</strong></summary>

![Nocturne application launcher](docs/screenshots/launcher.webp)

</details>

The shell includes:

- a multi-monitor bar with workspaces, media, weather, system state and tray;
- Bar Studio with per-display density and module visibility, icon scale and layout controls;
- Wi-Fi, Bluetooth and VPN control through NetworkManager and BlueZ;
- master volume, output routing and live per-application PipeWire streams;
- hardware-synchronized brightness and microphone state;
- a command-center launcher for apps, running windows and safe desktop actions;
- a nine-workspace overview plus restorable desktop and audio scenes;
- launcher favorites, recent apps, local file search and inline calculations;
- searchable notification history, timed focus modes, clipboard history, minimized apps and a DBusMenu-aware background-app switcher;
- per-app timed notification muting, grouped alerts and verification-code copying;
- live privacy and gaming dashboards with on-demand sensor/GPU inspection;
- calendar, world clocks/weather, Pomodoro, caffeine and power/session controls;
- Hyprshot screenshots and Kooha screen recording;
- dynamic day-cycle wallpapers, eight design presets and sixteen accents;
- scheduled Night Shift, live display scaling/rotation/mirroring and saved layouts;
- fail-closed NVIDIA PRIME offload for Steam and every game it launches;
- automatic gaming sessions that apply performance, caffeine and focus, then restore the exact prior state;
- apt, Flatpak, firmware and failed-service status in one maintenance card;
- hardware-aware setup profiles plus portable preference export and restore;
- one searchable native Settings app with overview, live hardware state, appearance, devices, defaults, accounts, integrations and guarded recovery;
- a compact dark Files profile with tabs, split view, rich previews, network/removable mounts and zero-idle indexing;
- dock, power, meeting, focus and gaming context automation, guarded theme previews and last-known-good recovery;
- coordinated Kitty, tmux, btop, Cava and NOC-branded Fastfetch defaults.

More images are in the [showcase](docs/SHOWCASE.md).

![Nocturne lock screen](docs/screenshots/lockscreen.webp)

## Install

Start from a working **Hyprland 0.56+ session** on Ubuntu. Nocturne configures
the desktop around Hyprland; it does not install the compositor itself.

```bash
git clone https://github.com/justneeraj12/nocturne-hyprland.git
cd nocturne-hyprland
./install.sh --install-packages
```

If the runtime and build dependencies are already installed:

```bash
./install.sh
```

Then log out once and select **Hyprland (uwsm-managed)**. On later updates,
pull and run `./install.sh` again. The installer is idempotent and creates a
fresh pre-install snapshot every time.

Before changing the live session, you can build and validate the tree with:

```bash
./install.sh --dry-run
```

Read the complete [installation, update and rollback guide](docs/INSTALL.md)
before installing on a machine with an existing custom rice.

## Essential controls

| Action | Shortcut |
| --- | --- |
| Launch an app | `Super + Space` |
| Workspace overview | `Super + Tab` |
| Session scenes | `Super + Shift + Tab` |
| Open terminal | `Super + Enter` |
| Open Nocturne Settings | `Super + R` |
| Show the full key guide | `Super + /` |
| Close / minimize | `Super + Q` / `Super + M` |
| Switch workspace | `Super + 1…9` |
| Move window to workspace | `Super + Shift + 1…9` |
| Power and session | `Super + P` |
| Area / window / display screenshot | `Print` / `Shift + Print` / `Ctrl + Print` |
| Screen recorder | `Super + Print` |

The full reference is available inside the desktop and in
[`config/hypr/KEYS.md`](config/hypr/KEYS.md).

## How it fits together

```text
bar clicks + hotkeys
         │
         ▼
nocturne-native (Qt Quick + LayerShellQt)
         │  one local IPC owner; cards exit when dismissed
         ├── PipeWire / WirePlumber     audio + app streams
         ├── NetworkManager / BlueZ     Wi-Fi + VPN + Bluetooth
         ├── sysfs / brightnessctl      hardware backlight
         ├── power-profiles-daemon      power policy
         ├── Mako / Cliphist            notifications + clipboard
         ├── Hyprshot                   screenshots
         └── Kooha / XDG portal         screen recording
```

Nocturne does not replace those services. It gives them one compact,
consistent interface. See the [architecture notes](docs/ARCHITECTURE.md) for
process ownership, performance choices and extension points.

Some freedesktop backends intentionally remain: Hyprland's portal owns screen
sharing, KDE supplies the file chooser Hyprland's portal does not implement,
Secret Service stores application credentials, and GVfs exposes configured
Google accounts. None of those owns a panel, launcher or settings window.

## Personalize it

Open `Super + R` to change wallpapers, design presets and accents. Machine and
city-specific values live in ordinary files rather than hard-coded QML:

- `~/.config/nocturne/locations.json` — world clocks and weather;
- `~/Pictures/Wallpapers` — static wallpaper library;
- `~/.config/nocturne/theme.json` — active preset and shell density;
- `~/.config/nocturne/accent.css` — current accent colors.

See [customization](docs/CUSTOMIZATION.md) for monitors, applications, themes,
wallpapers and location privacy.

## Reliability

```bash
# source build, config verification and the local agent suite
./scripts/validate-nocturne.sh

# read-only live desktop health check
nocturne-doctor
```

The local validator performs a clean Qt build and verifies the live Hyprland
Lua provider. CI repeats the clean build, checks packaging and capture
invariants, and rejects GTK imports in Nocturne's own native UI. Third-party
applications keep their own toolkit and license.

## Project

- [Install and rollback](docs/INSTALL.md)
- [Showcase](docs/SHOWCASE.md)
- [NOC identity](branding/README.md)
- [Customization](docs/CUSTOMIZATION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Launch and community plan](docs/LAUNCH.md)
- [Experimental NØX local agent](agent/README.md) — optional and not installed by default
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

Nocturne is MIT licensed. If the idea resonates, try it, open a focused issue,
or share a screenshot of your own palette and hardware profile.
