-- ~/.config/hypr/env.lua

local home = os.getenv("HOME")
local user_path = home .. "/.local/bin:" .. (os.getenv("PATH") or "")

-- Set environment variables for Hyprland and its children
hl.env("PATH", user_path)
hl.env("FONT_NAME", "Terminess Nerd Font Propo")
hl.env("FONT_SIZE", "15")
-- SSH passphrases (git commit signing included) ask in a desktop window
hl.env("SSH_ASKPASS", home .. "/.local/bin/ln-askpass")
hl.env("SSH_ASKPASS_REQUIRE", "prefer")

-- Export immediately to D-Bus and systemd
hl.exec_cmd("dbus-update-activation-environment --systemd PATH FONT_NAME FONT_SIZE SSH_ASKPASS SSH_ASKPASS_REQUIRE")
