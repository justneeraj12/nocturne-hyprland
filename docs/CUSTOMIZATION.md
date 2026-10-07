# Customization

Nocturne keeps machine-specific preferences in small files and scripts rather
than forking the shell UI.

## Monitors

On first install, Nocturne reads the active Hyprland outputs and writes:

```text
~/.config/nocturne/monitors.lua
```

That keeps the refresh rates, positions and scales already working in the
current session. Edit this small file for a different permanent layout; a
catch-all preferred-mode rule handles newly connected displays. Delete the
file and run `./install.sh` from the desired live layout to detect it again.
The native Displays card can extend, mirror, scale and rotate outputs live;
choose **Save Layout** only after the arrangement looks correct.

## Night Shift

Brightness controls include manual warm presets and a timed Hyprsunset mode.
The default schedule is neutral at 07:00, 4500 K at 19:00 and 3600 K at 22:30.
Edit `~/.config/hypr/hyprsunset.conf` to change those times or temperatures.

## Wallpapers

Put static images in:

```text
~/Pictures/Wallpapers
```

They appear in **Nocturne Settings → Appearance**. Selecting a static image
pauses the dynamic cycle. Dynamic GNOME XML wallpaper packs keep their authored
morning/day/evening/night timing.

## Presets and accents

The Settings app exposes these design presets without changing shortcuts or
workflow:

- Obsidian Grid
- Carbon Compact
- Midnight Circuit
- Phosphor Terminal
- Crimson Relay
- Copper Blue
- Copper Deep Green
- Copper Deep Gold

Sixteen accents are available from the same page. Changes begin as a 30-second
preview: choose **Keep** or let Nocturne restore the old palette automatically.
Theme Studio can derive an accent from the active wallpaper and save named
custom themes under `~/.config/nocturne/themes`.

## Lock screen styles

**Settings → Appearance → Lock Screen Style** includes ten layouts: Editorial,
Center Signal, NOC Grid, Phosphor Terminal, Relay Split, Black Ice, Red Sector,
Signal Tower, Mainframe and Dead Channel. **Apply** makes a style persistent.
**Try** locks the session once with that layout and restores the previous style
immediately after a successful unlock. Every layout uses the active Nocturne
accent and the same PAM-backed Hyprlock authentication path.

The same card controls wallpaper treatment (**Void**, **Dim**, **Balanced** or
**Vivid**) and clock notation (**Operator**, conventional 12-hour or 24-hour).
Operator notation keeps Nocturne's `+` AM and `−` PM markers.

The selected style is stored privately in
`~/.config/nocturne/lock-style.json`; rendered Hyprlock configuration is rebuilt
when the session locks, so theme and accent changes stay synchronized.

## Terminal identity

Fastfetch uses the grand framed NOC wordmark. Run `nocturne-banner` for the same
identity plus live node, session and uptime state. It automatically chooses a
compact mark in narrow terminal splits; `--grand`, `--compact` and `--plain`
provide explicit output for screenshots, scripts and dotfiles.

## Scenes and context automation

Open **Settings → Scenes + Automation** to save the current applications,
workspace placement, monitors, wallpaper, power profile and audio defaults.
Restoring a scene may relaunch its known desktop applications. Context rules
for docked, mobile, AC and battery states use `settings-only` mode and never
launch applications automatically. They are checked by a 30-second systemd
timer, so there is no persistent polling process.

Audio scenes remember output/input devices, master levels, active application
levels and the selected EasyEffects preset. The Meeting action always prefers
the laptop microphone but leaves output routing switchable.

## World clocks and weather

Edit:

```text
~/.config/nocturne/locations.json
```

The current-location row uses a coarse IP lookup, caches only city/region,
country, coordinates and timezone for six hours, and retains the last good
result while offline. Disable it with:

```json
{
  "current_location": {
    "enabled": false
  }
}
```

The remaining manually configured cities continue working normally.

## Default applications

The reference setup uses the Nocturne-styled Dolphin profile for folders,
qpdfview on Ubuntu or Okular on Arch for PDFs, and Qalculate-Qt for
calculations. Change defaults with `xdg-mime` if you prefer other applications;
the shell does not require those exact choices.

## Portable preferences

**Settings → Setup + Recovery** exports theme state, accents, locations, wallpaper
selection, saved monitor layout and Night Shift configuration. The archive does
not include Wi-Fi secrets, passwords, browser profiles or wallpaper images.

## Keybindings

Bindings live in `~/.config/hypr/hyprland.lua`. Keep `Super + /` available as
the discoverability shortcut if you change the rest, and update
`~/.config/hypr/KEYS.md` so the on-screen guide remains truthful.

## Application rules

Nocturne tiles normal application windows. Dialogs and transient Steam windows
may float when that produces a more usable result. Add application-specific
rules at the bottom of `hyprland.lua` after confirming the real class with:

```bash
hyprctl clients
```
