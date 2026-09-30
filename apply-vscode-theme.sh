#!/usr/bin/env bash
set -euo pipefail

settings_file=${XDG_CONFIG_HOME:-"$HOME/.config"}/Code/User/settings.json
[[ -f "$settings_file" ]] || {
  printf 'VS Code settings were not found at %s\n' "$settings_file" >&2
  exit 1
}

command -v code >/dev/null || {
  printf 'The VS Code command-line launcher is not installed.\n' >&2
  exit 1
}

code --install-extension enkia.tokyo-night --force
code --install-extension PKief.material-icon-theme --force

perl -0pi -e 's/"workbench\.colorTheme"\s*:\s*"[^"]*"/"workbench.colorTheme": "Tokyo Night Storm"/' "$settings_file"
perl -0pi -e 's/"workbench\.iconTheme"\s*:\s*"[^"]*"/"workbench.iconTheme": "material-icon-theme"/' "$settings_file"
perl -0pi -e 's/"workbench\.colorCustomizations"\s*:\s*\{\s*\}/"workbench.colorCustomizations": {\n        "titleBar.activeBackground": "#0f111a",\n        "titleBar.activeForeground": "#c0caf5",\n        "titleBar.inactiveBackground": "#0f111a",\n        "titleBar.inactiveForeground": "#565f89",\n        "activityBar.background": "#0f111a",\n        "sideBar.background": "#15161e",\n        "editorGroupHeader.tabsBackground": "#0f111a",\n        "tab.activeBorderTop": "#7aa2f7",\n        "statusBar.background": "#15161e",\n        "statusBar.foreground": "#a9b1d6",\n        "window.activeBorder": "#283457",\n        "window.inactiveBorder": "#15161e"\n    }/' "$settings_file"

printf 'VS Code now uses Tokyo Night Storm with the matching Material icon theme.\n'
