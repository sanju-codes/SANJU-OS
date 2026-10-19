#!/usr/bin/env bash
# Runs INSIDE WSL Debian. Called by sanju-build.bat with the WSL path of the folder holding the phase scripts.
set -euo pipefail
WINDIR="${1:?usage: sanju-wsl-build.sh <folder-with-phase-scripts>}"
PROJ="$HOME/sanju-security-os"
cd "$WINDIR"
sed -i 's/\r$//' phase*.sh

# passwordless sudo for this WSL user only (so the long build doesn't stop for a password)
if ! sudo -n true 2>/dev/null; then
  echo "Debian password needed once:"
  sudo bash -c "echo '$USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sanju-build && chmod 440 /etc/sudoers.d/sanju-build"
fi

# Phases 1-4 (generate project files) - only the first time
if [ ! -d "$PROJ/scripts" ]; then
  for p in phase1-bootstrap.sh phase2-branding.sh phase3-security-center.sh phase4-tools.sh; do
    bash "./$p" "$PROJ"
  done
fi

# Phase 2b (Parrot-style panel + categorized menu) - safe to re-run every time
if [ -f "$WINDIR/phase2b-parrot-style.sh" ]; then
  bash "$WINDIR/phase2b-parrot-style.sh" "$PROJ"
else
  echo "NOTE: phase2b-parrot-style.sh not found in $WINDIR - skipping Parrot-style panel"
fi

# Refocus: Cybersecurity + Forensics + Data Recovery + SIGINT/RF catalog (safe to re-run)
if [ -f "$WINDIR/refocus-sigint-recovery.sh" ]; then
  bash "$WINDIR/refocus-sigint-recovery.sh" "$PROJ"
fi

cd "$PROJ"
./scripts/01-install-deps.sh
./scripts/07-apply-branding.sh
bash "$WINDIR/phase5-iso.sh" "$PROJ"
./scripts/02-configure.sh
./scripts/03-build.sh
cp build/*.iso build/*.sha256 "$WINDIR/"
echo "BUILD DONE"
