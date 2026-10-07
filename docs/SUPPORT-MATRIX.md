# Support matrix

| Area | Reference status | Notes |
| --- | --- | --- |
| Ubuntu 26.04 | Tested | Reference hardware and clean CI target |
| Arch Linux x86_64 (current) | CI validated | Official-repository package plan and native build run on every change |
| Hyprland 0.56+ | Tested | Lua configuration provider required |
| Intel integrated graphics | Tested | Native Wayland and VA-API path |
| NVIDIA hybrid graphics | Tested | Fail-closed PRIME launch path for Steam |
| AMD graphics | Community validation needed | Hardware reports welcome |
| One display | Tested | Responsive module density |
| Two displays | Tested | Per-output bar and hotplug reconciliation |
| More than two displays | Community validation needed | Include geometry in hardware report |
| HiDPI / mixed scale | Partial | Core Qt scaling works; broader hardware evidence needed |
| Arch derivatives | Compatible target | Uses the Arch adapter; distro-specific defaults still need community evidence |
| Other distributions | Source-compatible target | Package mappings are not yet maintained |

“Tested” means exercised on real hardware for the current release, not guaranteed
for every driver or firmware combination.
