local home = os.getenv("HOME")
local config_dir = home .. "/.config/hypr"

-- Monitor config is mutable: Home Manager creates screen.lua once, runtime scripts rewrite it.
dofile(config_dir .. "/screen_conf/screen.lua")
dofile(config_dir .. "/hyprland-host.lua")

local mod = "SUPER"
local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

local function move_current_workspace_to_next_monitor()
    local monitors = hl.get_monitors()
    local active = hl.get_active_monitor()

    if not active or #monitors < 2 then
        return
    end

    table.sort(monitors, function(a, b)
        return a.id < b.id
    end)

    for i, monitor in ipairs(monitors) do
        if monitor.id == active.id then
            local next_monitor = monitors[(i % #monitors) + 1]
            hl.dispatch(hl.dsp.workspace.move({ monitor = next_monitor.name }))
            return
        end
    end
end

hl.on("hyprland.start", function()
    hl.exec_cmd("dunst")
    hl.exec_cmd("bash " .. config_dir .. "/scripts/open_bar.sh")
    hl.exec_cmd("emacs --daemon")
    hl.exec_cmd("pypr")
    hl.exec_cmd("syncthing")
    -- Keep host-specific startup after shared daemons; path differs per distro.
    start_host_services()
    hl.exec_cmd("awww-daemon && bash " .. config_dir .. "/wallpaper.sh")
    hl.exec_cmd("fcitx5 -d &")
    hl.exec_cmd("arrpc")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)

hl.config({
    input = {
        kb_layout = KEYBOARD_LAYOUT,
        kb_variant = KEYBOARD_VARIANT,
        kb_model = "",
        kb_options = KEYBOARD_OPTIONS,
        kb_rules = "",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = false,
        },
        sensitivity = 0,
    },
    general = {
        gaps_in = 3,
        gaps_out = 5,
        border_size = 1,
        col = {
            active_border = { colors = { "rgb(b9b9b9)", "rgb(e0e0e0)" }, angle = 45 },
            inactive_border = "rgb(2d2d2d)",
        },
        layout = "dwindle",
        allow_tearing = true,
    },
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },
    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            noise = 0.03,
            size = 8,
            passes = 2,
            new_optimizations = true,
        },
        shadow = {
            enabled = false,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        enable_anr_dialog = false,
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
    master = {
        new_status = "slave",
        drop_at_cursor = true,
    },
    cursor = {
        no_hardware_cursors = true,
    },
})

hl.layer_rule({
    name = "blur-rofi",
    match = { namespace = "rofi" },
    blur = true,
})
hl.layer_rule({
    name = "blur-gtk-layer-shell",
    match = { namespace = "gtk-layer-shell" },
    blur = true,
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "slidevert" })

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding = 0,
})
hl.window_rule({
    name = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding = 0,
})
hl.window_rule({
    name = "float-gnuplot-qt",
    match = { class = "gnuplot_qt" },
    float = true,
})

hl.bind(mod .. " + Return", exec("kitty"))
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mod .. " + Escape", exec("bash " .. config_dir .. "/scripts/power_menu.sh"))
hl.bind(mod .. " + F", exec("nautilus"))
hl.bind(mod .. " + W", exec("zen"))
hl.bind(mod .. " + E", exec("emacsclient --create-frame"))
hl.bind(mod .. " + F1", exec("bash " .. config_dir .. "/scripts/wallpaper_menu.sh"))
hl.bind(mod .. " + N", exec('vicinae toggle --query "Wifi Commander"'))
hl.bind(mod .. " + SHIFT + N", exec("~/.config/eww/scripts/notifications toggle"))
hl.bind(mod .. " + A", exec("hyprctl switchxkblayout at-translated-set-2-keyboard next & hyprctl switchxkblayout evision-usb-device next"))
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + Space", exec("vicinae open"))
hl.bind(mod .. " + V", exec("vicinae 'vicinae://launch/clipboard/history?toggle=true'"))
hl.bind(mod .. " + SHIFT + Return", exec("pypr toggle term"))
hl.bind(mod .. " + M", exec("pypr toggle music"))
hl.bind(mod .. " + CTRL + Q", exec("vicinae 'vicinae://launch/@leonkohli/vicinae-extension-process-manager-0/processes?toggle=true'"))
hl.bind("Print", exec("wayshot ~/pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).jpg -g"))
hl.bind(mod .. " + B", exec("eww kill || bash " .. config_dir .. "/scripts/open_bar.sh"), { release = true })

hl.bind("XF86AudioPlay", exec("playerctl play-pause"))
hl.bind("XF86AudioStop", exec("playerctl stop"))
hl.bind("XF86AudioPrev", exec("playerctl previous"))
hl.bind("XF86AudioNext", exec("playerctl next"))
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86MonBrightnessUp", exec("brightnessctl set +20"), { repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 20-"), { repeating = true })

hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + D", exec("vicinae 'vicinae://launch/wm/switch-windows?toggle=true'"))
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + S", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + P", move_current_workspace_to_next_monitor)
hl.bind(mod .. " + F5", exec("bash " .. config_dir .. "/scripts/screen_config.sh"))

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
