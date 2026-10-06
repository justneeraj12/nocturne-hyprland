# Nocturne 0.9 // Local workflow memory

Nocturne 0.9 turns the shell into a useful work surface without adding a cloud
account, an Electron task app, a model process or another resident widget
framework. NOC Desk exists only while its card is open; the persistent bar reads
its compact local status through an event-driven file watch.

## NOC Desk

1. Native task card opened with `Super + Shift + N`.
2. One-line task capture with keyboard submit.
3. Low, normal and high priorities.
4. No-date, today and tomorrow capture presets.
5. Open, today, completed and all-task views.
6. Live text filtering inside each view.
7. Pinned tasks sort ahead of ordinary work.
8. Inline task editing.
9. One-click completion and reopening.
10. Two-step deletion with an expiring confirmation.
11. Two-step completed-task cleanup.
12. Full-state undo/redo swap for manual mutations.
13. One selected focus target at a time.
14. A focus block starts Pomodoro and timed notification silence together.
15. Completing a task from the timer card.
16. Autosaved multiline scratch note.
17. Private Markdown export to Documents.
18. Count-only daily brief with no task content in notifications.
19. Today, overdue, completed-today and focus-minute metrics.
20. Per-task focus session and minute accumulation.
21. Today, seven-day and lifetime focus statistics in the local API.
22. Capped 500-session history instead of unbounded state growth.
23. Mode `0600` for task, note, timer and undo state.
24. No task, note or focus content in Nocturne Trace or support reports.

## Command Center operator input

25. `+ task` captures a normal Desk task.
26. `+! task` marks the capture high priority.
27. `+^ task` makes it due today; markers can be combined as `+!^`.
28. `volume 35` previews a PipeWire volume action.
29. `brightness 60` previews a hardware-backlight action.
30. `focus 45` previews timed notification focus.
31. `timer 50/10` configures focus and recovery minutes.
32. `power performance`, `power balanced` and `power saver` select a profile.
33. `wifi on/off` controls only the Wi-Fi radio.
34. `bluetooth on/off` controls only the Bluetooth controller.
35. `night on/off` controls native Hyprsunset Night Shift.
36. `mute/unmute audio|mic` controls an explicit PipeWire endpoint.

These inputs are parsed against fixed regular expressions and range checks. They
are displayed as an action first and execute only after confirmation with Enter.
User input is passed as argument data, never evaluated by a shell.

## Integration and efficiency

37. Optional NOC Desk module in Bar Studio and per-display overrides.
38. Bar state refreshes on data-directory events with a five-minute recovery
    check; there is no Desk service or polling loop.
39. The Pomodoro clock now survives shell and session restarts and safely catches
    an elapsed phase on the next read.
40. Auto-start-next-phase is exposed in the native timer card.
41. Schema 6 adds the module without overwriting existing bar preferences.
42. Doctor verifies Desk data shape, file privacy and zero persistent processes.
43. The release suite exercises task mutation, undo, note round-trip, export,
    timer transition, session recording and operator-query parsing.
44. All 24 on-demand cards are instantiated in an isolated Qt runtime during the
    clean release build.

## Upgrade

Run `./install.sh`. The installer creates a recovery snapshot, migrates existing
bar preferences and leaves all other Nocturne data intact. NOC Desk initializes
an empty private store on first status read. Rollback remains available through
`./uninstall.sh` with the explicit `RESTORE` confirmation.
