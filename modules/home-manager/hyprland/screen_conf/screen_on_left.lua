dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

slot_monitor(B_MONITOR, { mode = "preferred", position = "0x0", scale = 1 })
slot_monitor(A_MONITOR, { mode = A_RES_X .. "x" .. A_RES_Y, position = B_MONITOR and B_RES_X .. "x0" or "0x0", scale = A_SCALE })
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })
