# NOC Security Hub

Security Hub is a lightweight control plane over standard Linux security
mechanisms. It does not claim that one scanner can make a workstation safe.
Prevention, containment, integrity and detection are shown together.

## Resource model

- no ClamAV daemon or on-access scanner is enabled;
- official signatures are stored in the user's local NOC data directory;
- `clamscan` and its signature memory exist only during an explicit or scheduled
  scan, then exit;
- optional systemd timers consume no resident RAM between a daily definition
  update and weekly quick scan;
- Security Hub itself is instantiated only while its Settings page is visible.

This avoids the persistent signature memory required by `clamd`/`clamonacc`.
The tradeoff is intentional: it is scheduled and on-demand detection, not
fanotify-based blocking at every file access.

## Detection modes

**Quick scan** checks Downloads and Desktop with official signatures. **Deep
Downloads** additionally enables PUA, heuristic and encrypted-content alerts.
Those extra classes may report legitimate packers or encrypted files, so NOC
never deletes or quarantines automatically. Scan logs stay mode `0600` under
`~/.local/state/nocturne/security/` and are never included in support bundles.

**Full home scan** excludes regenerable caches, Steam libraries and Trash. It is
manual because loading signatures and walking a home directory is not a
lightweight background task.

## Protection layers

- AppArmor mandatory access control and enforced-profile count;
- UFW or nftables firewall availability and state;
- UEFI Secure Boot state;
- root-device encryption detection;
- outstanding distribution package updates;
- distribution-native package integrity (`debsums` or `pacman -Qkk`);
- local listening-socket count as exposure context.

The `x/7 layers ready` badge is coverage, not a security score or guarantee.
Some valid systems intentionally lack Secure Boot, disk encryption or a host
firewall.

## Commands

```bash
security-control status
security-control update
security-control scan quick standard
security-control scan downloads deep
security-control scan home standard
security-control integrity
security-control schedule true
```

Definition updates use ClamAV's official mirror. Files and hashes are never
uploaded to a reputation service.

## Design references

- [ClamAV signature management](https://docs.clamav.net/manual/Usage/SignatureManagement.html)
- [ClamAV PUA detection](https://docs.clamav.net/faq/faq-pua.html)
- [ClamAV on-access scanning](https://docs.clamav.net/manual/OnAccess.html)
- [Ubuntu AppArmor guidance](https://documentation.ubuntu.com/server/how-to/security/apparmor/)
- [Ubuntu firewall guidance](https://documentation.ubuntu.com/server/how-to/security/firewalls/)
