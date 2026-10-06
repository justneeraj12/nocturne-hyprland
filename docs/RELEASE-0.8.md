# Nocturne 0.8 // Explainable continuity

Nocturne 0.8 makes desktop automation understandable and safe enough to leave
enabled. The shell can already react to dock, power, meeting, focus and gaming
contexts. This release adds the missing human layer: it shows what Nocturne
detected, why it selected a scene, what it changed and how to reverse it.

## Nocturne Trace

Open **Settings → Scenes & automation → Nocturne Trace**, or search Command
Center for **Explain Desktop Changes**.

Trace presents the current hardware/workflow context, the matching rule and a
small local decision history. Its event store is capped at 80 records, is mode
`0600`, and deliberately excludes application names, window titles, network
names and user content. Pausing automation also disables its systemd timer, so
the feature has no polling cost while off.

## Scene safety

Restoring a desktop scene is now a two-step operation. Preview reports how many
applications may launch, window placements and displays are involved, and how
many power, audio, wallpaper or theme settings differ. The confirmation expires
automatically. Delete uses the same guarded interaction.

Scenes now restore the saved Nocturne design preset too. Context-driven restores
remain settings-only: they never launch applications.

## Release engineering

The release gate now starts every one of the 23 on-demand QML cards in an
isolated, off-screen runtime. This catches missing required properties, imports
and component construction failures that static checks cannot see. A separate
installer contract test guarantees every binary installed by Nocturne is also
covered by rollback.

Settings now lazy-loads one section at a time. Inactive wallpaper, hardware and
diagnostic pages are released instead of keeping all 14 sections alive, reducing
the control center's private memory footprint during ordinary use.

The full gate includes a clean Qt build, Hyprland Lua verification, shell
interaction contracts, capture and portal ownership checks, packaging checks and
105 automated Python tests.

## Upgrade

Run `./install.sh` from the repository. The installer creates a new snapshot
before applying the release. Existing scenes and preferences remain in place.
Use `./uninstall.sh` and its explicit `RESTORE` confirmation to return to the
pre-install snapshot.
