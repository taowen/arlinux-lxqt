#!/bin/sh
# The runner has already configured Debian and installed the desktop.
set -eu
guest=/usr/lib/arlinux/guest
update-mime-database /usr/share/mime
if [ ! -s /etc/machine-id ]; then
    chmod u+w /etc/machine-id
    tr -d '-' < /proc/sys/kernel/random/uuid > /etc/machine-id
    chmod 444 /etc/machine-id
fi
mkdir -p /usr/lib/python3/dist-packages/arlinux
cp "$guest/arlinux/"*.py /usr/lib/python3/dist-packages/arlinux/
/bin/sh "$guest/opencode-instructions.sh"
mkdir -p /etc/pulse/client.conf.d /etc/alsa/conf.d
printf 'default-server = unix:%s/runtime/pulse-native\nautospawn = no\nenable-shm = no\n' \
    "$BIONICX_FILES" > /etc/pulse/client.conf.d/arlinux.conf
printf 'pcm.!default { type pulse }\nctl.!default { type pulse }\n' \
    > /etc/alsa/conf.d/99-arlinux-pulse.conf
