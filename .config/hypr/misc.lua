-- ~/.config/hypr/misc.lua
hl.config({
    misc = {
        vrr = 1,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = "0x000000" -- Pure black for OLED
    },
    debug = {
        vfr = true
    },
    env = {
        "XDG_CURRENT_DESKTOP,Hyprland",
        "XDG_SESSION_TYPE,wayland",
        "XDG_SESSION_DESKTOP,Hyprland",
        "LIBVA_DRIVER_NAME,iHD"       -- Hardware video decoding for Lunar Lake
    }
})
