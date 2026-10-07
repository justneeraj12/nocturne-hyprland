# NOC roadmap

The latest stable release is Nocturne 1.3. NOC 2.0 is being developed as an
installable desktop platform powered by Hyprland.

## 2.0 foundation

- [x] public Community/private Operator trust boundary;
- [x] encrypted, transport-neutral multi-device continuity;
- [x] conflict refusal and machine-local state separation;
- [x] structured bug, hardware and feature contribution paths;
- [ ] clean virtual-machine install fixture;
- [ ] Ubuntu package and signed repository metadata;
- [ ] transactional update command with automatic rollback;
- [ ] first-run hardware onboarding and compatibility report;
- [ ] stable native extension contract;
- [ ] community beta across Intel, AMD and NVIDIA hardware.

## Stable 2.0 gate

2.0 will not be labelled stable until clean install, update and rollback pass on
the reference laptop plus disposable machines, critical cards pass keyboard and
multi-monitor interaction tests, and the public support matrix contains results
from hardware outside the maintainer's system.

Nocturne is not planning to fork the compositor in this cycle. A version-pinned
Hyprland plugin may be introduced for behaviour that cannot be expressed through
documented configuration and IPC.
