# Install, update and rollback

Nocturne targets people who already have Hyprland running and want to apply the
complete desktop layer. The Ubuntu helper installs build/runtime dependencies;
it intentionally does not replace the distribution's Hyprland package.

## Requirements

- Ubuntu 26.04 or a compatible Ubuntu development base
- Hyprland 0.56 or newer, launched through UWSM
- systemd user services and PipeWire/WirePlumber
- a working network connection during the first install
- `sudo` access only for the optional apt dependency step

The shell itself runs entirely as the logged-in user. Deep-sleep and MSI
hardware helpers are separate, opt-in scripts because they change system-wide
policy.

## Install

```bash
git clone https://github.com/justneeraj12/nocturne-hyprland.git
cd nocturne-hyprland
./install.sh --install-packages
```

The command installs Ubuntu packages, checksum-verifies Hyprshot, installs
Kooha from Flathub, installs Hyprsunset and fwupd support, builds the Qt shell
in release mode and applies the config.

Already have every dependency?

```bash
./install.sh
```

Log out after the first installation and choose **Hyprland (uwsm-managed)**.
The next login starts the bar, wallpaper engine, notifications, idle manager,
clipboard watchers and hardware helpers.

## What changes

User-owned files are installed below:

- `~/.config/hypr`, `~/.config/nocturne`, `~/.config/mako`;
- selected Kitty, tmux, btop, Cava and Qt configuration;
- `~/.local/bin/nocturne-*`;
- `~/.local/share/applications` and `~/.local/share/backgrounds`;
- selected systemd user units and XDG portal configuration.

Before applying those files, the installer snapshots existing desktop config
under `~/.local/state/nocturne/backups/`. It does not delete browser profiles,
Steam data, documents, downloads, application accounts or the GNOME session.

## Validate first

```bash
./install.sh --dry-run
```

This performs a clean C++/QML build, verifies the Hyprland Lua config, checks
JSON and scripts, and runs the local agent test suite without installing
packages or applying config.

## Update

```bash
git pull --ff-only
./install.sh
```

Each application creates another timestamped snapshot. Local wallpaper,
palette and theme state is preserved where the installer treats the file as
user-owned.

## Roll back

```bash
./uninstall.sh
```

The rollback script shows the snapshot it will restore and requires an explicit
`RESTORE` confirmation. It saves the current Nocturne config first, restores
the original pre-Nocturne shell configuration, disables Nocturne services and
leaves apt packages, Hyprshot and Kooha installed for safety.

To choose a particular snapshot:

```bash
./uninstall.sh ~/.local/state/nocturne/backups/pre-hyprland-YYYYMMDD-HHMMSS
```

Log out after rollback so the restored session owns its portals and shell
processes from a clean start.

## Optional system helpers

Review these before authorizing them:

```bash
pkexec ./configure-deep-sleep.sh
pkexec ./configure-msi-controls.sh
```

They are deliberately excluded from the normal installer because firmware,
sleep modes and embedded-controller behavior differ across machines.

## First-run profile and portable backup

Open **Nocturne Settings → Setup + Backup** after the first login. Hardware
detection recommends a desktop or laptop profile; the choice changes only
optional background services and never removes the core shell. The same page
exports a portable preferences bundle under `~/Documents/Nocturne-Backups`.
Bundles intentionally exclude passwords, network credentials, browser data and
wallpaper files.
