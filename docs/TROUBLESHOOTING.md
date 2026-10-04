# Troubleshooting

Start with the read-only health check:

```bash
nocturne-doctor
```

It verifies the native binary, Hyprland provider, bar, portals, notifications,
tray owner, audio, backlight, networking, Bluetooth, power profile, lock/PAM,
screenshots, recorder, wallpaper coverage and deep sleep.

## The bar or a card is stale

```bash
hyprctl reload
pkill -f '^.*/nocturne-native bar$'
```

The existing bar supervisor starts one clean replacement. Rebooting should not
be necessary.

## A screenshot selector does not appear

```bash
hyprshot --help
command -v grim slurp wl-copy
```

`Print` selects an area, `Shift + Print` selects a window and `Ctrl + Print`
selects a monitor. Nocturne intentionally does not wrap Hyprshot in another UI.

## Kooha cannot start recording

Confirm the recorder and both portal backends:

```bash
flatpak info --user io.github.seadve.Kooha
systemctl --user status xdg-desktop-portal-hyprland.service
systemctl --user status plasma-xdg-desktop-portal-kde.service
```

Log out and back in after changing portal configuration. Wayland portal state
is session-scoped and is often not repaired by reopening only the application.

## Audio does not switch to Bluetooth

```bash
systemctl --user status nocturne-audio-autoswitch.service
wpctl status
```

The service prefers a newly connected Bluetooth sink but leaves the laptop
microphone as the default input. Both remain manually selectable.

## Brightness changes but the card does not move

Run `brightnessctl -m`. If it reports no device, the kernel is not exposing a
supported backlight. If it reports the right percentage, close and reopen the
card and include `nocturne-doctor` output in a bug report.

## Hyprlock rejects every password

Check that `/etc/pam.d/hyprlock` exists and that `hyprpolkitagent` is running.
Do not weaken PAM configuration to make the lock screen appear functional.

## Verify that Steam games use NVIDIA

Nocturne places a verified `steam` wrapper in `~/.local/bin` and adds that
directory to the managed user-session path. Steam-generated game shortcuts and
the Nocturne launcher therefore share one PRIME offload path.

```bash
steam --verify-gpu | jq
nvidia-smi
```

Verification must report `ok: true`, the NVIDIA renderer and available 32-bit
libraries. On hybrid laptops, leave Ubuntu PRIME in **on-demand** mode;
Nocturne keeps the desktop on the integrated GPU and offloads Steam and its
child games. If the GPU exists but its driver is unavailable, Steam is blocked
instead of silently launching games on Intel.

## Report a bug

Include:

- Ubuntu, Hyprland and Qt versions;
- the smallest repeatable sequence;
- relevant `nocturne-doctor` lines;
- whether the issue survives a clean logout/login.

Never attach account pages, clipboard contents, private notifications, tokens
or machine backups.
