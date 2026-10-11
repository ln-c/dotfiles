-- ~/.config/hypr/autostart.lua

hl.on("hyprland.start", function()
    local daemons = {
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP FONT_NAME FONT_SIZE",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP FONT_NAME FONT_SIZE",
        "/usr/lib/hyprpolkitagent",
        "hypridle",
        "foot --server",
        "ln-themectl",
    }

    for _, cmd in ipairs(daemons) do
        hl.exec_cmd(cmd)
    end

    hl.exec_cmd("ln-monitorctl ini")
end)
