# NOC 2.0 Alpha 2 — Arch portability

Alpha 2 makes NOC a two-distribution Hyprland platform instead of an
Ubuntu-shaped source tree. Nocturne 1.3 remains the stable release.

## What changed

- automatic Ubuntu/Arch detection from `/etc/os-release`;
- separate apt and pacman dependency plans;
- an AUR-free Arch path using packages from Core and Extra;
- clean-container Arch package resolution, native compilation and component CI;
- distro-aware Settings maintenance, update counts and safe cache cleanup;
- a portable Hyprpolkitagent launcher for both filesystem layouts;
- qpdfview on Ubuntu and themed Okular on Arch;
- distro-aware camera installation guidance;
- the same snapshot, rollback and encrypted Continuity contracts on both hosts.

## Install on Arch

Start from a working Hyprland 0.56+ session. NOC does not replace Hyprland.

Download the [source bundle](https://noc-operator.noc-operator.workers.dev/download/v2.0.0-alpha.2/nocturne-2.0.0-alpha.2-source.tar.gz)
and [SHA-256 checksum](https://noc-operator.noc-operator.workers.dev/download/v2.0.0-alpha.2/nocturne-2.0.0-alpha.2-source.tar.gz.sha256),
or clone the signed release tag below. The optional download redirect stores
only timestamp, two-letter country code, release and asset; direct GitHub assets
remain available on the release page.

```bash
git clone --branch v2.0.0-alpha.2 https://github.com/justneeraj12/nocturne-hyprland.git
cd nocturne-hyprland
./install.sh --dry-run
./install.sh --install-packages
```

The dependency step uses `sudo pacman -Syu --needed`, then enables
NetworkManager and Bluetooth because NOC's connectivity controls use those
system services. It does not invoke an AUR helper.

## Support boundary

Arch's package plan and native shell are validated in a clean rolling container.
Real-hardware suspend, mixed-DPI, camera and hybrid-GPU reports are still needed
before Arch can be called hardware-tested. Arch derivatives use the same adapter
but are not yet official release targets.
