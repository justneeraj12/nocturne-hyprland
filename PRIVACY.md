# Privacy

Nocturne Community does not phone home. It contains no analytics endpoint,
installation identifier, advertising identifier, crash-upload service or usage
telemetry. Diagnostics stay on the machine unless the user explicitly exports
a support archive; that archive excludes personal files and content.

## Distribution measurements

The project may count visits or downloads at its website or download redirect.
Those systems are separate from the desktop package. Published measurements
must be labelled **downloads**, never active users. The minimum permitted event
is a timestamp, two-letter country code, release and asset name. IP addresses,
user agents, referrers, device identifiers and application activity must not be
stored by Nocturne's own analytics system.

## Continuity

Nocturne Continuity encrypts its archive locally with `age` before placing it in
a user-selected shared directory. It includes roaming preferences and optional
workflow data. Passwords, network credentials, browser profiles, logs, display
layout, machine hardware state and wallpaper files are excluded. The encryption
identity never enters the shared directory automatically.

The private Operator dashboard is a deployment tool for the project maintainer.
It is not part of Community packages and cannot inspect installed desktops.
