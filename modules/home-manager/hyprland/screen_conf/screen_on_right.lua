dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

slot_monitor(A_MONITOR, { mode = A_RES_X .. "x" .. A_RES_Y, position = "0x0", scale = A_SCALE })
slot_monitor(B_MONITOR, { mode = "preferred", position = "auto-right", scale = 1 })
slot_monitor(C_MONITOR, { mode = "preferred", position = "auto-right", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })
