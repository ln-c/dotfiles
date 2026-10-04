-- ~/.config/hypr/autostart.lua

local home = os.getenv("HOME")
local user_path = home .. "/.local/bin:" .. (os.getenv("PATH") or "")

-- Add user path script in enviroment Hyprland
hl.env("PATH", user_path)

-- Export it to D-Bus and systemd user environments on startup
hl.exec_cmd("dbus-update-activation-environment --systemd PATH")

hl.on("hyprland.start", function()
    local daemons = {
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
	"/usr/lib/hyprpolkitagent",
        "hyprpaper",
	"waybar",
        "mako -c ~/.cache/wal/mako-config",
        "hypridle",
	"wal -R",
	"ln-monitorctl ini",
	"hyprlock"
    }

    for _, cmd in ipairs(daemons) do
        hl.exec_cmd(cmd)
    end
end)
