# Launch and community plan

This document is a rollout plan, not an instruction to spam communities. Each
post should be adapted to the venue, disclose the tested platform honestly and
stay available for support after publishing.

## Positioning

**Name:** Nocturne Hyprland

**One line:** A sharp, native control plane for Hyprland—tiling speed with the
desktop controls people miss when they leave GNOME.

**Three proof points:**

1. one Qt/Wayland shell instead of several independently themed widget stacks;
2. live state from NetworkManager, BlueZ, PipeWire, sysfs and power profiles;
3. reversible install, read-only diagnostics and a normal-app escape hatch.

Avoid unsupported claims such as “zero RAM,” “works on every distro” or
“production-ready on all hardware.” The honest initial claim is: reference
tested on Ubuntu 26.04, Hyprland 0.56.2, two displays and an NVIDIA laptop.

## Before going public

- [ ] merge the release branch into `main`;
- [ ] change repository visibility from private to public;
- [ ] set the description and GitHub topics;
- [ ] confirm CI passes from a clean runner;
- [ ] perform one clean install in a disposable user or VM;
- [ ] open and close every card at both display edges;
- [ ] verify install, update and rollback docs;
- [ ] create a signed `v0.1.0` release with a short changelog;
- [ ] enable Discussions if support traffic warrants it.

Suggested GitHub topics:

```text
hyprland wayland qt6 qml linux-desktop dotfiles ubuntu ricing layer-shell
```

## Rollout sequence

### 1. Soft launch

Share first in the Hyprland Discord showcase and `r/hyprland`. Ask specifically
for feedback on install friction, multi-monitor behavior and non-reference
hardware. Fix the first reproducible issues before a larger post.

### 2. Visual launch

Post the hero image to `r/unixporn` with the required details in the first
comment: OS, compositor, bar, terminal, shell, editor, wallpaper, fonts and
dotfiles link. Use “Nocturne — Qt-native controls for Hyprland” as a descriptive
title rather than clickbait.

### 3. Developer launch

Publish a concise Show HN-style or Lobsters post only if there is a technical
story worth discussing: the single-owner layer-shell process, authoritative
backend state and reversible installer. Lead with architecture, not aesthetics.

### 4. Durable discovery

After the first release settles, submit a focused PR to an appropriate Awesome
Hyprland/dotfiles list. Share updates on Mastodon or Bluesky only for meaningful
releases rather than every commit.

## Ready-to-adapt post

> I built Nocturne, a Qt 6/Wayland desktop layer for Hyprland. It keeps the
> tiling workflow but adds the controls I missed from a full desktop: coherent
> Wi-Fi/Bluetooth/VPN, live per-app audio, brightness that follows hardware
> keys, power profiles, notifications, clipboard history and a real settings
> app. The cards are on-demand, the system services remain the source of truth,
> and the installer snapshots the previous config for rollback. The first
> supported target is Ubuntu 26.04 + Hyprland 0.56. Feedback on other hardware
> and display layouts is very welcome.

Attach `docs/screenshots/hero.webp`, then link the repository and installation
guide. Do not attach screenshots containing the developer's browser, messages,
accounts, network names or terminal history.

## Content cadence

- **Launch:** hero, quick-controls grid and the one-line value proposition.
- **Week one:** a short architecture note and fixes learned from real installs.
- **First release:** before/after workflow video, changelog and supported matrix.
- **Later:** contributor screenshots and hardware profiles—with permission.

Success is not raw stars. Track successful installs, actionable bug reports,
new hardware coverage, outside contributions and the percentage of issues that
include reproducible diagnostics.
