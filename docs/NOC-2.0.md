# NOC 2.0 product architecture

NOC 2.0 is an installable desktop platform powered by Hyprland. Hyprland owns
composition, input and window management; Nocturne owns the coherent user
experience, session policy, configuration schema, hardware adapters, recovery
and community distribution.

## Trust domains

### Community

- one public source tree and reproducible package inputs;
- no telemetry, endpoint or per-install identifier;
- native shell, Settings, cards and supervised session;
- encrypted multi-device continuity through a user-selected directory;
- diagnostics and support exports that stay local until explicitly shared.

### Operator

The maintainer-only overlay is a separate private repository and deployment. It
aggregates download-redirect events by country, date, hour, release and asset.
It stores no IP address, user agent, referrer or device identifier. Its metric
is **downloads**, not people or active installations. The public desktop has no
dependency on this system.

## Component boundary

| Component | Responsibility |
| --- | --- |
| `nocturne-native` | Bar, cards, launcher and Settings UI |
| `nocturne-session.target` | Lifecycle and failure supervision |
| Hyprland adapter | Workspaces, windows, monitors, gestures and IPC |
| Service adapters | NetworkManager, BlueZ, PipeWire, UPower and portals |
| Continuity | Encrypted roaming state with conflict refusal |
| Recovery | Pre-install snapshot and last-known-good rollback |
| Operator overlay | Private distribution aggregate, never desktop telemetry |

## Continuity model

Roaming state includes palette, bar preferences, launcher favorites, locations,
lock style, automation rules and encrypted Desk/Habits/Vault data. Machine state
such as monitor geometry, hardware profile, credentials and logs remains local.

The shared directory can be transported by Syncthing, Nextcloud, Drive or a
private Git checkout. Nocturne writes only `nocturne-continuity.age` there. A
remote change that the current device has not pulled causes push to fail closed;
the user must pull or explicitly force after review.

## Delivery milestones

1. **Foundation:** edition boundary, encrypted continuity, community templates,
   operator analytics contract and clean-install matrix.
2. **Packaging:** versioned Ubuntu package/repository, deterministic update and
   rollback, first-run hardware onboarding.
3. **Compatibility:** hardware reports, adapter fixtures, single-display and
   multi-display CI, NVIDIA/Intel/AMD validation.
4. **Platform:** stable shell API, documented card extension points and a
   version-pinned Hyprland plugin only where configuration cannot express NOC UX.
5. **Launch:** landing page, demo media, community beta, issue triage and public
   support matrix before the stable 2.0 release.
