-- Native monitor roles: no watcher, generated runtime files, or connector IDs.
local config_dir = os.getenv("HOME") .. "/.config/hypr"
local last_bar

local function connected_monitors()
    local monitors, seen = {}, {}
    local function add(monitor)
        if seen[monitor.name] then return end
        seen[monitor.name] = true
        table.insert(monitors, monitor)
        -- Mirrors are absent from get_monitors(), but exposed by their source.
        for _, mirror in ipairs(monitor.mirrors or {}) do add(mirror) end
    end
    for _, monitor in ipairs(hl.get_monitors()) do add(monitor) end
    table.sort(monitors, function(a, b)
        if a.description == b.description then return a.name < b.name end
        return a.description < b.description
    end)
    return monitors
end

function resolve_monitor_roles()
    local monitors, slots, used = connected_monitors(), {}, {}
    MONITOR_ORDER = {}
    for role, candidates in ipairs(MONITOR_CANDIDATES) do
        for _, candidate in ipairs(candidates) do
            for _, monitor in ipairs(monitors) do
                local matches = candidate:sub(1, 5) == "desc:"
                    and monitor.description:sub(1, #candidate - 5) == candidate:sub(6)
                    or candidate == monitor.name
                if matches and not used[monitor.name] then
                    slots[role], used[monitor.name] = monitor.name, true
                    MONITOR_ORDER[monitor.name] = role - 1
                    break
                end
            end
            if slots[role] then break end
        end
    end
    -- Clear previous slot/mirror rules before applying the selected preset.
    -- This also restores a lower-priority candidate to an ordinary extra output.
    for i, monitor in ipairs(monitors) do
        hl.monitor({ output = monitor.name, mode = "preferred", position = "auto-right",
            scale = 1, transform = 0, mirror = "" })
        if not used[monitor.name] then MONITOR_ORDER[monitor.name] = 3 + i end
    end
    return slots[1], slots[2], slots[3]
end

function slot_monitor(output, settings)
    if output then
        settings.output = output
        hl.monitor(settings)
    end
end

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

-- Also queried by the existing bar script, so queued requests use current state.
function monitor_bar_state()
    local visible, colors = {}, {}
    for _, monitor in ipairs(hl.get_monitors()) do
        if not monitor.is_mirror then
            visible[monitor.name] = true
            local rank = MONITOR_ORDER[monitor.name]
            -- Connector names are compositor-controlled ASCII identifiers.
            table.insert(colors, string.format('%q:%d', monitor.name, rank and rank < 3 and rank or -1))
        end
    end
    local preferred = { B_MONITOR or false, C_MONITOR or false, A_MONITOR or false }
    local extras = {}
    for name in pairs(visible) do table.insert(extras, name) end
    table.sort(extras, function(a, b) return (MONITOR_ORDER[a] or 9999) < (MONITOR_ORDER[b] or 9999) end)
    for _, name in ipairs(extras) do table.insert(preferred, name) end
    local target
    for _, name in ipairs(preferred) do
        if visible[name] then target = name; break end
    end
    if not target then return "" end
    table.sort(colors)
    local roles = "{" .. table.concat(colors, ",") .. "}"
    return target .. "\n" .. roles
end

-- One native timer coalesces the intermediate events from docks/mirror changes.
local bar_timer
bar_timer = hl.timer(function()
    bar_timer:set_enabled(false)
    local state = monitor_bar_state()
    if state == last_bar then return end
    last_bar = state
    hl.exec_cmd("bash " .. shell_quote(config_dir .. "/scripts/open_bar.sh"))
end, { timeout = 250, type = "repeat" })
bar_timer:set_enabled(false)

function refresh_monitor_bar()
    bar_timer:set_timeout(250)
end

local function hotplug()
    last_bar = nil
    dofile(config_dir .. "/screen_conf/screen.lua")
end

hl.on("monitor.added", hotplug)
hl.on("monitor.removed", hotplug)
hl.on("monitor.layout_changed", refresh_monitor_bar)
hl.on("config.reloaded", refresh_monitor_bar)
