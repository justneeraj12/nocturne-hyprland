# Contributing

Keep changes small, reversible and distribution-friendly. Nocturne's own UI
must remain Qt/Wayland-native; do not add GTK/GNOME UI dependencies or private
Hyprland plugins.

1. Create a topic branch.
2. Run `./scripts/validate-nocturne.sh`.
3. Test changed popovers on a real Wayland session at both display edges.
4. Do not commit screenshots containing browsers, messages, file names,
   account names, tokens or terminal history.
5. Explain user-visible behavior and rollback impact in the pull request.

New subprocess actions must use an explicit argument list. Do not interpolate
untrusted Wi-Fi names, media titles or file names into a shell command.
