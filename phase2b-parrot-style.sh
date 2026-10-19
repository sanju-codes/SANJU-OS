#!/usr/bin/env bash
# Sanju Security OS - PHASE 2b: Parrot-style workflow
#   top panel:  Applications | Places | System  + quick launchers, tray on the right
#   Applications menu = categorized security menu generated from the Security Center catalog
# Original look and naming (no Parrot logos/artwork). Run AFTER phases 2-4.
# Usage: ./phase2b-parrot-style.sh ~/sanju-security-os
set -euo pipefail
ROOT="${1:-$HOME/sanju-security-os}"
[ -f "$ROOT/config/includes.chroot/usr/lib/sanju-security-center/catalog.json" ] || { echo "Run phases 2-4 first"; exit 1; }
cd "$ROOT"
INC=config/includes.chroot
XF=$INC/etc/skel/.config/xfce4
mkdir -p $INC/usr/local/bin config/hooks/normal $XF/xfconf/xfce-perchannel-xml $XF/panel

# ------------------------------------------------------------ sanju-run : safe launcher used by menu entries
cat > $INC/usr/local/bin/sanju-run <<'EOF'
#!/bin/sh
# usage: sanju-run gui|cli root|user auth|plain /path/to/tool
# Never runs scans: CLI tools open in a terminal showing --help only.
mode="$1"; root="$2"; auth="$3"; path="$4"
name=$(basename "$path")
if [ "$auth" = "auth" ]; then
  zenity --question --title="Open $name?" --width=360 \
    --text="This tool can probe systems or capture traffic.\nUse it only on systems and networks you own or have written permission to test.\n\nContinue?" || exit 0
fi
if [ "$mode" = "gui" ]; then
  if [ "$root" = "root" ]; then
    exec pkexec env DISPLAY="$DISPLAY" XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}" "$path"
  fi
  exec "$path"
fi
note=""; [ "$root" = "root" ] && note="Needs root: run it with sudo."
exec xfce4-terminal -T "$name" -x bash -c "clear; echo '== $name =='; echo 'Authorized use only: systems you own or have written permission to test.'; echo '$note'; echo; '$path' --help 2>&1 | head -30; echo; echo 'Nothing has been run. Type your command below.'; exec bash"
EOF
chmod +x $INC/usr/local/bin/sanju-run

# ------------------------------------------------------------ menu generator (runs at build time, after tools are installed)
cat > $INC/usr/lib/sanju-security-center/gen_menu.py <<'EOF'
#!/usr/bin/env python3
"""Generate categorized menu entries for every INSTALLED tool in catalog.json."""
import json, os, re, shutil
from xml.sax.saxutils import escape

APP = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("SANJU_OUT", "")          # test prefix; empty in the real image
EXTRA = "/usr/sbin:/sbin:/usr/local/sbin"


def P(p):
    return OUT + p


def find(spec):
    for b in spec.split("|"):
        p = shutil.which(b, path=os.environ.get("PATH", "") + ":" + EXTRA)
        if p:
            return p


data = json.load(open(os.path.join(APP, "catalog.json"), encoding="utf-8"))
for d in ("/usr/share/applications", "/usr/share/desktop-directories", "/etc/xdg/menus"):
    os.makedirs(P(d), exist_ok=True)

layout, submenus = [], []
for c in data["categories"]:
    cat = "X-Sanju-" + c["id"]
    n = 0
    for t in c["tools"]:
        path = find(t["bin"])
        if not path:
            continue
        slug = re.sub(r"[^a-z0-9]+", "-", t["name"].lower()).strip("-")
        cmd = "sanju-run {} {} {} {}".format(
            t["type"], "root" if t.get("root") else "user",
            "auth" if t.get("authorized") else "plain", path)
        with open(P(f"/usr/share/applications/sanju-{c['id']}-{slug}.desktop"), "w", encoding="utf-8") as f:
            f.write("[Desktop Entry]\nVersion=1.0\nType=Application\n"
                    f"Name={t['name']}\nComment={t['desc']}\nExec={cmd}\nIcon={c['icon']}\n"
                    f"Terminal=false\nCategories={cat};\n")
        n += 1
    if n:
        with open(P(f"/usr/share/desktop-directories/sanju-{c['id']}.directory"), "w", encoding="utf-8") as f:
            f.write(f"[Desktop Entry]\nVersion=1.0\nType=Directory\nName={c['title']}\nIcon={c['icon']}\n")
        layout.append(f"  <Menuname>{escape(c['title'])}</Menuname>")
        submenus.append(f"""  <Menu><Name>{escape(c['title'])}</Name><Directory>sanju-{c['id']}.directory</Directory>
    <Include><Category>{cat}</Category></Include></Menu>""")

# session entry used by the System menu
with open(P("/usr/share/applications/sanju-logout.desktop"), "w") as f:
    f.write("[Desktop Entry]\nVersion=1.0\nType=Application\nName=Log Out / Shut Down\n"
            "Exec=xfce4-session-logout\nIcon=system-log-out\nTerminal=false\nCategories=X-Sanju-session;\n")

HEAD = ('<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" '
        '"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">\n')

apps = HEAD + "<Menu>\n <Name>Applications</Name>\n <DefaultAppDirs/>\n <DefaultDirectoryDirs/>\n"
apps += " <Layout>\n" + "\n".join(layout) + """
  <Menuname>Internet</Menuname>
  <Menuname>Accessories</Menuname>
 </Layout>
""" + "\n".join(submenus) + """
  <Menu><Name>Internet</Name><Directory>xfce-network.directory</Directory>
    <Include><Or><Category>Network</Category><Category>WebBrowser</Category></Or></Include></Menu>
  <Menu><Name>Accessories</Name><Directory>xfce-accessories.directory</Directory>
    <Include><Category>Utility</Category></Include></Menu>
</Menu>
"""
open(P("/etc/xdg/menus/sanju-applications.menu"), "w", encoding="utf-8").write(apps)

system = HEAD + """<Menu>
 <Name>System</Name>
 <DefaultAppDirs/>
 <DefaultDirectoryDirs/>
  <Menu><Name>Preferences</Name><Directory>xfce-settings.directory</Directory>
    <Include><Category>Settings</Category></Include></Menu>
  <Menu><Name>Administration</Name><Directory>xfce-system.directory</Directory>
    <Include><And><Category>System</Category><Not><Category>Settings</Category></Not></And></Include></Menu>
  <Include><Filename>sanju-logout.desktop</Filename></Include>
</Menu>
"""
open(P("/etc/xdg/menus/sanju-system.menu"), "w", encoding="utf-8").write(system)
print("menu generated")
EOF
chmod +x $INC/usr/lib/sanju-security-center/gen_menu.py

cat > config/hooks/normal/0500-sanju-menu.hook.chroot <<'EOF'
#!/bin/sh
set -e
python3 /usr/lib/sanju-security-center/gen_menu.py
EOF
chmod +x config/hooks/normal/0500-sanju-menu.hook.chroot

# ------------------------------------------------------------ panel: Applications | Places | System | launchers ... tray
rm -rf $XF/panel/launcher-*
i=2
for row in "Firefox|firefox-esr|firefox-esr" "Terminal|xfce4-terminal|utilities-terminal" \
           "Files|thunar|system-file-manager" "Security Center|sanju-security-center|sanju-security-os"; do
  IFS='|' read -r n e ic <<<"$row"
  mkdir -p "$XF/panel/launcher-$((i+3))"
  printf '[Desktop Entry]\nVersion=1.0\nType=Application\nName=%s\nExec=%s\nIcon=%s\nTerminal=false\n' "$n" "$e" "$ic" \
    > "$XF/panel/launcher-$((i+3))/1700000000$((i+3)).desktop"
  i=$((i+1))
done

cat > $XF/xfconf/xfce-perchannel-xml/xfce4-panel.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.043"/><value type="double" value="0.067"/>
        <value type="double" value="0.094"/><value type="double" value="0.96"/>
      </property>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/><value type="int" value="2"/><value type="int" value="3"/>
        <value type="int" value="4"/><value type="int" value="5"/><value type="int" value="6"/>
        <value type="int" value="7"/><value type="int" value="8"/><value type="int" value="9"/>
        <value type="int" value="10"/><value type="int" value="11"/><value type="int" value="12"/>
        <value type="int" value="13"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-title" type="string" value="Applications"/>
      <property name="show-button-title" type="bool" value="true"/>
      <property name="button-icon" type="string" value="sanju-security-os"/>
      <property name="custom-menu" type="bool" value="true"/>
      <property name="custom-menu-file" type="string" value="/etc/xdg/menus/sanju-applications.menu"/>
    </property>
    <property name="plugin-2" type="string" value="directorymenu">
      <property name="base-directory" type="string" value="/home"/>
      <property name="icon-name" type="string" value="folder"/>
    </property>
    <property name="plugin-3" type="string" value="applicationsmenu">
      <property name="button-title" type="string" value="System"/>
      <property name="show-button-title" type="bool" value="true"/>
      <property name="button-icon" type="string" value="preferences-system"/>
      <property name="custom-menu" type="bool" value="true"/>
      <property name="custom-menu-file" type="string" value="/etc/xdg/menus/sanju-system.menu"/>
    </property>
    <property name="plugin-4" type="string" value="separator"/>
    <property name="plugin-5" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000005.desktop"/></property>
    </property>
    <property name="plugin-6" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000006.desktop"/></property>
    </property>
    <property name="plugin-7" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000007.desktop"/></property>
    </property>
    <property name="plugin-8" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="17000000008.desktop"/></property>
    </property>
    <property name="plugin-9" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-10" type="string" value="systray"/>
    <property name="plugin-11" type="string" value="pulseaudio"/>
    <property name="plugin-12" type="string" value="power-manager-plugin"/>
    <property name="plugin-13" type="string" value="clock">
      <property name="digital-format" type="string" value="%a %d %b  %H:%M"/>
    </property>
  </property>
</channel>
EOF
echo "Phase 2b done. Rebuild: ./scripts/02-configure.sh && ./scripts/03-build.sh"
