#!/bin/sh
set -eu
root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
export DPKG_ROOT=$root BIONICX_VIRTUAL_ROOT=1
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export SYSTEMD_OFFLINE=1 SYSTEMD_SYSUSERS_BYPASS=1 SYSTEMD_TMPFILES_BYPASS=1

guest=$root/usr/lib/arlinux/guest
mkdir -p "$root/etc/apt/sources.list.d" "$root/etc/dpkg/dpkg.cfg.d" \
    "$root/var/lib/apt/lists/partial" "$root/var/cache/apt/archives/partial" \
    "$root/var/log/apt" "$root/tmp"
chmod 1777 "$root/tmp"
if [ ! -s "$root/etc/machine-id" ]; then
    chmod u+w "$root/etc/machine-id"
    tr -d '-' < /proc/sys/kernel/random/uuid > "$root/etc/machine-id"
    chmod 444 "$root/etc/machine-id"
fi
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

set -- bash ca-certificates curl dbus-x11 desktop-file-utils fontconfig gvfs gvfs-backends \
    fonts-dejavu-core fonts-noto-cjk breeze-icon-theme papirus-icon-theme \
    at-spi2-core python3-dbus python3-pyatspi ibus ibus-gtk3 ibus-gtk4 gir1.2-ibus-1.0 \
    python3-dogtail python3-pip mpg123 \
    wl-clipboard wtype xclip xdotool libwayland-egl1 libwayland-client0 \
    libwayland-server0 libx11-xcb1 libasound2-plugins \
    libpam-elogind \
    lxqt-core lxqt-branding-debian lxqt-about lxqt-archiver featherpad lximage-qt qlipper qps \
    screengrab qt6-translations-l10n \
    qt6-wayland qt6-qpa-plugins qt6-svg-plugins
missing=
for package do
    if ! dpkg-query -W -f '${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'; then
        missing=1
        break
    fi
done
if [ -n "$missing" ]; then
    echo 'ARLINUX:Updating Debian Testing package metadata...'
    apt-get update
    echo 'ARLINUX:Installing the LXQt desktop...'
    apt-get install -y --no-install-recommends \
        dbus-system-bus-common systemd-standalone-sysusers
    # Maintainer scripts are intentionally offline during installation.  Run
    # the standard package helpers once for the system bus before installing
    # the desktop packages that depend on it.
    env -u SYSTEMD_SYSUSERS_BYPASS systemd-sysusers dbus.conf
    apt-get install -y --no-install-recommends "$@"
    exit 75
fi

if ! python3 -c 'import edge_tts' >/dev/null 2>&1; then
    echo 'ARLINUX:Installing online speech support...'
    python3 -m pip install --break-system-packages --no-cache-dir 'edge-tts==7.2.8'
fi
mkdir -p "$root/usr/lib/python3/dist-packages/arlinux"
cp "$guest/arlinux/"*.py "$root/usr/lib/python3/dist-packages/arlinux/"

"$root/bin/sh" "$guest/opencode-install.sh"
"$root/bin/sh" "$guest/opencode-instructions.sh"
install -Dm644 "$guest/opencode-autostart.desktop" \
    "$root/etc/xdg/autostart/opencode.desktop"

mkdir -p "$root/etc/pulse/client.conf.d" "$root/etc/alsa/conf.d"
printf 'default-server = unix:%s/runtime/pulse-native\nautospawn = no\nenable-shm = no\n' \
    "$BIONICX_FILES" > "$root/etc/pulse/client.conf.d/arlinux.conf"
cat > "$root/etc/alsa/conf.d/99-arlinux-pulse.conf" <<'ALSA'
pcm.!default { type pulse }
ctl.!default { type pulse }
ALSA
