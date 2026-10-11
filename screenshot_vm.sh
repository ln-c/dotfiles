#!/bin/bash
export WLR_BACKENDS=headless
export WAYLAND_DISPLAY=wayland-1
export HYPRLAND_LOG_WLR=1
export XDG_RUNTIME_DIR=/run/user/1000

# Start Hyprland in background
Hyprland > /tmp/hyprland.log 2>&1 &
HYPR_PID=$!

# Wait for Wayland socket
sleep 5
echo "Taking screenshot..."
grim /tmp/banner.jpg
kill $HYPR_PID
