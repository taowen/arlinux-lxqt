# Arlinux LXQt

Arlinux LXQt is a complete LXQt Wayland desktop built from a pinned Debian Sid
snapshot for the open
[arlinux-rootfs](https://github.com/taowen/arlinux-rootfs) runtime. It uses the
anlabwc compositor supplied by the Android host and does not start a nested
Linux compositor.

This repository is also the external distribution-authoring reference. It was
created using only the public rootfs code and
[distribution contract](https://github.com/taowen/arlinux-rootfs/blob/main/docs/DISTRIBUTION-AUTHORING.md).
It contains no Android source, device automation, private submodules, or
host-specific build entry point.

## Build

Clone it into an `arlinux-rootfs` checkout:

```bash
git clone --recurse-submodules https://github.com/taowen/arlinux-rootfs.git
cd arlinux-rootfs
git clone https://github.com/taowen/arlinux-lxqt.git distributions/lxqt
./build.sh doctor
./build.sh validate distributions/lxqt
./build.sh build lxqt
./build.sh verify out/lxqt.arlinux-rootfs
```

The build is Linux-native, runs as an ordinary user on x86-64, and produces an
AArch64 bundle.

## Desktop composition

- Debian Sid snapshot with a glibc 2.43 ABI
- LXQt session, panel, runner, notifications, PCManFM-Qt, and QTerminal
- native Wayland clients with Xwayland available from the host
- host-provided anlabwc, graphics, input, audio, and AT-SPI transport

The package set intentionally excludes a display manager, Linux compositor,
power manager, lock screen, and network manager. Android owns those services.
The Sid archive is timestamped in `rootfs.lock.json`; updates are reviewed as a
complete snapshot rather than applied from an unbounded rolling mirror.

## Repository layout

- `rootfs.lock.json` pins the Debian archive snapshot and base packages.
- `tools/seed.sh` creates a foreign AArch64 rootfs seed.
- `guest/first-boot.sh` configures dpkg and installs the desktop natively.
- `guest/session.sh` supplies mobile-oriented defaults and starts LXQt.
- `profile.json` connects the session to the host-provided Wayland display.
- `native/product-policy.h` scopes Debian package-manager compatibility.

## License

The distribution recipe is GPL-3.0-or-later. Debian and LXQt packages retain
their respective licenses.
