dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

hl.monitor({ output = C_MONITOR, mode = "preferred", position = "0x0", scale = 1, transform = 1 })
hl.monitor({ output = B_MONITOR, mode = "preferred", position = "1080x450", scale = 1 })
hl.monitor({ output = A_MONITOR, mode = A_RES_X .. "x" .. A_RES_Y, position = "3640x500", scale = A_SCALE })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, mirror = A_MONITOR })
