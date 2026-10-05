-- Minimal Nocturne recovery session: deliberately no panels, plugins or effects.
local home = os.getenv("HOME")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.config({
    general = { gaps_in = 2, gaps_out = 3, border_size = 1, layout = "dwindle" },
    decoration = { rounding = 0, shadow = { enabled = false }, blur = { enabled = false } },
    animations = { enabled = false },
    misc = { disable_hyprland_logo = false, disable_splash_rendering = false },
})
local function run(command) return hl.dsp.exec_cmd(command) end
hl.bind("SUPER + Return", run("kitty"))
hl.bind("SUPER + R", run(home .. "/.local/bin/nocturne-recovery restore"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + Escape", run("uwsm stop"))
hl.on("hyprland.start", function()
    hl.exec_cmd("notify-send 'Nocturne recovery session' 'Super+R restores the last checkpoint. Super+Enter opens a terminal.'")
end)
