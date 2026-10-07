# NOC roadmap

The latest stable release is NOC 2.0, an installable desktop platform powered
by Hyprland.

## 2.0 foundation

- [x] public Community/private Operator trust boundary;
- [x] encrypted, transport-neutral multi-device continuity;
- [x] conflict refusal and machine-local state separation;
- [x] structured bug, hardware and feature contribution paths;
- [x] official-repository Arch package adapter and clean Arch native CI;
- [x] clean-home install, checkpoint and rollback fixture;
- [ ] Ubuntu package and signed repository metadata;
- [ ] transactional update command with automatic rollback;
- [x] first-run hardware onboarding and compatibility report;
- [x] capability-gated declarative extension contract with zero arbitrary code;
- [ ] stable native extension contract;
- [ ] community beta across Intel, AMD and NVIDIA hardware.

## Post-2.0 hardening

2.0 is stable for its published Ubuntu reference and Arch CI contract. Package
repository metadata, a wider external hardware matrix, a stable third-party
native-extension ABI and additional disposable-machine coverage remain active
hardening work; they will expand support without silently changing the 2.0
privacy or rollback boundaries.

Nocturne is not planning to fork the compositor in this cycle. A version-pinned
Hyprland plugin may be introduced for behaviour that cannot be expressed through
documented configuration and IPC.
