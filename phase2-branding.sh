#!/usr/bin/env bash
# Sanju Security OS - PHASE 2: branding, theme, XFCE desktop
# Usage: ./phase2-branding.sh ~/sanju-security-os
set -euo pipefail
ROOT="${1:-$HOME/sanju-security-os}"
[ -d "$ROOT/config" ] || { echo "Run Phase 1 first ($ROOT/config missing)"; exit 1; }
cd "$ROOT"

INC=config/includes.chroot
SK=$INC/etc/skel
XF=$SK/.config/xfce4
mkdir -p scripts wallpapers themes "$XF/xfconf/xfce-perchannel-xml" "$XF/panel" "$SK/Desktop" \
  "$SK/.config/gtk-3.0" "$XF/terminal" "$INC/usr/local/bin" "$INC/etc/lightdm" \
  config/hooks/normal config/package-lists

# ------------------------------------------------------------ logo (original)
cat > themes/sanju-logo.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <g transform="translate(128,128) scale(0.72)">
    <path d="M0 -150 L120 -105 L120 20 C120 95 60 140 0 165 C-60 140 -120 95 -120 20 L-120 -105 Z"
          fill="#0b1118" stroke="#00e5ff" stroke-width="10" stroke-linejoin="round"/>
    <path d="M38 -55 C38 -85 -42 -85 -42 -40 C-42 5 42 -5 42 45 C42 90 -38 90 -38 55"
          fill="none" stroke="#e6f1ff" stroke-width="16" stroke-linecap="round"/>
    <circle cx="-85" cy="-70" r="7" fill="#00e5ff"/><circle cx="85" cy="70" r="7" fill="#00e5ff"/>
    <path d="M-85 -70 L-60 -70 M85 70 L60 70" stroke="#00e5ff" stroke-width="5"/>
  </g>
</svg>
SVG

# ------------------------------------------------------------ wallpaper 1920x1080
cat > wallpapers/sanju-wallpaper.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
  <defs>
    <radialGradient id="bg" cx="50%" cy="45%" r="75%">
      <stop offset="0" stop-color="#14202c"/><stop offset="1" stop-color="#05080c"/>
    </radialGradient>
    <pattern id="grid" width="60" height="60" patternUnits="userSpaceOnUse">
      <path d="M60 0 L0 0 0 60" fill="none" stroke="#00e5ff" stroke-opacity="0.05" stroke-width="1"/>
    </pattern>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#grid)"/>
  <g stroke="#00e5ff" stroke-opacity="0.25" stroke-width="2" fill="none">
    <path d="M0 200 L300 200 L360 260 L700 260"/><path d="M1920 880 L1600 880 L1540 820 L1250 820"/>
    <path d="M0 860 L220 860 L280 920 L520 920"/><path d="M1920 220 L1650 220 L1590 160 L1380 160"/>
  </g>
  <g fill="#00e5ff" fill-opacity="0.5"><circle cx="700" cy="260" r="5"/><circle cx="1250" cy="820" r="5"/>
    <circle cx="520" cy="920" r="5"/><circle cx="1380" cy="160" r="5"/></g>
  <g transform="translate(960,440) scale(1.25)">
    <path d="M0 -150 L120 -105 L120 20 C120 95 60 140 0 165 C-60 140 -120 95 -120 20 L-120 -105 Z"
          fill="#0b1118" fill-opacity="0.85" stroke="#00e5ff" stroke-width="6" stroke-linejoin="round"/>
    <path d="M38 -55 C38 -85 -42 -85 -42 -40 C-42 5 42 -5 42 45 C42 90 -38 90 -38 55"
          fill="none" stroke="#e6f1ff" stroke-width="14" stroke-linecap="round"/>
  </g>
  <text x="960" y="760" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-size="60"
        font-weight="bold" letter-spacing="14" fill="#e6f1ff">SANJU SECURITY OS</text>
  <text x="960" y="812" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-size="24"
        letter-spacing="8" fill="#00e5ff" fill-opacity="0.85">Security • Forensics • Recovery</text>
</svg>
SVG

# ------------------------------------------------------------ boot splash 640x480
cat > wallpapers/sanju-boot.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="640" height="480" viewBox="0 0 640 480">
  <rect width="640" height="480" fill="#05080c"/>
  <g transform="translate(320,120) scale(0.5)">
    <path d="M0 -150 L120 -105 L120 20 C120 95 60 140 0 165 C-60 140 -120 95 -120 20 L-120 -105 Z"
          fill="#0b1118" stroke="#00e5ff" stroke-width="10" stroke-linejoin="round"/>
    <path d="M38 -55 C38 -85 -42 -85 -42 -40 C-42 5 42 -5 42 45 C42 90 -38 90 -38 55"
          fill="none" stroke="#e6f1ff" stroke-width="16" stroke-linecap="round"/>
  </g>
  <text x="320" y="240" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-size="26"
        font-weight="bold" letter-spacing="6" fill="#e6f1ff">SANJU SECURITY OS</text>
  <text x="320" y="266" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-size="12"
        letter-spacing="3" fill="#00e5ff">Security • Forensics • Recovery</text>
</svg>
SVG

# ------------------------------------------------------------ asset renderer
cat > scripts/07-apply-branding.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"
command -v rsvg-convert >/dev/null || sudo apt-get install -y librsvg2-bin
INC=config/includes.chroot
mkdir -p $INC/usr/share/backgrounds/sanju $INC/usr/share/icons/hicolor/scalable/apps
rsvg-convert -w 1920 -h 1080 wallpapers/sanju-wallpaper.svg -o $INC/usr/share/backgrounds/sanju/sanju-wallpaper.png
cp $INC/usr/share/backgrounds/sanju/sanju-wallpaper.png $INC/usr/share/backgrounds/sanju/sanju-login.png
cp wallpapers/sanju-wallpaper.svg $INC/usr/share/backgrounds/sanju/
cp themes/sanju-logo.svg $INC/usr/share/icons/hicolor/scalable/apps/sanju-security-os.svg

# Boot screen: copy live-build's bootloader templates once, then swap the splash images
BL=config/bootloaders
if [ ! -d "$BL" ]; then
  mkdir -p "$BL"; cp -r /usr/share/live/build/bootloaders/. "$BL/"
fi
find "$BL" -name 'splash.svg' -exec cp wallpapers/sanju-boot.svg {} \;
find "$BL" -name 'splash.png' -exec rsvg-convert -w 640 -h 480 wallpapers/sanju-boot.svg -o {} \;
echo "Boot splash files replaced:"; find "$BL" -name 'splash.*'
chmod +x $INC/usr/local/bin/* 2>/dev/null || true
chmod +x $INC/etc/skel/Desktop/*.desktop
echo "Branding applied. Now run: ./scripts/02-configure.sh && ./scripts/03-build.sh"
SH
chmod +x scripts/07-apply-branding.sh

# ------------------------------------------------------------ packages
cat > config/package-lists/sanju-desktop.list.chroot <<'EOF'
arc-theme
papirus-icon-theme
librsvg2-common
fonts-noto-color-emoji
fonts-dejavu
zenity
EOF

# ------------------------------------------------------------ placeholder launcher
cat > $INC/usr/local/bin/sanju-launch <<'SH'
#!/bin/sh
# Placeholder until Phase 3 installs the Sanju Security Center GUI.
CAT="${1:-home}"
if command -v sanju-security-center >/dev/null 2>&1; then
  exec sanju-security-center --category "$CAT"
fi
zenity --info --title="Sanju Security OS" --width=320 \
  --text="<b>$CAT</b>\n\nSanju Security Center arrives in Phase 3." 2>/dev/null
SH
chmod +x $INC/usr/local/bin/sanju-launch

# ------------------------------------------------------------ desktop shortcuts
mk_desktop() { # file name exec icon
  cat > "$1" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$2
Exec=$3
Icon=$4
Terminal=false
Categories=Sanju;
EOF
  chmod +x "$1"
}
D=$SK/Desktop
mk_desktop $D/recon.desktop       "🔎 Recon"            "sanju-launch recon"     system-search
mk_desktop $D/audit.desktop       "🛡 Security Audit"   "sanju-launch audit"     security-high
mk_desktop $D/web.desktop         "🌐 Web Security"     "sanju-launch web"       web-browser
mk_desktop $D/wifi.desktop        "📡 Wi-Fi Audit"      "sanju-launch wifi"      network-wireless
mk_desktop $D/forensics.desktop   "💾 Digital Forensics" "sanju-launch forensics" drive-harddisk
mk_desktop $D/repair.desktop      "🔧 System Repair"    "sanju-launch recovery"  preferences-system
mk_desktop $D/analysis.desktop    "📊 Analysis"         "sanju-launch analysis"  utilities-system-monitor
mk_desktop $D/settings.desktop    "⚙ Settings"         "xfce4-settings-manager" preferences-desktop

# ------------------------------------------------------------ panel launchers
i=3
for row in "Security|sanju-launch audit|security-high" "Forensics|sanju-launch forensics|drive-harddisk" \
           "Network|sanju-launch recon|network-workgroup" "System|xfce4-settings-manager|preferences-system" \
           "Terminal|xfce4-terminal|utilities-terminal"; do
  IFS='|' read -r n e ic <<<"$row"
  mkdir -p "$XF/panel/launcher-$i"
  mk_desktop "$XF/panel/launcher-$i/1700000000$i.desktop" "$n" "$e" "$ic"
  i=$((i+1))
done

# ------------------------------------------------------------ top panel
cat > $XF/xfconf/xfce-perchannel-xml/xfce4-panel.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="34"/>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.043"/><value type="double" value="0.067"/>
        <value type="double" value="0.094"/><value type="double" value="0.96"/>
      </property>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/><value type="int" value="2"/>
        <value type="int" value="3"/><value type="int" value="4"/><value type="int" value="5"/>
        <value type="int" value="6"/><value type="int" value="7"/>
        <value type="int" value="8"/><value type="int" value="9"/><value type="int" value="10"/>
        <value type="int" value="11"/><value type="int" value="12"/><value type="int" value="13"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-title" type="string" value="SANJU SECURITY OS"/>
      <property name="show-button-title" type="bool" value="true"/>
      <property name="button-icon" type="string" value="sanju-security-os"/>
    </property>
    <property name="plugin-2" type="string" value="separator"/>
    <property name="plugin-3" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000003.desktop"/></property>
    </property>
    <property name="plugin-4" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000004.desktop"/></property>
    </property>
    <property name="plugin-5" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000005.desktop"/></property>
    </property>
    <property name="plugin-6" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000006.desktop"/></property>
    </property>
    <property name="plugin-7" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000007.desktop"/></property>
    </property>
    <property name="plugin-8" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-9" type="string" value="systray"/>
    <property name="plugin-10" type="string" value="pulseaudio"/>
    <property name="plugin-11" type="string" value="power-manager-plugin"/>
    <property name="plugin-12" type="string" value="clock">
      <property name="digital-format" type="string" value="%a %d %b  %H:%M"/>
    </property>
    <property name="plugin-13" type="string" value="actions">
      <property name="appearance" type="uint" value="1"/>
    </property>
  </property>
</channel>
XML

# ------------------------------------------------------------ theme / WM / terminal
cat > $XF/xfconf/xfce-perchannel-xml/xsettings.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Sans 10"/>
    <property name="MonospaceFontName" type="string" value="Monospace 11"/>
  </property>
</channel>
XML

cat > $XF/xfconf/xfce-perchannel-xml/xfwm4.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Arc-Dark"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XML

cat > $SK/.config/gtk-3.0/gtk.css <<'CSS'
@define-color sanju_accent #00e5ff;
selection { background-color: #00a9bd; color: #ffffff; }
CSS

cat > $XF/terminal/terminalrc <<'EOF'
[Configuration]
FontName=Monospace 11
ColorForeground=#d6e4f0
ColorBackground=#0b1118
ColorCursor=#00e5ff
MiscDefaultGeometry=110x32
ScrollingLines=10000
EOF

# ------------------------------------------------------------ login screen
cat > $INC/etc/lightdm/lightdm-gtk-greeter.conf <<'EOF'
[greeter]
background=/usr/share/backgrounds/sanju/sanju-login.png
theme-name=Arc-Dark
icon-theme-name=Papirus-Dark
font-name=Sans 11
default-user-image=/usr/share/icons/hicolor/scalable/apps/sanju-security-os.svg
clock-format=%a %d %b  %H:%M
indicators=~host;~spacer;~clock;~spacer;~session;~a11y;~power
EOF

# ------------------------------------------------------------ hook: wallpaper for any monitor name
cat > config/hooks/normal/0200-sanju-branding.hook.chroot <<'SH'
#!/bin/sh
set -e
X=/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p "$X"
{
echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<channel name="xfce4-desktop" version="1.0">'
echo ' <property name="backdrop" type="empty">'
echo '  <property name="screen0" type="empty">'
for m in monitor0 monitorVirtual-1 monitorVirtual1 monitorVGA-1 monitorVGA1 monitorHDMI-1 \
         monitorHDMI1 monitoreDP-1 monitoreDP1 monitorLVDS-1 monitorLVDS1 monitorDP-1; do
  echo "   <property name=\"$m\" type=\"empty\">"
  echo '    <property name="workspace0" type="empty">'
  echo '     <property name="color-style" type="int" value="0"/>'
  echo '     <property name="image-style" type="int" value="5"/>'
  echo '     <property name="last-image" type="string" value="/usr/share/backgrounds/sanju/sanju-wallpaper.png"/>'
  echo '    </property>'
  echo '   </property>'
done
echo '  </property>'
echo ' </property>'
echo ' <property name="desktop-icons" type="empty">'
echo '  <property name="style" type="int" value="2"/>'
echo '  <property name="file-icons" type="empty">'
echo '   <property name="show-home" type="bool" value="false"/>'
echo '   <property name="show-filesystem" type="bool" value="false"/>'
echo '   <property name="show-trash" type="bool" value="false"/>'
echo '  </property>'
echo ' </property>'
echo '</channel>'
} > "$X/xfce4-desktop.xml"
chmod +x /etc/skel/Desktop/*.desktop
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
SH
chmod +x config/hooks/normal/0200-sanju-branding.hook.chroot

echo "Phase 2 files created in $ROOT"
echo "Next: ./scripts/07-apply-branding.sh && ./scripts/02-configure.sh && ./scripts/03-build.sh"
