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

## Meet or Discord's share chooser tiles or disappears

Nocturne uses the upstream `hyprland-share-picker` supplied by
xdg-desktop-portal-hyprland. The compositor rule keeps this trusted chooser
compact, centered, floating and pinned above the meeting without making the
rest of the desktop modal.

```bash
systemctl --user status xdg-desktop-portal-hyprland.service
hyprctl clients | sed -n '/hyprland-share-picker/,+12p'
```

Choose **Application Window** when you want the least exposure, or **Entire
Display** when demonstrating a complete workspace. If an older session still
tiles the chooser, run `hyprctl reload`; restart the portal only when no screen
share is active.

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

## Signal asks for GNOME or reports an unreadable database

Electron chooses its encrypted-storage backend from the desktop name. Hyprland
is not a password-store name, so launching the native package directly can make
a healthy Signal database look unreadable. Nocturne's Signal launcher forces
the unlocked GNOME Secret Service for the native package. If a linked Flatpak
profile already exists, it is preserved and opened instead of silently starting
a separate empty profile.

Choose a backend explicitly only when needed:

```bash
printf 'native\n' > ~/.config/nocturne/signal-backend
# or: printf 'flatpak\n' > ~/.config/nocturne/signal-backend
```

Never delete either profile merely to resolve the password-store warning.

## Report a bug

Include:

- Ubuntu, Hyprland and Qt versions;
- the smallest repeatable sequence;
- relevant `nocturne-doctor` lines;
- whether the issue survives a clean logout/login.

Never attach account pages, clipboard contents, private notifications, tokens
or machine backups.
