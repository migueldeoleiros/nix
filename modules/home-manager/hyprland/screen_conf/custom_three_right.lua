dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

slot_monitor(A_MONITOR, { mode = A_RES_X .. "x" .. A_RES_Y, position = "0x754", scale = A_SCALE })
slot_monitor(B_MONITOR, { mode = "preferred", position = "1920x754", scale = 1 })
slot_monitor(C_MONITOR, { mode = "preferred", position = "4480x0", scale = 1, transform = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })
