# NOC 2.0 // First Signal

NOC 2.0 is the first stable release of Nocturne as an installable Hyprland
desktop platform. It keeps Hyprland as the compositor and standard Linux
services as the hardware backends, while one Qt Quick control plane owns the
bar, cards, launcher, Settings, overview and operational surfaces.

## Install

```bash
git clone --branch v2.0.0 --depth 1 https://github.com/justneeraj12/nocturne-hyprland.git
cd nocturne-hyprland
./install.sh
```

The guided terminal path detects Ubuntu or Arch, shows its intended scope,
offers validation or a full dependency install, and requires an explicit
`INSTALL` confirmation. Existing desktop configuration is snapshotted before
the live profile changes. The first NOC login opens a one-shot terminal welcome
with health, shortcut, workflow and recovery guidance.

## Stable foundations

- one native multi-monitor Qt shell with zero-idle popovers;
- familiar outside-click/card-toggle behavior and searchable settings;
- deterministic launcher controls, scenes and explainable automation;
- PipeWire routing, per-app audio, Bluetooth switching and laptop-mic policy;
- Hyprland portals, screenshots, recording and meeting-safe sharing;
- lock compositions, wallpaper cycles, accent palettes and dimensional NOC art;
- private Desk, Habits, Vault, clipboard and Connected Agenda workflows;
- Laptop Intelligence, Display Lab, Storage, Security and Campus controls;
- encrypted transport-neutral continuity without an NOC cloud account;
- reversible Update Guard, checkpoints and a minimal recovery login.

## NOX DOC

NOX DOC operates without the optional NØX language model. At boot it can run on
`tty1` through `nox-doc.target`, inspect direct evidence and restore only a
verified NOC checkpoint. During a working session it can diagnose the bar,
portals, failed user units, audio, microphone preference and wallpaper path.

Live repair is confirmation-gated and enum-only. It snapshots evidence, pauses
only active non-essential NOC timers, executes an allow-listed repair,
re-diagnoses the exact selected fault, restores those timers and writes a
content-free mode-0600 receipt. NØX can request this interface but has neither
arbitrary shell nor root authority.

## Installation confidence

The release gate includes:

- clean C++/QML builds and component tests on Ubuntu and Arch runners;
- official-repository Arch package resolution and Ubuntu package contracts;
- deterministic shell, privacy, installer and rollback tests;
- a clean-home install that builds the shell, applies every public manifest,
  creates a checkpoint, validates First Signal, and restores the original home;
- 113 local-agent policy, planner, tool and verification tests;
- a live reference-laptop NOX DOC repair from one failed unit to zero.

## Support contract

Ubuntu 26.04 is hardware-tested on the reference MSI laptop. Current Arch is
package-resolved and native-build tested in CI. Both require Hyprland 0.56+,
Qt 6.6+, systemd user services and PipeWire/WirePlumber. Other distributions
may work but are not described as supported by this release.

NOC does not delete personal files, browser profiles, Steam data or GNOME. It
does not collect analytics, prompts, SSIDs, application content or a device
identifier. Optional privileged hardware helpers remain separate and opt-in.

## Update and rollback

```bash
git pull --ff-only
./install.sh --user-only

# Restore the original pre-NOC desktop profile
./uninstall.sh
```

See [Install, update and rollback](INSTALL.md), [NOX DOC](NOX-DOC.md), and the
[support matrix](SUPPORT-MATRIX.md) for the complete operational contract.
