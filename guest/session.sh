#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" \
    "$HOME/Pictures" "$XDG_CONFIG_HOME/lxqt" "$XDG_CONFIG_HOME/autostart"

if [[ ! -f $XDG_CONFIG_HOME/lxqt/session.conf ]]; then
    cat > "$XDG_CONFIG_HOME/lxqt/session.conf" <<'EOF'
[General]
__userfile__=true
compositor=labwc
leave_confirmation=false
lock_command_wayland=
EOF
fi

# Android owns authentication, power, networking, and session termination.
cat > "$XDG_CONFIG_HOME/autostart/lxqt-policykit-agent.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=LXQt PolicyKit Agent
Hidden=true
EOF

lxqt-session &
session_pid=$!

(
    sleep 2
    cd "$BIONICX_ROOTFS"
    exec "$BIONICX_ROOTFS/opt/OpenCode/ai.opencode.desktop" \
        --ozone-platform=wayland \
        --use-gl=angle --use-angle=vulkan \
        --force-renderer-accessibility
) &

wait "$session_pid"
