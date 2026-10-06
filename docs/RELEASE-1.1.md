# Nocturne 1.1 // Fifty system upgrades

Nocturne 1.1 turns Settings into a practical control plane for storage, meetings, permissions, reliability, automation, input, displays, power and private clipboard behavior. The new helpers are command-driven and exit after each request; automation and adaptive power reuse the existing context timer instead of adding resident daemons.

1. A native Storage Center inside Nocturne Settings.
2. Live filesystem used and free capacity.
3. Separate cache, Downloads, Steam and local-model totals.
4. Explicit thumbnail cleanup with a two-step confirmation.
5. Explicit rebuildable developer-cache cleanup.
6. Browser-cache cleanup that refuses to run while a Chromium browser is open.
7. Guarded trash cleanup.
8. Visible privileged maintenance for package cache and journal cleanup.
9. On-demand duplicate detection limited to large files in Downloads or Documents.
10. A protected-data declaration covering games, personal files, rollback points and Codex runtimes.
11. A reversible Meeting Mode.
12. Exact pre-meeting notification state capture.
13. Exact pre-meeting caffeine state capture.
14. Exact pre-meeting input and output audio capture.
15. Exact pre-meeting power-profile capture.
16. Laptop-microphone preference and balanced power while Meeting Mode is active.
17. One-click Google Meet and Discord launch through Meeting Mode.
18. A native Permission Center.
19. Hyprland, broker and KDE portal health in one view.
20. Per-Flatpak override visibility.
21. Explicit per-application sandbox override reset.
22. Dynamic Flatpak permission totals.
23. User startup-application visibility.
24. Reversible startup enable and disable controls.
25. NOC Guard checks for bar, portal, audio, microphone, wallpaper and compositor errors.
26. Explainable safe repairs for every repairable Guard condition.
27. Scoped configuration diff against the last-known-good Nocturne checkpoint.
28. A bounded Automation Builder with no arbitrary shell execution.
29. Docked and mobile rule triggers.
30. AC and battery rule triggers.
31. Meeting, focus and gaming rule triggers.
32. DND, caffeine, power-profile and scene actions.
33. Edge-triggered rules that do not repeat until state changes.
34. Automation events recorded in the private Nocturne Trace.
35. NOC Pulse for private on-demand work, habit, focus, meeting and health totals.
36. Battery health and cycle visibility when firmware exposes them.
37. Firmware-aware charge-threshold controls.
38. Deep-sleep capability and active sleep-mode visibility.
39. Adaptive low-battery saver using the existing context timer.
40. Available monitor-mode and refresh-rate visibility.
41. One-click maximum-refresh selection and VRR control.
42. Touchpad workspace-swipe and pointer-acceleration controls using Hyprland 0.56 gestures.
43. Wi-Fi captive-portal detection and sign-in.
44. Metered-network control.
45. Local Wi-Fi sharing QR codes and hotspot controls.
46. Bluetooth battery and active codec detail when devices expose them.
47. Sensitive clipboard values excluded from Cliphist and expired if still copied.
48. Private `0600` pinned text clipboard items.
49. Local screenshot annotation through Grim, Slurp and Swappy.
50. Local screen OCR to the Wayland clipboard through Tesseract.

## Safety model

- Storage cleanup targets are named and bounded; duplicate scans never delete.
- Meeting Mode saves state before changing it and restores that state on exit.
- Automation accepts only known triggers and known actions.
- Permission reset and startup changes require an explicit app selection.
- Clipboard pins, automation rules and power preferences are private to the user.
- Guard diagnoses first and only exposes safe, predefined repairs.
- New control-center helpers add zero persistent processes. Clipboard privacy
  replaces the existing text-history watcher rather than adding a second watcher.

## Optional workflow packages

`./install.sh --install-packages` installs Swappy, Tesseract and qrencode for annotation, OCR and Wi-Fi sharing. The rest of Nocturne remains functional when one of those optional workflows is unavailable, and `nocturne-doctor` reports the exact missing component.
