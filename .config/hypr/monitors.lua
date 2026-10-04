-- ~/.config/hypr/monitors.lua

-- eDP-1: 2.8K 120Hz OLED Display (1.6x fractional scale)
hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@120",
    position = "0x0",
    scale = 2.25
    }
)
-- Fallback Monitor setup
hl.monitor({
    output = "DP-1",
    mode = "1920x1080@60",
    position = "0x1080",
    scale = 1
    }
)
-- Fallback Monitor setup
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
    }
)
