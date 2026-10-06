# Nocturne 0.7 — fifty practical upgrades

This release deliberately groups small interaction fixes with larger system
features. Every item below is represented in source and covered by the normal
build/validation pipeline.

## Input, accessibility and shared controls

1. Bar controls can receive keyboard focus.
2. Enter activates the focused bar control.
3. Space activates the focused bar control.
4. Focused bar controls get a high-contrast outline.
5. Bar controls expose accessible names and descriptions.
6. Clickable bar controls use a pointing cursor.
7. Bar tooltips stay hidden while a button is pressed.
8. Native toggles participate in Tab navigation.
9. Space and Enter operate native toggles.
10. Toggles expose their checked state to accessibility tools.

## Command Center and clipboard

11. Command Center reports grammatically correct result counts.
12. Page Up and Page Down navigate results in useful chunks.
13. Ctrl+Home and Ctrl+End jump to the first and last result.
14. Ctrl+L selects the launcher query for immediate replacement.
15. Escape clears a query before closing the launcher.
16. Empty launcher filters now explain why no result is visible.
17. Favorite stars no longer lose clicks to the row activation target.
18. Clipboard history clearing requires a second confirmation click.
19. Clipboard clear confirmation expires automatically.
20. Clipboard adds counts, paging, first/last jumps and filtered-empty feedback.

## Notifications, minimized windows and power

21. Notification results support keyboard arrow navigation.
22. Notification results support paged and first/last navigation.
23. Ctrl+F focuses and selects notification search.
24. Notification selection is clamped when live results change.
25. The active one-hour Focus preset is visibly selected.
26. Filtered notification empty states and match counts are explicit.
27. Minimized windows can be selected and restored entirely by keyboard.
28. The minimized panel shows window counts and workspace badges.
29. Restore All disappears when there is nothing to restore.
30. Restart and shutdown now share one cancelable, expiring confirmation state.

## Settings and diagnostics

31. Settings remembers the last opened section.
32. Alt+Left and Alt+Right move between Settings sections.
33. Ctrl+Home and Ctrl+End jump across the Settings navigation.
34. Ctrl+B toggles the compact Settings sidebar.
35. Settings search includes a mouse-accessible clear button.
36. F1 opens the complete key guide from any native card.
37. Ctrl+R refreshes the active native card when it supports refresh.
38. `nocturne-doctor --json` emits structured health results.
39. `nocturne-doctor --summary` emits a one-line status.
40. Settings can create a privacy-limited, permission-0600 support archive.

## Audio and camera quality

41. Muted master audio has an unmistakable selected/danger state.
42. Muted application streams use the same visual contract.
43. Stream counts say ACTIVE rather than incorrectly claiming playback.
44. Master and per-application sliders expose descriptive accessible names.
45. A themed camera-quality card reports the real sensor and current owner.
46. Camera profiles refuse to modify a sensor held by another application.
47. SMART keeps automatic exposure, white balance and focus with backlight help.
48. NATURAL preserves automatic control while avoiding backlight compensation.
49. LOW LIGHT enables supported dynamic-exposure behavior.
50. Camera tuning persists in hardware with no idle process and selects local
    50/60 Hz anti-flicker while targeting the sensor's efficient 720p30 MJPEG mode.
