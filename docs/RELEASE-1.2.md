# Nocturne 1.2 — NOC Core

Nocturne 1.2 turns the desktop from a themed collection of controls into a
measured, supervised operations workstation. It adds no resident telemetry
daemon and does not replace Linux service providers.

## Operations Deck

The bar's system control and `Super + O` open a native NOC surface with:

1. a deterministic green, amber or red node score;
2. memory and swap pressure;
3. one-minute system load;
4. package thermal state;
5. native-shell proportional memory and CPU;
6. active network link, interface and local address;
7. received and transmitted link totals;
8. power source, battery and profile;
9. portal, PipeWire and WirePlumber status;
10. competing-shell detection;
11. actionable fault summaries;
12. direct Maintenance, Settings and Doctor paths.

All collection is synchronous, bounded and active only while the card is open.

## Supervised session

`nocturne-session.target` now owns eight essential responsibilities:

- native multi-display bar;
- Hypridle lock policy;
- packaged, D-Bus-activated Mako notifications;
- PolicyKit authentication;
- privacy-aware text clipboard history;
- image clipboard history;
- wallpaper day-cycle service;
- one-shot hardware initialization.

Each long-running component has one owner, restart-on-failure behavior and
graphical-session shutdown semantics. Existing upstream service providers—
NetworkManager, BlueZ, PipeWire, WirePlumber and portals—remain authoritative.

## Enforced efficiency

`nocturne-benchmark` checks the native bar against an explicit public budget:

- at most 128 MiB proportional memory;
- at most 2% idle CPU;
- zero legacy shell competitors;
- zero failed user services.

The budget is checked by Nocturne Doctor and exercised by the shell contract
suite. It measures Nocturne, not unrelated browser tabs or application memory.

## Visual system

Five accent-aware Hyprlock compositions—Editorial, Center Signal, NOC Grid,
Phosphor Terminal and Relay Split—share the active palette and PAM path. The
Appearance page provides persistent Apply and one-unlock Try actions.
