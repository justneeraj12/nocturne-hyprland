# NOX DOC // deterministic recovery agent

NOX DOC is NOC's headless recovery controller. It can run on `tty1` with no
Wayland session, network, GPU, Python environment or language model. It pauses
the graphical NOC control plane, diagnoses the machine from direct evidence,
and exposes a very small repair allowlist before returning the machine to its
normal target.

## Why the model is not root

The optional NØX 4B model is useful for natural-language explanation while a
desktop is working, but model output is not a safe system-repair authority. A
confidently invented mount, package, filesystem or bootloader command can make
a recoverable machine unbootable.

NOX DOC therefore separates three layers:

1. **Evidence collector:** filesystem state, free space, failed systemd units,
   NOC config/binary presence and checkpoint integrity.
2. **Linux recovery knowledge pack:** curated evidence-to-action guidance that
   ships as inspectable JSON and never becomes a command.
3. **Repair executor:** compiled allow-listed operations only. It can reload
   systemd state or restore a verified NOC checkpoint; it cannot accept a shell
   command from the model.

From the ordinary NØX terminal, questions such as “why did my desktop break?”
route to NOX DOC's live diagnosis. The model may explain the result, but the
response explicitly has `root_access: false`.

## Repair a working session

NOX DOC can now operate while Hyprland is running. This path is deliberately
smaller than boot recovery: it can repair only the user-session components
that NOC can verify and restore without changing packages, disks, boot state or
personal data.

```bash
nox-doc live-diagnose | jq
nox-doc live-plan | jq
nox-doc live-repair audio
```

The live contract is always the same:

1. snapshot structured evidence from NOC Guard;
2. classify conditions as repairable or explanation-only;
3. preview the exact bounded repair and require confirmation;
4. pause only the non-essential NOC timers that were actually active;
5. execute one compiled, allow-listed repair through NOC Guard;
6. collect fresh evidence and verify the condition count did not regress;
7. resume exactly the timers that were active and write a content-free receipt.

The current live allowlist covers the NOC bar, Wayland portals, failed user
units, PipeWire/WirePlumber audio, microphone preference and wallpaper
renderer. A request outside that list is explained but not executed. There is
no arbitrary-command fallback.

From NØX, “show me the recovery plan” stays read-only. A direct request such as
“fix my audio with NOX DOC” becomes a confirmation-gated action. NØX sends only
the selected enum (`audio`, `microphone`, `portal`, `wallpaper`, `bar`,
`failed`, or `all`) to NOX DOC; it cannot supply a shell command or gain root.

Privacy-safe receipts live at
`~/.local/state/nocturne/nox-doc/live-repairs.jsonl`. They contain time, repair
target, result and before/after issue counts—not prompts, window titles,
networks, filenames, audio data or document content.

## Enter recovery

When the machine still reaches a terminal:

```bash
sudo nox-doc enter
```

This clearly warns that the graphical target will pause, requires typing
`ENTER`, then isolates `nox-doc.target` on `tty1`.

When the normal boot cannot reach a login, edit the Linux kernel line once in
the bootloader and append:

```text
systemd.unit=nox-doc.target
```

NOX DOC starts after local filesystems are available. It displays its compact
ASCII recovery-ASIC sequence, announces that other NOC work is paused, and
offers:

- reset failed control-plane state;
- restore the verified last-known-good NOC checkpoint offline;
- print the evidence-based plan;
- return to the normal default target.

It never automatically runs `fsck`, remounts a filesystem, deletes personal
files, edits a bootloader, changes encryption, or enables unrelated services.

## Check without changing anything

```bash
nox-doc diagnose --json | jq
nox-doc plan | jq
nox-doc verify
```

`diagnose`, `plan`, and `verify` are read-only. A checkpoint is rejected if its
compression is invalid or any member contains an absolute/parent-traversal
path. Offline restore still creates the same pre-restore safety archive used by
the graphical recovery flow.

## System integration

The dependency installer places:

| Path | Purpose |
| --- | --- |
| `/usr/local/sbin/nox-doc` | headless recovery controller |
| `/etc/systemd/system/nox-doc.target` | isolatable offline recovery target |
| `/etc/systemd/system/nox-doc.service` | `tty1` recovery UI |
| `/usr/share/nocturne/nox-doc-knowledge.json` | inspectable Linux recovery knowledge |
| `/etc/nocturne/nox-doc.conf` | desktop owner and home path only |

No password, prompt, SSID, document, browser content or personal identifier is
stored. The target is installed but not made the default boot target.
