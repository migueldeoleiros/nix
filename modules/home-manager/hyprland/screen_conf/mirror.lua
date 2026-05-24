dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

hl.monitor({ output = A_MONITOR, mode = A_RES_X .. "x" .. A_RES_Y, position = "0x0", scale = A_SCALE })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, mirror = A_MONITOR })
