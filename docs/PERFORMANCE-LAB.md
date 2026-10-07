# NOC Performance Lab

Performance Lab is a pressure-aware, reversible system profile for laptops. It
does not promise benchmark magic, clear useful caches, hold maximum clocks, or
overclock hardware. Its goal is better responsiveness during real mixed loads
without making idle power, heat, or data safety worse.

## What it changes

The optional **Adaptive profile** installs two NOC-owned files:

| File | Policy |
| --- | --- |
| `/etc/systemd/zram-generator.conf.d/90-nocturne.conf` | zstd-compressed zram, half of physical RAM capped at 8 GiB logical capacity, swap priority 100 |
| `/etc/sysctl.d/90-nocturne-performance.conf` | `vm.swappiness=100`, `vm.page-cluster=0`, `vm.vfs_cache_pressure=75` |

This means cold anonymous pages can move to compressed RAM before disk swap.
Existing disk swap remains the last-resort safety net. The zram capacity is a
limit, not permanently reserved memory: physical RAM is consumed only as pages
are stored.

The profile deliberately does **not** change dirty-write limits, NVMe queue
depth, CPU voltage, GPU clocks, filesystem mount flags, or thermal safeguards.
Those settings are hardware-, firmware- and workload-specific and can easily
make a laptop slower or less reliable.

## Cache policy

Linux already uses otherwise-idle RAM as a page cache and reclaims it under
pressure. Performance Lab therefore:

- never schedules `drop_caches`;
- never installs `preload` or a resident prediction daemon;
- leaves NVMe read-ahead and the block scheduler at the kernel/device defaults;
- retains filesystem metadata slightly longer with a conservative cache
  pressure of 75;
- reports memory PSI so a user can distinguish allocated RAM from actual
  contention.

The kernel documents `vfs_cache_pressure` as a reclaim balance, not a generic
speed dial. NOC stays close to the default instead of applying an extreme
internet-tuning value.

## Apply and rollback

Open **Settings → Performance Lab**. Applying opens a visible terminal, prints
the exact plan, and requires typing `APPLY`. A restart activates the profile;
NOC never replaces active swap devices under a running session.

Rollback uses the backup created immediately before the latest apply:

```bash
~/.config/hypr/scripts/performance-control rollback
```

It requires typing `ROLLBACK` and another restart. The status and plan commands
are always read-only:

```bash
~/.config/hypr/scripts/performance-control status | jq
~/.config/hypr/scripts/performance-control plan | jq
```

## Workload habits that matter more than sysctl folklore

- Keep **Balanced** for normal work. Use **Performance** while plugged in for a
  build or game, then return to Balanced.
- Keep at least 10–15% of the NVMe free so firmware and the filesystem retain
  working room.
- Use GameMode and NVIDIA offload per game instead of forcing maximum clocks for
  the whole session.
- Treat sustained memory PSI, thermal throttling, or storage fullness as the
  real bottleneck. High page-cache usage by itself is healthy.

## Upstream basis

- [Linux zram administration guide](https://www.kernel.org/doc/html/latest/admin-guide/blockdev/zram.html)
- [systemd zram generator configuration](https://github.com/systemd/zram-generator/blob/main/man/zram-generator.conf.md)
- [Linux VM sysctl documentation](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html)
- [systemd-oomd interface](https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.oom1.html)

