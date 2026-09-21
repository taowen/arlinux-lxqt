#!/usr/bin/env bash
set -euo pipefail
product=$(cd "$(dirname "$0")/.." && pwd)
out=${1:?rootfs output required}
readarray -t config < <(python3 - "$product/rootfs.lock.json" <<'PY'
import json, sys
x = json.load(open(sys.argv[1]))
print(x['suite'])
print(x['mirror'].rstrip('/'))
print(x['variant'])
print(x['include'])
PY
)
rm -rf "$out"
mkdir -p "$out"
debootstrap --arch=arm64 --foreign --variant="${config[2]}" \
    --include="${config[3]}" "${config[0]}" "$out" "${config[1]}"

# Seed TLS trust before architecture-native package configuration runs.
ca_deb=("$out"/var/cache/apt/archives/ca-certificates_*_all.deb)
[[ -f "${ca_deb[0]}" ]] || { echo "ca-certificates package missing from seed" >&2; exit 1; }
dpkg-deb --extract "${ca_deb[0]}" "$out"
mkdir -p "$out/etc/ssl/certs"
find "$out/usr/share/ca-certificates" -type f -name '*.crt' -print0 \
    | sort -z | xargs -0 cat > "$out/etc/ssl/certs/ca-certificates.crt"
[[ -s "$out/etc/ssl/certs/ca-certificates.crt" ]]

# Sid configures base-files before the guest can create its system users. Seed
# the names its maintainer scripts require, without exposing _apt: Android
# cannot switch to a real sandbox UID. systemd-sysusers completes the database
# during first boot.
printf 'root:x:0:0:root:/root:/bin/bash\n' > "$out/etc/passwd"
printf 'root:x:0:\nmail:x:8:\n' > "$out/etc/group"
ln -s mawk "$out/usr/bin/awk"
cp "$product/guest/debian.sources" "$out/etc/apt/sources.list.d/debian.sources"
rm -f "$out/etc/apt/sources.list"
