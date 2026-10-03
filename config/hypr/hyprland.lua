-- Nocturne Hyprland — compact, keyboard-first and still mouse-friendly.
-- Hyprland 0.56+ uses Lua natively. Keep interaction here and presentation in
-- the native Nocturne shell and Hyprlock so there is one owner per surface.

local home = os.getenv("HOME")
local config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local function read_file(path)
    local handle = io.open(path, "r")
    if not handle then return "" end
    local contents = handle:read("*a")
    handle:close()
    return contents
end

local function theme_number(name, fallback)
    local raw = read_file(config_home .. "/nocturne/theme.conf")
    local value = raw:match("%$" .. name .. "%s*=%s*([%d%.]+)")
    return tonumber(value) or fallback
end

local function accent_border()
    local raw = read_file(config_home .. "/nocturne/accent.conf")
    local hex = raw:match("rgba%(([%x]+)%)")
    return hex and ("rgba(" .. hex .. ")") or "rgba(365c4cff)"
end

local terminal = "kitty"
local launcher = home .. "/.config/hypr/scripts/launcher"
local control = home .. "/.local/bin/nocturne-settings"
local clipboard = home .. "/.config/hypr/scripts/clipboard"
local power = home .. "/.config/hypr/scripts/power-menu"
local minimize = home .. "/.config/hypr/scripts/minimize"
local wallpaper = home .. "/.config/hypr/scripts/wallpaper"
local snap = home .. "/.config/hypr/scripts/snap-window"
local steam = home .. "/.config/hypr/scripts/steam-launch"
local hardware = home .. "/.config/hypr/scripts/hardware-control"
local scripts = home .. "/.config/hypr/scripts/"

local monitor_config = config_home .. "/nocturne/monitors.lua"
local monitor_file = io.open(monitor_config, "r")
if monitor_file then
    monitor_file:close()
    local loaded = pcall(dofile, monitor_config)
    if not loaded then
        hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
    end
else
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("GTK_THEME", "Adwaita-dark")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.on("hyprland.start", function()
    local commands = {
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME",
        "hyprpaper -c " .. config_home .. "/hypr/nocturne-wallpaper.conf",
        "systemctl --user start nocturne-wallpaper-cycle.service",
        "hypridle",
        "mako",
        scripts .. "bar",
        hardware .. " touchpad init",
        "/usr/libexec/hyprpolkitagent",
        "wl-paste --type text --watch cliphist store",
        "wl-paste --type image --watch cliphist store",
    }
    for _, command in ipairs(commands) do hl.exec_cmd(command) end
end)

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
            disable_while_typing = true,
        },
    },
    general = {
        gaps_in = theme_number("nocturne_gaps_in", 2),
        gaps_out = theme_number("nocturne_gaps_out", 3),
        border_size = theme_number("nocturne_border_size", 1),
        col = {
            active_border = accent_border(),
            inactive_border = "rgba(111719ff)",
        },
        resize_on_border = true,
        extend_border_grab_area = 12,
        allow_tearing = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        active_opacity = theme_number("nocturne_active_opacity", 1.0),
        inactive_opacity = theme_number("nocturne_inactive_opacity", 1.0),
        fullscreen_opacity = 1.0,
        shadow = { enabled = false },
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            vibrancy = 0.18,
            xray = false,
        },
    },
    animations = { enabled = true },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        force_split = 2,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        vrr = 1,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = true,
        enable_swallow = true,
        swallow_regex = "^(kitty)$",
    },
})

hl.curve("nocturne", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("quick", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "nocturne", style = "popin 97%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "quick", style = "popin 97%" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "nocturne" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "quick" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "nocturne", style = "slide" })
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

local function run(command) return hl.dsp.exec_cmd(command) end
local mod = "SUPER"

hl.bind(mod .. " + Return", run(terminal))
hl.bind(mod .. " + Space", run(launcher))
hl.bind(mod .. " + slash", run(scripts .. "help"))
hl.bind(mod .. " + R", run(control))
hl.bind(mod .. " + SHIFT + R", run("resources"))
hl.bind(mod .. " + W", run(wallpaper))
hl.bind(mod .. " + E", run("pcmanfm-qt"))
hl.bind(mod .. " + B", run("xdg-open https://www.google.com"))
hl.bind(mod .. " + C", run("chatgpt"))
hl.bind(mod .. " + X", run("kitty --class nox --title 'NØX // LOCAL OPERATOR' -e nox"))
hl.bind(mod .. " + D", run("code"))
hl.bind(mod .. " + T", run(steam))
hl.bind(mod .. " + N", run(home .. "/.local/bin/nocturne-native notifications"))
hl.bind(mod .. " + CTRL + W", run(home .. "/.local/bin/nocturne-native connectivity wifi"))
hl.bind(mod .. " + CTRL + B", run(home .. "/.local/bin/nocturne-native connectivity bluetooth"))
hl.bind(mod .. " + CTRL + A", run(home .. "/.local/bin/nocturne-native audio"))
hl.bind(mod .. " + SHIFT + V", run(clipboard))
hl.bind(mod .. " + P", run(power))
hl.bind(mod .. " + Escape", run(scripts .. "lock-screen"))

hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + M", run(minimize .. " hide"))
hl.bind(mod .. " + SHIFT + M", run(minimize .. " show"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + A", run(snap))
hl.bind(mod .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch" }))
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind(mod .. " + U", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + minus", hl.dsp.layout("splitratio -0.1"))
hl.bind(mod .. " + equal", hl.dsp.layout("splitratio 0.1"))

local directions = {
    H = "left", L = "right", K = "up", J = "down",
    left = "left", right = "right", up = "up", down = "down",
}
for key, direction in pairs(directions) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

for workspace = 1, 9 do
    hl.bind(mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", run(hardware .. " microphone"), { locked = true })
hl.bind("XF86AudioPlay", run("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", run("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", run("playerctl previous"), { locked = true })
hl.bind("XF86MonBrightnessUp", run(scripts .. "brightness up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", run(scripts .. "brightness down"), { locked = true, repeating = true })
hl.bind("XF86TouchpadToggle", run(hardware .. " touchpad toggle"), { locked = true })
hl.bind("XF86TouchpadOn", run(hardware .. " touchpad on"), { locked = true })
hl.bind("XF86TouchpadOff", run(hardware .. " touchpad off"), { locked = true })
hl.bind("XF86WebCam", run(hardware .. " camera"), { locked = true })
hl.bind("XF86KbdBrightnessUp", run(hardware .. " keyboard-light up"), { locked = true })
hl.bind("XF86KbdBrightnessDown", run(hardware .. " keyboard-light down"), { locked = true })
hl.bind("XF86Tools", run(scripts .. "help"))
local screenshots = home .. "/Pictures/Screenshots"
local hyprshot = home .. "/.local/bin/hyprshot -o " .. screenshots
hl.bind("Print", run(hyprshot .. " -m region"))
hl.bind("SHIFT + Print", run(hyprshot .. " -m window"))
hl.bind("CTRL + Print", run(hyprshot .. " -m output"))
hl.bind(mod .. " + Print", run("flatpak run io.github.seadve.Kooha"))

hl.layer_rule({ match = { namespace = "nocturne-native" }, blur = true, ignore_alpha = 0.2 })

local tiled_apps = "^(NocturneVisualizer|com\\.nocturne\\.Visualizer|com\\.nocturne\\.Settings|NocturneDashboard|pcmanfm-qt|qpdfview|qalculate-qt|net\\.nokyan\\.Resources|pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueman-manager|com\\.github\\.wwmm\\.easyeffects|org\\.rncbc\\.qpwgraph|org\\.kde\\.kdeconnect\\.app)$"
hl.window_rule({ match = { class = tiled_apps }, tile = true })

local opaque_utilities = "^(com\\.nocturne\\.Settings|pcmanfm-qt|qpdfview|qalculate-qt|org\\.kde\\..*|net\\.nokyan\\.Resources|io\\.missioncenter\\.MissionCenter|pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueman-manager|com\\.github\\.wwmm\\.easyeffects|org\\.rncbc\\.qpwgraph)$"
hl.window_rule({ match = { class = opaque_utilities }, opacity = "1.0 override 1.0 override 1.0 override" })
hl.window_rule({ match = { class = "^(NocturneDashboard)$" }, opacity = "0.98 override 0.98 override" })
hl.window_rule({ match = { class = "^(NocturneVisualizer|com\\.nocturne\\.Visualizer)$" }, opacity = "0.99 override 0.99 override" })
hl.window_rule({ match = { class = "^(firefox|Brave-browser|chromium|mpv)$" }, idle_inhibit = "fullscreen" })

hl.window_rule({ match = { class = "^(steam)$", title = "^(Steam)$" }, tile = true })
hl.window_rule({
    match = { class = "^(steam)$", title = "^(Steam Settings|Friends List|.* - Properties|.* Properties)$" },
    float = true,
    size = {960, 720},
    center = true,
})
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, immediate = true })

local opaque_content = "^(firefox|Brave-browser|brave-browser|brave-.*|chromium|Google-chrome|google-chrome|mpv|vlc|qpdfview|libreoffice.*|steam|steam_app_.*)$"
hl.window_rule({ match = { class = opaque_content }, opacity = "1.0 override 1.0 override 1.0 override" })

hl.layer_rule({ match = { namespace = "nocturne-bar" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "mako" }, blur = true, ignore_alpha = 0.15 })
