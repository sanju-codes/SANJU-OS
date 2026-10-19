#!/usr/bin/env bash
# Sanju Security OS - PHASE 1 bootstrap
# Run on a Debian 12 / Ubuntu 22.04+ host (VM or bare metal). Do NOT run as root.
set -euo pipefail

ROOT="${1:-$HOME/sanju-security-os}"
mkdir -p "$ROOT"/{build,config,packages,desktop,themes,wallpapers,scripts,tools,installer,docs}
cd "$ROOT"

# ---------------------------------------------------------------- README
cat > README.md <<'EOF'
# Sanju Security OS
Security • Forensics • Recovery
Debian 12 (bookworm) + XFCE live ISO built with live-build.
For education, authorized testing, forensics, and recovery only.

Build:
    ./scripts/00-prepare.sh      # host check
    ./scripts/01-install-deps.sh # host packages
    ./scripts/02-configure.sh    # lb config + overlay
    ./scripts/03-build.sh        # produces the ISO
    ./scripts/05-test-qemu.sh    # boot test
    ./scripts/06-write-usb.sh    # write to USB
EOF

# ---------------------------------------------------------------- scripts
cat > scripts/00-prepare.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run as a normal user (sudo is used where needed)."; exit 1; }
. /etc/os-release
echo "Host: $PRETTY_NAME"
echo "Free disk in $HOME:"; df -h "$HOME" | tail -1
free_gb=$(df --output=avail -BG "$HOME" | tail -1 | tr -dc 0-9)
[ "$free_gb" -ge 20 ] || { echo "Need at least 20 GB free."; exit 1; }
echo "RAM:"; free -h | sed -n 2p
echo "OK - host is ready."
EOF

cat > scripts/01-install-deps.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y \
  live-build debootstrap squashfs-tools xorriso \
  isolinux syslinux syslinux-common syslinux-efi \
  grub-pc-bin grub-efi-amd64-bin grub-common mtools dosfstools \
  cryptsetup rsync git curl ca-certificates \
  qemu-system-x86 ovmf
echo "Dependencies installed."
EOF

cat > scripts/02-configure.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE/build"
sudo lb clean --purge >/dev/null 2>&1 || true

lb config \
  --distribution bookworm \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --debian-installer none \
  --archive-areas "main contrib non-free non-free-firmware" \
  --apt-indices false \
  --apt-recommends false \
  --memtest none \
  --iso-application "Sanju Security OS" \
  --iso-volume "SANJU_OS" \
  --iso-publisher "Sanju Security OS Project" \
  --bootappend-live "boot=live components quiet splash persistence username=sanju hostname=sanju-os locales=en_US.UTF-8 keyboard-layouts=us timezone=Etc/UTC"

# Overlay our own config (package lists, includes, hooks) on top
rsync -a "$HERE/config/" "$HERE/build/config/"
echo "Configured. Next: ./scripts/03-build.sh"
EOF

cat > scripts/03-build.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE/build"
rsync -a "$HERE/config/" config/
sudo lb build 2>&1 | tee build.log
ISO=$(ls -1 *.iso | head -1)
OUT="sanju-security-os-0.1-amd64.iso"
mv "$ISO" "$OUT"
sha256sum "$OUT" | tee "$OUT.sha256"
echo "ISO ready: $HERE/build/$OUT"
EOF

cat > scripts/05-test-qemu.sh <<'EOF'
#!/usr/bin/env bash
# Usage: ./05-test-qemu.sh [bios|uefi]
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ISO="$HERE/build/sanju-security-os-0.1-amd64.iso"
MODE="${1:-bios}"
ARGS=(-m 3072 -smp 2 -cdrom "$ISO" -boot d -vga virtio -nic user,model=virtio-net-pci)
[ -w /dev/kvm ] && ARGS+=(-enable-kvm -cpu host)
if [ "$MODE" = "uefi" ]; then
  ARGS+=(-bios /usr/share/ovmf/OVMF.fd)
fi
qemu-system-x86_64 "${ARGS[@]}"
EOF

cat > scripts/06-write-usb.sh <<'EOF'
#!/usr/bin/env bash
# Usage: sudo ./06-write-usb.sh /dev/sdX   (WHOLE DEVICE, not a partition)
set -euo pipefail
DEV="${1:-}"
ISO="$(cd "$(dirname "$0")/.." && pwd)/build/sanju-security-os-0.1-amd64.iso"
[ -b "$DEV" ] || { echo "Usage: sudo $0 /dev/sdX"; exit 1; }
lsblk -o NAME,SIZE,MODEL,TRAN "$DEV"
read -rp "ALL DATA on $DEV will be erased. Type YES to continue: " a
[ "$a" = "YES" ] || exit 1
dd if="$ISO" of="$DEV" bs=4M status=progress conv=fsync
sync
echo "Done. For persistence, see docs/persistence.md"
EOF
chmod +x scripts/*.sh

# ---------------------------------------------------------------- package list
mkdir -p config/package-lists
cat > config/package-lists/sanju-base.list.chroot <<'EOF'
# --- live system
live-boot
live-config
live-config-systemd
systemd-sysv
linux-image-amd64
cryptsetup
sudo
locales
bash-completion
zsh
# --- firmware / hardware detection
firmware-linux
firmware-linux-nonfree
firmware-misc-nonfree
firmware-iwlwifi
firmware-realtek
firmware-atheros
firmware-brcm80211
pciutils
usbutils
lshw
hwinfo
# --- desktop (XFCE)
xorg
xserver-xorg-input-all
xfce4
xfce4-goodies
lightdm
lightdm-gtk-greeter
thunar
thunar-archive-plugin
xfce4-terminal
xfce4-screenshooter
file-roller
mousepad
# --- network / audio / time
network-manager
network-manager-gnome
systemd-timesyncd
pipewire-audio
pavucontrol
xfce4-pulseaudio-plugin
# --- software management
synaptic
apt-transport-https
# --- browser
firefox-esr
# --- python + GTK (for later phases)
python3
python3-gi
gir1.2-gtk-3.0
python3-psutil
EOF

# ---------------------------------------------------------------- includes
mkdir -p config/includes.chroot/etc
cat > config/includes.chroot/etc/issue <<'EOF'
SANJU SECURITY OS 0.1  -  Security • Forensics • Recovery
\n \l

EOF
cat > config/includes.chroot/etc/motd <<'EOF'
========================================
SANJU SECURITY OS
Security • Forensics • Recovery
Use only on systems you own or are authorized to test.
========================================
EOF

# ---------------------------------------------------------------- hooks
mkdir -p config/hooks/normal
cat > config/hooks/normal/0100-sanju-base.hook.chroot <<'EOF'
#!/bin/sh
set -e
# Enable NetworkManager and time sync
systemctl enable NetworkManager || true
systemctl enable systemd-timesyncd || true
# Default display manager
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
chmod +x config/hooks/normal/0100-sanju-base.hook.chroot

# ---------------------------------------------------------------- docs
cat > docs/persistence.md <<'EOF'
# Persistence (manual, Phase 1)
After writing the ISO to a USB stick, create a 2nd partition with free space:
    sudo parted /dev/sdX --script mkpart primary ext4 <end-of-iso>MiB 100%
    sudo mkfs.ext4 -L persistence /dev/sdX3     # check partition number with lsblk
    sudo mkdir -p /mnt/p && sudo mount /dev/sdX3 /mnt/p
    echo "/ union" | sudo tee /mnt/p/persistence.conf
    sudo umount /mnt/p
Boot the "Live" entry; the kernel option "persistence" is already set.
Encrypted persistence: use cryptsetup luksFormat on the partition, open it,
mkfs.ext4 -L persistence on the mapper device, add persistence.conf, and boot with
"persistence-encryption=luks" added to the kernel options.
EOF

echo
echo "Project created at: $ROOT"
echo "Next:"
echo "  cd $ROOT && ./scripts/00-prepare.sh && ./scripts/01-install-deps.sh"
echo "  ./scripts/02-configure.sh && ./scripts/03-build.sh"
