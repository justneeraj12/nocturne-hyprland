# Support matrix

| Area | Reference status | Notes |
| --- | --- | --- |
| Ubuntu 26.04 | Tested | Primary package and CI target |
| Hyprland 0.56+ | Tested | Lua configuration provider required |
| Intel integrated graphics | Tested | Native Wayland and VA-API path |
| NVIDIA hybrid graphics | Tested | Fail-closed PRIME launch path for Steam |
| AMD graphics | Community validation needed | Hardware reports welcome |
| One display | Tested | Responsive module density |
| Two displays | Tested | Per-output bar and hotplug reconciliation |
| More than two displays | Community validation needed | Include geometry in hardware report |
| HiDPI / mixed scale | Partial | Core Qt scaling works; broader hardware evidence needed |
| Non-Ubuntu distributions | Source-compatible target | Package mapping is not yet maintained |

“Tested” means exercised on real hardware for the current release, not guaranteed
for every driver or firmware combination.
