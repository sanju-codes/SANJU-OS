#!/usr/bin/env bash
# Sanju Security OS - PHASE 5: bootable ISO configuration
#  - boot menu (BIOS + UEFI): Live, Persistence, Encrypted persistence, Forensic mode, Safe graphics, To RAM
#  - forensic mode (write-blocks internal disks, no automount)
#  - persistence helper for USB sticks, ISO verification
# Usage: ./phase5-iso.sh ~/sanju-security-os
set -euo pipefail
ROOT="${1:-$HOME/sanju-security-os}"
[ -d "$ROOT/config" ] || { echo "Run Phase 1 first"; exit 1; }
cd "$ROOT"

INC=config/includes.chroot
BL=config/bootloaders
mkdir -p scripts docs config/hooks/normal $INC/usr/local/sbin $INC/etc/systemd/system

# ------------------------------------------------------------ 1. persistence is now a menu choice, not default
sed -i 's/ splash persistence username=/ splash username=/' scripts/02-configure.sh
grep -q 'splash username=' scripts/02-configure.sh && echo "02-configure.sh: persistence removed from default boot line"

# ------------------------------------------------------------ 2. bootloader templates
if [ ! -d "$BL" ]; then
  [ -d /usr/share/live/build/bootloaders ] || { echo "Install live-build first (Phase 1)"; exit 1; }
  mkdir -p "$BL"; cp -r /usr/share/live/build/bootloaders/. "$BL/"
fi

SYS_CFG=$(mktemp); GRUB_CFG=$(mktemp)
cat > "$SYS_CFG" <<'EOF'
label sanju-live
	menu label ^Sanju Security OS (Live)
	menu default
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@

label sanju-persistence
	menu label Live with ^persistence
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@ persistence

label sanju-encrypted
	menu label Live with ^encrypted persistence
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@ persistence persistence-encryption=luks

label sanju-forensic
	menu label ^Forensic mode (write-block internal disks, no automount)
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@ noswap sanju.forensic=1

label sanju-safe
	menu label Safe ^graphics (nomodeset)
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@ nomodeset

label sanju-toram
	menu label Load to ^RAM (can remove USB afterwards)
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@ toram
EOF
cat > "$GRUB_CFG" <<'EOF'
menuentry "Sanju Security OS (Live)" {
	linux  @LINUX@ @APPEND_LIVE@
	initrd @INITRD@
}
menuentry "Live with persistence" {
	linux  @LINUX@ @APPEND_LIVE@ persistence
	initrd @INITRD@
}
menuentry "Live with encrypted persistence" {
	linux  @LINUX@ @APPEND_LIVE@ persistence persistence-encryption=luks
	initrd @INITRD@
}
menuentry "Forensic mode (write-block internal disks, no automount)" {
	linux  @LINUX@ @APPEND_LIVE@ noswap sanju.forensic=1
	initrd @INITRD@
}
menuentry "Safe graphics (nomodeset)" {
	linux  @LINUX@ @APPEND_LIVE@ nomodeset
	initrd @INITRD@
}
menuentry "Load to RAM (can remove USB afterwards)" {
	linux  @LINUX@ @APPEND_LIVE@ toram
	initrd @INITRD@
}
EOF

found=0
while IFS= read -r f; do
  found=1
  case "$f" in
    *grub*) cp "$GRUB_CFG" "$f"; echo "grub menu written:     $f" ;;
    *)      cp "$SYS_CFG"  "$f"; echo "syslinux menu written: $f" ;;
  esac
done < <(find "$BL" -name 'live.cfg.in')
rm -f "$SYS_CFG" "$GRUB_CFG"
[ "$found" = 1 ] || echo "WARNING: no live.cfg.in found under $BL - see troubleshooting in the guide"

# Menu title (syslinux)
find "$BL" -type f \( -name '*.cfg' -o -name '*.cfg.in' \) -path '*syslinux*' \
  -exec sed -i 's/^menu title.*/menu title SANJU SECURITY OS/' {} \; 2>/dev/null || true

# ------------------------------------------------------------ 3. forensic mode
cat > $INC/usr/local/sbin/sanju-forensic-mode <<'EOF'
#!/bin/sh
# Forensic mode: write-block every disk except the live medium, stop automounting.
src=$(findmnt -n -o SOURCE /run/live/medium 2>/dev/null)
live_disk=""
[ -n "$src" ] && live_disk=$(lsblk -no pkname "$src" 2>/dev/null | head -1)

for d in /sys/block/*; do
  n=$(basename "$d")
  case "$n" in loop*|ram*|sr*|zram*|dm-*|md*) continue ;; esac
  [ "$n" = "$live_disk" ] && continue
  blockdev --setro "/dev/$n" 2>/dev/null
  for p in "$d"/"$n"*; do
    [ -e "$p" ] && blockdev --setro "/dev/$(basename "$p")" 2>/dev/null
  done
  logger -t sanju-forensic "write-blocked /dev/$n"
done

swapoff -a 2>/dev/null
systemctl stop udisks2.service 2>/dev/null
systemctl mask --runtime udisks2.service 2>/dev/null
touch /run/sanju-forensic-mode
exit 0
EOF
chmod +x $INC/usr/local/sbin/sanju-forensic-mode

# helper for devices plugged in later (evidence drives)
cat > $INC/usr/local/sbin/sanju-writeblock <<'EOF'
#!/bin/sh
# Usage: sudo sanju-writeblock on|off|status /dev/sdX
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
case "$1" in
  on)     blockdev --setro "$2" && echo "$2 is now READ-ONLY" ;;
  off)    blockdev --setrw "$2" && echo "$2 is now READ-WRITE" ;;
  status) blockdev --getro "$2" | sed 's/^1$/read-only/;s/^0$/read-write/' ;;
  *)      echo "usage: sanju-writeblock on|off|status /dev/sdX"; exit 1 ;;
esac
EOF
chmod +x $INC/usr/local/sbin/sanju-writeblock

cat > $INC/etc/systemd/system/sanju-forensic-mode.service <<'EOF'
[Unit]
Description=Sanju forensic mode (write-block internal disks, no automount)
ConditionKernelCommandLine=sanju.forensic=1
After=local-fs.target systemd-udevd.service
Before=display-manager.service udisks2.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/sanju-forensic-mode

[Install]
WantedBy=multi-user.target
EOF

cat > config/hooks/normal/0400-sanju-forensic.hook.chroot <<'EOF'
#!/bin/sh
set -e
systemctl enable sanju-forensic-mode.service
EOF
chmod +x config/hooks/normal/0400-sanju-forensic.hook.chroot

# ------------------------------------------------------------ 4. ISO verification
cat > scripts/08-verify-iso.sh <<'EOF'
#!/usr/bin/env bash
# Checks the built ISO: size, checksum, BIOS+UEFI boot entries, boot menu labels.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ISO="${1:-$HERE/build/sanju-security-os-0.1-amd64.iso}"
[ -f "$ISO" ] || { echo "ISO not found: $ISO"; exit 1; }
echo "== Size";     du -h "$ISO" | cut -f1
echo "== SHA-256";  sha256sum "$ISO"
[ -f "$ISO.sha256" ] && (cd "$(dirname "$ISO")" && sha256sum -c "$(basename "$ISO").sha256")
echo "== Boot entries (expect a BIOS and a UEFI entry)"
xorriso -indev "$ISO" -report_el_torito plain 2>/dev/null | grep -Ei 'El Torito (boot img|catalog)|BIOS|UEFI|efi' || true
echo "== Hybrid partition table (USB boot)"
fdisk -l "$ISO" 2>/dev/null | grep -E '^Disklabel|^'"$ISO" || true
echo "== Boot menu labels"
T=$(mktemp -d)
for f in /isolinux/live.cfg /boot/grub/live.cfg /boot/grub/grub.cfg /EFI/boot/grub.cfg; do
  xorriso -osirrox on -indev "$ISO" -extract "$f" "$T/$(echo "$f" | tr / _)" >/dev/null 2>&1 || true
done
grep -hiE 'menu label|^menuentry' "$T"/* 2>/dev/null || echo "(menu files not found at the usual paths)"
rm -rf "$T"
EOF
chmod +x scripts/08-verify-iso.sh

# ------------------------------------------------------------ 5. persistence helper for USB sticks
cat > scripts/09-make-persistence.sh <<'EOF'
#!/usr/bin/env bash
# Adds a persistence partition to a USB stick that already holds the Sanju ISO (written with dd/Rufus DD mode).
# Usage: sudo ./09-make-persistence.sh /dev/sdX [--encrypt]
set -euo pipefail
DEV="${1:-}"; ENC="${2:-}"
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
[ -b "$DEV" ] && [ "$(lsblk -dn -o TYPE "$DEV")" = "disk" ] || { echo "Give a WHOLE disk, e.g. /dev/sdb"; exit 1; }
ROOTDISK=$(lsblk -no pkname "$(findmnt -n -o SOURCE /)" 2>/dev/null | head -1 || true)
[ "$(basename "$DEV")" != "$ROOTDISK" ] || { echo "Refusing: that is the system disk."; exit 1; }
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL "$DEV"
read -rp "Add a persistence partition on $DEV (existing partitions are kept)? Type YES: " a
[ "$a" = "YES" ] || exit 1
umount "$DEV"?* 2>/dev/null || true

END=$(parted -ms "$DEV" unit MiB print | tail -n +3 | cut -d: -f3 | tr -d 'MiB' | sort -n | tail -1)
parted -s "$DEV" mkpart primary ext4 "${END}MiB" 100%
partprobe "$DEV"; sleep 2
NEW=$(lsblk -lnpo NAME "$DEV" | tail -1)
echo "New partition: $NEW"

MNT=$(mktemp -d)
if [ "$ENC" = "--encrypt" ]; then
  cryptsetup luksFormat "$NEW"
  cryptsetup luksOpen "$NEW" sanju-persist
  mkfs.ext4 -F -L persistence /dev/mapper/sanju-persist
  mount /dev/mapper/sanju-persist "$MNT"
  echo "/ union" > "$MNT/persistence.conf"
  umount "$MNT"; cryptsetup luksClose sanju-persist
  echo "Encrypted persistence ready. Boot: 'Live with encrypted persistence' and enter your passphrase."
else
  mkfs.ext4 -F -L persistence "$NEW"
  mount "$NEW" "$MNT"
  echo "/ union" > "$MNT/persistence.conf"
  umount "$MNT"
  echo "Persistence ready. Boot: 'Live with persistence'."
fi
rmdir "$MNT"
EOF
chmod +x scripts/09-make-persistence.sh

# ------------------------------------------------------------ docs
cat > docs/iso-and-boot.md <<'EOF'
# ISO, boot menu and persistence (Phase 5)
Boot menu (BIOS and UEFI): Live | Live + persistence | Live + encrypted persistence |
Forensic mode | Safe graphics | Load to RAM.

Forensic mode (kernel option sanju.forensic=1): every disk except the live USB is set
read-only at boot, swap is off, udisks2 automounting is stopped. Later-plugged drives:
  sudo sanju-writeblock on /dev/sdX
Note: GNOME Disks needs udisks2 and will not work in this mode; use Guymager, ddrescue, dc3dd.

Persistence on USB:
  1. dd / Rufus (DD mode) the ISO to the stick
  2. sudo ./scripts/09-make-persistence.sh /dev/sdX            (plain)
     sudo ./scripts/09-make-persistence.sh /dev/sdX --encrypt  (LUKS)
  3. boot the matching menu entry

Verify an ISO: ./scripts/08-verify-iso.sh
Secure Boot: this ISO is unsigned - turn Secure Boot off in firmware setup.
EOF

echo
echo "Phase 5 files created. Rebuild:"
echo "  ./scripts/02-configure.sh && ./scripts/03-build.sh && ./scripts/08-verify-iso.sh"
