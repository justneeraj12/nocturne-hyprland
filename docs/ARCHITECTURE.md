# Architecture

Nocturne is a desktop layer, not a replacement operating system and not a
private Hyprland fork.

## Process model

`nocturne-native` is a C++/Qt Quick application with three roles:

1. one long-running bar process for every active monitor;
2. one settings window when Settings is open;
3. one layer-shell card process that exits when dismissed.

Card requests use a local socket. Invoking the same surface twice closes it;
invoking another surface changes the existing owner rather than stacking
another popup. The full-screen transparent layer exists only while a card is
open and provides consistent outside-click dismissal.

## System ownership

Nocturne renders controls but does not invent parallel services:

| Capability | Source of truth |
| --- | --- |
| Audio and application streams | PipeWire / WirePlumber |
| Wi-Fi and VPN | NetworkManager |
| Bluetooth | BlueZ |
| Brightness | kernel backlight sysfs / brightnessctl |
| Power policy | power-profiles-daemon |
| Notifications | Mako |
| Clipboard history | Cliphist |
| Screenshots | Hyprshot, grim and slurp |
| Screen recording | Kooha and the XDG ScreenCast portal |

This is why hardware keys and external changes remain authoritative while a
card is open.

## Toolkit boundary

Nocturne's own shell contains no GTK imports. Qt 6 and LayerShellQt provide the
native Wayland UI. External applications may use any toolkit; Kooha, Steam,
browsers and editor windows are not reimplemented inside the shell.

## Performance choices

- Cards are demand-loaded and terminate after dismissal.
- Expensive PipeWire stream discovery runs only while the audio card is open.
- Brightness is read from sysfs while the display card is visible.
- Weather and current-location data are cached.
- Monitor geometry is captured once into a user-owned override, not hard-coded
  into the public Hyprland configuration.
- The bar uses one StatusNotifier watcher instead of launching applet stacks.
- Cava and the dashboard are user-launched, never idle background services.

Nocturne avoids marketing a fixed RAM number because GPU drivers, Flatpak
portals, connected displays and tray applications dominate real-world variance.
Use `nocturne-doctor`, `systemd-cgtop` and the included dashboard to measure the
actual machine.

## Extension points

- Add a card under `native/qml/pages/` and register it in `Shell.qml`.
- Add trusted backend access in `native/src/backend.cpp` with explicit argument
  lists rather than interpolated shell strings.
- Put hardware- or distribution-specific behavior in an optional script, not
  in the portable UI.
- Add every invariant to `scripts/validate-nocturne.sh` and CI.
