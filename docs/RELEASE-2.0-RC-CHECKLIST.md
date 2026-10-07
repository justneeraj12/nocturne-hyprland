# NOC 2.0 release-candidate gate

NOC 2.0 should become a release candidate before it becomes stable. Passing
repository CI proves deterministic contracts; it does not prove boot recovery,
graphics, suspend, peripherals or a clean install across real machines.

## Required before `v2.0.0-rc.1`

- [ ] Ubuntu and Arch clean-VM install, login, update, rollback and uninstall.
- [ ] Package plans resolve from currently supported repositories.
- [ ] Fresh profile and migration from the latest stable NOC profile.
- [ ] Single display, mixed-DPI dual display, hot-plug and dock/undock.
- [ ] Intel, AMD and NVIDIA rendering smoke tests where hardware is available.
- [ ] PipeWire sink/source switching, Bluetooth reconnect and laptop-mic policy.
- [ ] Portal screen sharing in a browser and Discord-compatible client.
- [ ] Lock, unlock, suspend, deep-sleep resume and lid behavior on the reference laptop.
- [ ] Screenshot, screen recording and clipboard round trips.
- [ ] Driverless printer and AirScan discovery with absence handled cleanly.

## NOX DOC fault-injection matrix

- [ ] Live bar, portal, audio, microphone and wallpaper faults are each detected,
      previewed, confirmed, repaired and re-diagnosed.
- [ ] Cancelled live repair changes nothing.
- [ ] Unsupported conditions cannot cross the allowlist boundary.
- [ ] Active NOC timers resume; initially inactive timers remain inactive.
- [ ] Receipts stay mode `0600` and contain no content, paths or prompts.
- [ ] `nox-doc.target` boots without network, Wayland, GPU or model runtime.
- [ ] Missing, valid, corrupt and path-traversing checkpoints are handled safely.
- [ ] Root read-only and disk-below-5% cases refuse checkpoint restore.
- [ ] Offline restore preserves ownership/mode and creates a pre-restore archive.
- [ ] Repeated service failure cannot create an unbounded repair loop.

## Stable `v2.0.0` gate

- [ ] One week of RC use on the reference laptop without a severity-one failure.
- [ ] At least one clean install report from Ubuntu and one from Arch.
- [ ] Accessibility pass: keyboard-only operation, focus order, contrast and scale.
- [ ] Threat review of installer, continuity, update guard and NOX DOC boundaries.
- [ ] Release bundle checksum, reproducibility and rollback instructions verified.
- [ ] Known limitations and supported hardware matrix are published.

A failed box blocks stable promotion; it does not block another RC. Emergency
recovery remains deterministic and conservative even if the optional NØX model
is unavailable.
