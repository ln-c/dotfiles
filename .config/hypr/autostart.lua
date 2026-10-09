-- ~/.config/hypr/autostart.lua

hl.on("hyprland.start", function()
    local daemons = {
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP FONT_NAME FONT_SIZE",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP FONT_NAME FONT_SIZE",
	"/usr/lib/hyprpolkitagent",
        "hyprpaper",
	"waybar",
        "mako -c ~/.cache/wal/mako-config",
        "hypridle",
	"ln-themectl",
    }

    for _, cmd in ipairs(daemons) do
        hl.exec_cmd(cmd)
    end
end)

-- Execute on every config reload (and startup)
hl.exec_cmd("ln-monitorctl ini")
