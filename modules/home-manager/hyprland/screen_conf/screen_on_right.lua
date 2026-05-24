dofile(os.getenv("HOME") .. "/.config/hypr/screen_conf/variables.lua")

hl.monitor({ output = A_MONITOR, mode = A_RES_X .. "x" .. A_RES_Y, position = "0x0", scale = A_SCALE })
hl.monitor({ output = B_MONITOR, mode = B_RES_X .. "x" .. B_RES_Y, position = "auto-right", scale = 1 })
hl.monitor({ output = C_MONITOR, mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
