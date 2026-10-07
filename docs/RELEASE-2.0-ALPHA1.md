# NOC 2.0 Alpha 1 — Foundation

This prerelease is for community testing. Nocturne 1.3 remains the stable
release. Alpha 1 establishes the product, privacy, continuity and distribution
boundaries required before NOC can become a broadly installable desktop.

## What is ready

- the existing Qt/Wayland shell, cards, Settings and supervised session;
- ten lock compositions and the responsive NOC terminal identity;
- a machine-readable Community edition with no desktop telemetry endpoint;
- age-encrypted multi-device Continuity for preferences, Desk, Habits and Vault;
- local rollback before every continuity pull;
- refusal to overwrite unseen changes from another device;
- release bundles with deterministic contents and SHA-256 checksums;
- Discussions, structured bug/hardware reports and a public support matrix.

The private Operator deployment is maintained separately. It can aggregate
download redirects by timestamp, country, release and asset, but cannot inspect
installed desktops or identify active users.

## Install the alpha

Download both files from the prerelease:

```bash
sha256sum -c nocturne-2.0.0-alpha.1-source.tar.gz.sha256
tar -xzf nocturne-2.0.0-alpha.1-source.tar.gz
cd nocturne-2.0.0-alpha.1
./install.sh --dry-run
./install.sh --install-packages
```

The installer snapshots the existing configuration first. Read
[`INSTALL.md`](INSTALL.md) before applying it to a customized session.

## Test requests

The most useful reports cover:

1. clean install on a disposable Ubuntu 26.04 account;
2. AMD graphics;
3. more than two displays or mixed scaling;
4. suspend, lock and resume;
5. screen capture and meeting sharing;
6. continuity between two machines using an already-trusted sync directory.

Never publish SSIDs, account names, clipboard contents, private file names or an
exported continuity identity. Use the Hardware compatibility issue form for a
structured report.

## Not stable yet

The stable 2.0 gate still requires a packaged update/rollback path, clean-machine
automation and external Intel/AMD/NVIDIA evidence. The complete gate is in
[`ROADMAP.md`](../ROADMAP.md).
