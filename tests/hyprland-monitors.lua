-- Run from the repository root: lua tests/hyprland-monitors.lua
-- Stub-only tests: never call hyprctl or modify the running desktop.
local monitors, callbacks, rules, commands = {}, {}, {}, {}
local timer
hl = {
    get_monitors = function() return monitors end,
    on = function(event, callback) callbacks[event] = callback end,
    monitor = function(rule) rules[rule.output] = rule end,
    exec_cmd = function(command) table.insert(commands, command) end,
    timer = function(callback)
        timer = {
            callback = callback,
            set_enabled = function(self, enabled) self.enabled = enabled end,
            set_timeout = function(self) self.enabled = true end,
        }
        return timer
    end,
}
dofile("modules/home-manager/hyprland/screen_conf/monitors.lua")

local function display(name, description, mirrors)
    return { name = name, description = description, mirrors = mirrors or {} }
end
local panel = display("eDP-1", "BOE panel")
local home = display("DP-11", "Philips home")
local office = display("DP-8", "Dell office")
local portrait = display("DP-4", "HP portrait")
MONITOR_CANDIDATES = { { "desc:BOE" }, { "desc:Philips", "desc:Dell" }, { "desc:HP" } }

local function resolve()
    A_MONITOR, B_MONITOR, C_MONITOR = resolve_monitor_roles()
end

-- Candidate priority, independent of compositor enumeration/connector numbers.
monitors = { portrait, office, home, panel }
resolve()
assert(A_MONITOR == "eDP-1" and B_MONITOR == "DP-11" and C_MONITOR == "DP-4")
assert(MONITOR_ORDER[panel.name] == 0 and MONITOR_ORDER[home.name] == 1)
assert(MONITOR_ORDER[portrait.name] == 2 and MONITOR_ORDER[office.name] >= 3)
assert(rules[office.name].mirror == "" and rules[office.name].transform == 0)
assert(monitor_bar_state():match("^DP%-11\n"))

-- Connector churn does not change the physical display's role.
home.name = "DP-99"
resolve()
assert(B_MONITOR == "DP-99" and MONITOR_ORDER["DP-11"] == nil)

-- Removing the first candidate promotes the next; missing roles remain nil.
monitors = { office }
resolve()
assert(A_MONITOR == nil and B_MONITOR == "DP-8" and C_MONITOR == nil)
assert(monitor_bar_state():match("^DP%-8\n"))

-- Overlapping lists never claim the same physical output twice.
MONITOR_CANDIDATES = { { "desc:Dell" }, { "desc:Dell", "desc:HP" }, { "desc:HP" } }
monitors = { office, portrait }
resolve()
assert(A_MONITOR == "DP-8" and B_MONITOR == "DP-4" and C_MONITOR == nil)

-- Mirrors remain discoverable across reloads, but cannot host the bar.
MONITOR_CANDIDATES = { { "desc:BOE" }, { "desc:Philips" }, { "desc:HP" } }
panel.mirrors = { home, portrait }
home.is_mirror, portrait.is_mirror = true, true
monitors = { panel }
resolve()
assert(B_MONITOR == "DP-99" and C_MONITOR == "DP-4")
assert(monitor_bar_state() == 'eDP-1\n{"eDP-1":0}')

-- Unknown-only and empty setups stay usable without fabricating A/B/C slots.
monitors = { office }
resolve()
assert(not A_MONITOR and not B_MONITOR and not C_MONITOR)
assert(monitor_bar_state() == 'DP-8\n{"DP-8":-1}')
monitors = {}
resolve()
assert(monitor_bar_state() == "")
slot_monitor(nil, {})

-- Native timer coalesces a layout burst; unchanged state does not respawn eww.
monitors = { panel }
resolve()
for _ = 1, 10 do callbacks["monitor.layout_changed"]() end
assert(#commands == 0 and timer.enabled)
timer.callback()
assert(#commands == 1 and not timer.enabled)
callbacks["config.reloaded"]()
timer.callback()
assert(#commands == 1)

-- Hotplug replays the selected preset, not a hardcoded layout.
local real_dofile, replayed = dofile, 0
dofile = function(path)
    assert(path:match("/screen_conf/screen.lua$"))
    replayed = replayed + 1
end
callbacks["monitor.added"]()
callbacks["monitor.removed"]()
dofile = real_dofile
assert(replayed == 2)
print("PASS: monitor candidates, churn, overlap, mirrors, extras, debounce, hotplug")
