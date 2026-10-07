# Community-demand feature architecture

This NOC 2.0 feature set responds to repeated requests for calendar integration,
GUI-managed window behaviour, easier onboarding, extensibility, laptop policies
and reliable multi-monitor profiles. Each subsystem follows the same constraints:

- no new resident process;
- versioned JSON at every helper/UI boundary;
- atomic private state writes;
- no user text passed to a shell;
- capability-gated controls instead of pretend buttons;
- reversible changes or explicit confirmation for deletion;
- no account credentials, calendar URLs, window titles or personal content in
  support archives.

## Connected Agenda

`nocturne-agenda` accepts an absolute local ICS path or HTTPS/webcal subscription.
Google, Outlook, iCloud, Nextcloud and other providers can expose read-only ICS
feeds without giving NOC an account password or OAuth token. The source URL is
stored mode `0600`, redacted from UI status and never logged. A bounded parser
supports all-day and timed events plus daily, weekly and monthly recurrences.

The refresh timer wakes every thirty minutes only when an enabled source exists. It uses
a five-MiB response limit, a fifteen-second timeout and the last valid cache when
a provider is temporarily unavailable. Version 1 is intentionally read-only.

## Window Rules Studio

`nocturne-window-rules` discovers open Hyprland clients and generates only a
small allowlist of actions: tile, float, workspace, opacity, monitor, size, pin
and idle inhibit. Classes and optional titles become escaped exact regular
expressions. User text cannot become Lua syntax or a command.

Generated rules live separately from the maintained base configuration and load
through `pcall`, so an invalid local file cannot prevent the desktop from
starting.

## Onboarding

The Getting Started page reports capabilities—not hardware identifiers—and
links to seven reversible steps: shell health, recovery, service profile,
display layout, shortcuts, agenda and security baseline. It does not silently
install packages or rewrite an existing configuration.

## Extensions

Contract v1 is declarative. A reviewed local manifest may open an existing NOC
surface, a credential-free HTTPS URL or an installed desktop entry. Unsupported
permissions, HTTP URLs, embedded credentials, symlinks, oversized files and all
executable payloads are rejected. See [EXTENSIONS.md](EXTENSIONS.md).

## Laptop Intelligence

Power Lab v2 keeps hardware policy in one private document. Brightness keys read
the same step and floor as Settings. The existing context timer can temporarily
select a lower supported refresh rate while discharging and restores each exact
original monitor mode on AC. Bluetooth startup is a one-shot remember/on/off
policy. Charge limits appear only when firmware exposes a writable threshold.

Context scenes, automation rules, laptop policy and display-profile switching
share one timer arbiter. Disabling any one consumer cannot stop evaluation while
another consumer still needs it.

## Display Lab

Display profiles record output names, descriptions, modes, positions, scale and
rotation. Matching uses a hash of the connected monitor set; it is not telemetry
and never leaves the machine. Automatic application reuses the existing context
timer. Live output disable refuses to turn off the final active display.

HDR controls remain status-only. Current Hyprland color-management behaviour is
still hardware and application sensitive, so NOC will not silently force an
experimental mode that can wash out the desktop or corrupt capture colors.
