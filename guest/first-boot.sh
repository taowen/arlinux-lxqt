#!/bin/sh
set -eu
root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
export DPKG_ROOT=$root BIONICX_VIRTUAL_ROOT=1
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

guest=$root/usr/lib/arlinux/guest
mkdir -p "$root/etc/apt/sources.list.d" "$root/etc/dpkg/dpkg.cfg.d" \
    "$root/var/lib/apt/lists/partial" "$root/var/cache/apt/archives/partial" \
    "$root/var/log/apt"
cp "$guest/debian.sources" "$root/etc/apt/sources.list.d/debian.sources"
sed "s|@ROOT@|$root|g" "$guest/apt.conf.in" > "$root/etc/apt/apt.conf"
printf 'force-not-root\nforce-script-chrootless\nforce-confnew\nroot=%s\nadmindir=%s/var/lib/dpkg\n' \
    "$root" "$root" > "$root/etc/dpkg/dpkg.cfg.d/arlinux"

mkdir -p "$root/etc/ld.so.conf.d"
printf '/usr/lib/arlinux-platform\n' > "$root/etc/ld.so.conf.d/arlinux.conf"
dpkg-divert --local --no-rename --add /usr/sbin/ldconfig
dpkg-divert --local --no-rename --add /usr/bin/sudo
cp "$root/usr/lib/arlinux-platform/ldconfig" "$root/usr/sbin/ldconfig"
chmod 755 "$root/usr/sbin/ldconfig"
ldconfig

if ! dpkg --configure -a; then
    apt-get update
    apt-get -f install -y
fi

set -- bash ca-certificates curl dbus-x11 desktop-file-utils fontconfig \
    fonts-dejavu-core fonts-noto-cjk at-spi2-core python3-dbus python3-pyatspi \
    wl-clipboard wtype xclip xdotool libwayland-egl1 libwayland-client0 \
    libwayland-server0 libx11-xcb1 libasound2-plugins \
    lxqt-session lxqt-panel lxqt-runner lxqt-notificationd lxqt-config lxqt-qtplugin \
    lxqt-system-theme lxqt-themes pcmanfm-qt qterminal qtxdg-tools qt6-wayland
missing=
for package do
    if ! dpkg-query -W -f '${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'; then
        missing=1
        break
    fi
done
if [ -n "$missing" ]; then
    echo 'ARLINUX:Updating the Debian Sid snapshot...'
    apt-get update
    echo 'ARLINUX:Installing the LXQt desktop...'
    apt-get install -y --no-install-recommends "$@"
    exit 75
fi

mkdir -p "$root/etc/pulse/client.conf.d" "$root/etc/alsa/conf.d"
printf 'default-server = unix:%s/runtime/pulse-native\nautospawn = no\nenable-shm = no\n' \
    "$BIONICX_FILES" > "$root/etc/pulse/client.conf.d/arlinux.conf"
cat > "$root/etc/alsa/conf.d/99-arlinux-pulse.conf" <<'ALSA'
pcm.!default { type pulse }
ctl.!default { type pulse }
ALSA
