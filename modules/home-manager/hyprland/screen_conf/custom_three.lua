dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

slot_monitor(C_MONITOR, { mode = "preferred", position = "0x0", scale = 1, transform = 1 })
slot_monitor(B_MONITOR, { mode = "preferred", position = "1080x450", scale = 1 })
slot_monitor(A_MONITOR, { mode = A_RES_X .. "x" .. A_RES_Y, position = "3640x500", scale = A_SCALE })
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })
