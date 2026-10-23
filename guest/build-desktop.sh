#!/bin/sh
# Package installation runs on the native ARM64 runner, never on consumer boot.
set -eu
export DEBIAN_FRONTEND=noninteractive
unset DPKG_ROOT
guest=/usr/lib/arlinux/guest
mkdir -p /etc/apt/sources.list.d /etc/dpkg/dpkg.cfg.d \
    /var/lib/apt/lists/partial /var/cache/apt/archives/partial /var/log/apt
printf 'force-confnew\n' > /etc/dpkg/dpkg.cfg.d/arlinux
cp "$guest/debian.sources" /etc/apt/sources.list.d/debian.sources
rm -f /etc/apt/sources.list
cp "$guest/apt.conf.in" /etc/apt/apt.conf
if [ ! -f /usr/share/arlinux/desktop-packages-installed ]; then
    apt-get update
    apt-get install -y --no-install-recommends /usr/lib/arlinux/mesa-packages/*.deb libegl1 libgles2 libopengl0
    apt-get install -y --no-install-recommends \
        bash foot ca-certificates curl dbus-x11 desktop-file-utils fontconfig gvfs gvfs-backends \
        fonts-dejavu-core fonts-noto-cjk breeze-icon-theme papirus-icon-theme \
        at-spi2-core python3-dbus python3-pyatspi ibus ibus-gtk3 ibus-gtk4 gir1.2-ibus-1.0 gir1.2-gtk-3.0 \
        python3-dogtail python3-pip mpg123 \
        wl-clipboard wtype xclip xdotool libwayland-egl1 libwayland-client0 \
        libwayland-server0 libx11-xcb1 libasound2-plugins libpam-elogind \
        lxqt-core lxqt-branding-debian lxqt-about lxqt-archiver featherpad lximage-qt qlipper qps \
        screengrab qt6-translations-l10n qt6-wayland qt6-qpa-plugins qt6-svg-plugins
    mkdir -p /usr/share/arlinux
    touch /usr/share/arlinux/desktop-packages-installed
    exit 75
fi
apt-get autoremove -y
rm -f /usr/lib/arlinux/mesa-packages/*.deb
python3 -m pip install --break-system-packages --no-cache-dir 'edge-tts==7.2.8'
python3 -c 'import edge_tts, pyatspi'
test -z "$(dpkg --audit)"
dpkg-divert --local --no-rename --add /usr/bin/sudo
apt-get clean
dpkg-query -W -f '${binary:Package}\t${Version}\n' > /usr/share/arlinux/packages.tsv
printf 'lxqt\n' > /usr/share/arlinux/offline-distribution
printf '1\n' > /usr/share/arlinux/offline-desktop
