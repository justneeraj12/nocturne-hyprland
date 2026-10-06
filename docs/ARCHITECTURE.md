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
| Sensitive clipboard filtering and pins | Nocturne on-demand helper + systemd transient expiry |
| Screenshots | Hyprshot, grim and slurp |
| Screen recording | Kooha and the XDG ScreenCast portal |
| Meeting screen sharing | Hyprland XDG ScreenCast portal + PipeWire |
| File chooser | KDE XDG portal backend |
| Application secrets | freedesktop Secret Service via GNOME Keyring |
| Existing Google mounts | GVfs / GNOME Online Accounts backend |
| Phone integration | KDE Connect daemon |
| Nocturne Files | Dolphin with scoped KDE styling and Baloo disabled |
| Storage accounting | `df`, `du` and explicit user-selected cleanup targets |
| System automation | Existing Nocturne context timer + bounded local rules |

This is why hardware keys and external changes remain authoritative while a
card is open.

The last four are compatibility services, not desktop-shell owners. Hyprland's
portal does not implement a file chooser, Secret Service is the API used by
Signal and other applications, and removing GVfs/GOA would disconnect the
accounts already configured by the user. Nocturne Settings identifies these
dependencies explicitly while remaining the only visible system control app.

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
- Audio subscription events are coalesced and client lifecycle noise is ignored,
  preventing the bar's own status probes from creating a PipeWire event loop.
- Active XDPH capture nodes are detected through their upstream
  `xdph-streaming-*` identity; idle camera hardware is not presented as an
  application capture, and the portal itself is never terminated as a client.
- Desktop-file discovery runs only in the on-demand launcher, never in the bar.
- The Efficiency Center samples pressure and process data only while its page is
  visible. Its safe cleanup is explicit and limited to old regenerable
  thumbnails, old user journal entries and failed-unit state.
- Cava and the dashboard are user-launched, never idle background services.
- Storage, permissions, Guard, Meeting Mode, Power Lab, clipboard pins and NOC
  Pulse are short-lived commands. Automation and adaptive battery policy reuse
  `nocturne-context.timer`. Clipboard privacy replaces the existing Cliphist
  text watcher; the release adds no second watcher or permanent daemon.

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
