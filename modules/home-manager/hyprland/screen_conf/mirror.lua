dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

local primary = A_MONITOR or B_MONITOR or C_MONITOR
slot_monitor(primary, { mode = "preferred", position = "0x0", scale = A_MONITOR and A_SCALE or 1 })
for _, output in pairs({ a = A_MONITOR, b = B_MONITOR, c = C_MONITOR }) do
    if output ~= primary then
        slot_monitor(output, { mode = "preferred", position = "auto-right", scale = 1, mirror = primary })
    end
end
-- Only assigned slots mirror; unfamiliar/unused displays still extend right.
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })
