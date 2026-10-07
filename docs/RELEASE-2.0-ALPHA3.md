# NOC 2.0 Alpha 3 // Pressure & Peripherals

Alpha 3 makes NOC faster under contention and more useful away from a known
desk, while preserving the project's zero-idle and reversible design.

## Performance Lab

- live CPU, page-cache, memory PSI, swap, zram and NVMe policy visibility;
- optional compressed-memory profile with disk swap retained as fallback;
- explicit `APPLY` confirmation, pre-change backups and a tested rollback path;
- kernel-managed caching with no timed cache purges or resident predictor;
- hardware-aware recommendations rather than a universal “gaming sysctl” dump.

Read the exact policy in [Performance Lab](PERFORMANCE-LAB.md).

## Campus compatibility

- CUPS/IPP Everywhere, Avahi and IPP-over-USB readiness;
- bounded on-demand printer and SANE/AirScan discovery;
- Skanpage with Document Scanner fallback;
- WPA-Enterprise/eduroam safety guidance without credential ownership;
- standard FIDO2 and smart-card capability visibility;
- matching Ubuntu and Arch dependency plans.

Read the compatibility model in [Campus compatibility](CAMPUS-COMPATIBILITY.md).

## Upgrade note

Run the dependency installer once to add the new standard backends, then apply
the desktop update normally:

```bash
./scripts/install-packages.sh
./apply-hyprland.sh
```

The performance profile is **not** silently enabled during installation. Open
Settings → Performance Lab, inspect the live recommendation, and opt in. A
restart is required because NOC will not hot-replace a working swap stack.

