#!/usr/bin/env bash
# Sanju Security OS - PHASE 4: tools (network/forensics/recovery/authorized testing) + terminal
# Usage: ./phase4-tools.sh ~/sanju-security-os
set -euo pipefail
ROOT="${1:-$HOME/sanju-security-os}"
[ -d "$ROOT/config" ] || { echo "Run Phase 1 first"; exit 1; }
cd "$ROOT"

INC=config/includes.chroot
mkdir -p config/package-lists config/hooks/normal docs \
  $INC/usr/share/sanju/terminal $INC/usr/share/sanju $INC/usr/share/applications $INC/etc/skel

# ------------------------------------------------------------ CORE packages (common Debian 12 packages)
cat > config/package-lists/sanju-tools-core.list.chroot <<'EOF'
# --- recon / network diagnostics
nmap
bind9-dnsutils
whois
traceroute
mtr-tiny
iproute2
iputils-ping
curl
openssl
net-tools
tcpdump
iftop
iperf3
ethtool
wireshark
# --- wifi info
iw
wireless-tools
wavemon
rfkill
# --- recovery / disks
gparted
smartmontools
testdisk
gddrescue
ntfs-3g
efibootmgr
grub-common
dosfstools
rsync
lvm2
gnome-disk-utility
# --- analysis / forensics basics
sleuthkit
foremost
libimage-exiftool-perl
xxd
ghex
# --- system audit
lynis
rkhunter
chkrootkit
debsecan
# --- utilities
htop
ncdu
xfce4-taskmanager
EOF

# ------------------------------------------------------------ OPTIONAL packages (installed if available)
# Specialized tools: a missing/renamed package is skipped and logged, it never breaks the build.
cat > $INC/usr/share/sanju/optional-packages.txt <<'EOF'
nikto
sqlmap
whatweb
aircrack-ng
kismet
guymager
dc3dd
ewf-tools
bulk-extractor
binwalk
yara
lnav
hashdeep
volatility3
plaso
openscap-scanner
EOF

cat > config/hooks/normal/0300-sanju-optional-tools.hook.chroot <<'SH'
#!/bin/sh
# Installs each optional package on its own; logs the ones that could not be installed.
export DEBIAN_FRONTEND=noninteractive
LIST=/usr/share/sanju/optional-packages.txt
MISSING=/usr/share/sanju/missing-packages.txt
: > "$MISSING"
apt-get update || true
while read -r pkg; do
  [ -z "$pkg" ] && continue
  if apt-get install -y --no-install-recommends "$pkg"; then
    echo "OPTIONAL OK: $pkg"
  else
    echo "OPTIONAL MISSING: $pkg"
    echo "$pkg" >> "$MISSING"
  fi
done < "$LIST"
apt-get clean
rm -rf /var/lib/apt/lists/*
exit 0
SH
chmod +x config/hooks/normal/0300-sanju-optional-tools.hook.chroot

# ------------------------------------------------------------ terminal: shared shell setup
cat > $INC/usr/share/sanju/terminal/sanju-shell.sh <<'SHEOF'
# Sanju Security OS shell environment. Profile chosen by SANJU_PROFILE: admin (default) | pentest
SANJU_PROFILE="${SANJU_PROFILE:-admin}"
export SANJU_PROFILE

# ---- common aliases
alias ls='ls --color=auto'; alias ll='ls -lah'; alias la='ls -A'; alias ..='cd ..'
alias grep='grep --color=auto'
alias myip='ip -br address'
alias ports='ss -tulpn'
alias disks='lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT'
alias hashit='sha256sum'
alias health='sudo smartctl -H'
alias update='sudo apt update && sudo apt full-upgrade'
alias sc='sanju-security-center'

# ---- prompt
if [ "$(id -u)" -eq 0 ]; then U='\[\e[1;31m\]'; else U='\[\e[1;36m\]'; fi
if [ "$SANJU_PROFILE" = "pentest" ]; then
  TAG='\[\e[1;33m\][SEC-TEST]\[\e[0m\] '
else
  TAG=''
fi
PS1="${TAG}${U}\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\\$ "

# ---- profile specific helpers
if [ "$SANJU_PROFILE" = "pentest" ]; then
  # Create a structured, documented engagement folder
  newengagement() {
    [ -n "$1" ] || { echo "usage: newengagement <name>"; return 1; }
    d="$HOME/engagements/$1"
    mkdir -p "$d"/notes "$d"/evidence "$d"/reports
    [ -f "$d/SCOPE.txt" ] || printf 'Client/owner:\nWritten authorization (ref/date):\nIn-scope targets:\nOut-of-scope:\nTest window:\n' > "$d/SCOPE.txt"
    cd "$d" && echo "Fill in $d/SCOPE.txt before testing."
  }
  # Scope-checked scan: asks for explicit confirmation before touching a target
  scan-host() {
    [ -n "$1" ] || { echo "usage: scan-host <target> [extra nmap args]"; return 1; }
    t="$1"; shift
    printf 'Do you OWN %s or have WRITTEN permission to test it? Type yes: ' "$t"
    read -r a; [ "$a" = "yes" ] || { echo "Aborted."; return 1; }
    nmap -sV -T3 "$@" "$t"
  }
fi

# ---- banner (once per terminal)
sanju_banner() {
  local net; net="$(hostname -I 2>/dev/null | awk '{print $1}')"; [ -n "$net" ] || net="offline"
  printf '\e[1;36m'
  echo "========================================"
  echo "SANJU SECURITY OS"
  echo "Security • Forensics • Recovery"
  echo "========================================"
  printf '\e[0m'
  echo "User:    $(id -un)"
  echo "Host:    $(hostname)"
  echo "Kernel:  $(uname -r)"
  echo "Network: $net"
  echo "Profile: $SANJU_PROFILE"
  if [ "$SANJU_PROFILE" = "pentest" ]; then
    printf '\e[1;33m'
    echo "AUTHORIZED TESTING ONLY - own systems or written permission."
    printf '\e[0m'
    echo "Helpers: newengagement <name>, scan-host <target>"
  fi
  echo
}
sanju_banner
SHEOF

# skel .bashrc
cat > $INC/etc/skel/.bashrc <<'EOF'
case $- in *i*) ;; *) return ;; esac
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
[ -f /usr/share/sanju/terminal/sanju-shell.sh ] && . /usr/share/sanju/terminal/sanju-shell.sh
EOF

# ------------------------------------------------------------ two terminal profiles in the menu
cat > $INC/usr/share/applications/sanju-terminal-admin.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Sanju Terminal (Administration)
Comment=Normal administration shell
Exec=xfce4-terminal --title="Sanju Terminal - Admin" -x env SANJU_PROFILE=admin bash
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF
cat > $INC/usr/share/applications/sanju-terminal-pentest.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Sanju Terminal (Authorized Security Testing)
Comment=Shell with engagement helpers and scope checks
Exec=xfce4-terminal --title="Sanju Terminal - SECURITY TESTING" -x env SANJU_PROFILE=pentest bash
Icon=security-high
Terminal=false
Categories=System;Security;TerminalEmulator;
EOF

# ------------------------------------------------------------ docs
cat > docs/tools.md <<'EOF'
# Tool categories (Phase 4)
Core list : config/package-lists/sanju-tools-core.list.chroot  (build fails if a package is missing)
Optional  : config/includes.chroot/usr/share/sanju/optional-packages.txt (skipped + logged if missing)
On the live system, skipped packages are listed in /usr/share/sanju/missing-packages.txt

Recon      nmap, dig, whois, traceroute, mtr, ip, ping
Network    wireshark, tcpdump, iftop, ss, iperf3, ethtool
Web        nikto, sqlmap, whatweb, curl, openssl   (authorized targets only)
Wi-Fi      iw, wavemon, aircrack-ng, kismet        (own/authorized networks only)
Forensics  guymager, ddrescue, dc3dd, ewf-tools, sleuthkit, photorec, foremost,
           bulk-extractor, volatility3, plaso
Recovery   gparted, smartmontools, testdisk, ntfs-3g, efibootmgr, grub, rsync
Analysis   hashdeep, exiftool, binwalk, yara, lnav, ghex
Audit      lynis, rkhunter, chkrootkit, debsecan, openscap

Terminal profiles: "Sanju Terminal (Administration)" and
"(Authorized Security Testing)" - the second adds newengagement and scope-checked scan-host.
EOF

echo "Phase 4 files created."
echo "Next: ./scripts/02-configure.sh && ./scripts/03-build.sh"
echo "After build, check 'OPTIONAL MISSING' lines in build/build.log"
