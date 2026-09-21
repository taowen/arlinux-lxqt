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

[Environment]
XDG_CURRENT_DESKTOP=LXQt:wlroots
EOF
fi

# Android owns authentication, power, networking, and session termination.
cat > "$XDG_CONFIG_HOME/autostart/lxqt-policykit-agent.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=LXQt PolicyKit Agent
Hidden=true
EOF

# Qt discards an input module that is unavailable during application startup.
# D-Bus activation returns only after the host input engine is ready.
dbus-send --session --print-reply --dest=org.arlinux.HostedInput \
    /org/arlinux/HostedInput org.freedesktop.DBus.Peer.Ping >/dev/null

exec startlxqt
