#!/usr/bin/env bash
# Sanju Security OS - PHASE 3: Sanju Security Center (Python + GTK3)
# Usage: ./phase3-security-center.sh ~/sanju-security-os
set -euo pipefail
ROOT="${1:-$HOME/sanju-security-os}"
[ -d "$ROOT/config" ] || { echo "Run Phase 1 first"; exit 1; }
cd "$ROOT"

APP=config/includes.chroot/usr/lib/sanju-security-center
mkdir -p "$APP" config/includes.chroot/usr/local/bin config/includes.chroot/usr/share/applications \
         config/package-lists docs

# ------------------------------------------------------------ packages
cat > config/package-lists/sanju-gui.list.chroot <<'EOF'
python3
python3-gi
gir1.2-gtk-3.0
python3-psutil
policykit-1
policykit-1-gnome
man-db
less
EOF

# ------------------------------------------------------------ tool catalog
cat > "$APP/catalog.json" <<'JSONEOF'
{
 "categories": [
  {"id":"recon","title":"Recon","subtitle":"Discovery, DNS, IP info","icon":"system-search","tools":[
   {"name":"Nmap","bin":"nmap","desc":"Network discovery and service enumeration","type":"cli","authorized":true},
   {"name":"dig","bin":"dig","desc":"DNS lookups and record queries","type":"cli"},
   {"name":"whois","bin":"whois","desc":"Domain and IP registration info","type":"cli"},
   {"name":"traceroute","bin":"traceroute","desc":"Show the network path to a host","type":"cli"},
   {"name":"mtr","bin":"mtr","desc":"Live path and latency diagnostics","type":"cli"},
   {"name":"ip","bin":"ip","desc":"Interface, address and route information","type":"cli"},
   {"name":"ping","bin":"ping","desc":"Host reachability check","type":"cli"}]},
  {"id":"network","title":"Network","subtitle":"Diagnostics, capture, config","icon":"network-workgroup","tools":[
   {"name":"Wireshark","bin":"wireshark","desc":"Packet capture and protocol analysis","type":"gui","root":true,"authorized":true},
   {"name":"tcpdump","bin":"tcpdump","desc":"Command-line packet capture","type":"cli","root":true,"authorized":true},
   {"name":"iftop","bin":"iftop","desc":"Live bandwidth per connection","type":"cli","root":true},
   {"name":"ss","bin":"ss","desc":"Sockets and listening ports","type":"cli"},
   {"name":"iperf3","bin":"iperf3","desc":"Throughput testing between your own hosts","type":"cli"},
   {"name":"ethtool","bin":"ethtool","desc":"Ethernet adapter settings and link state","type":"cli","root":true},
   {"name":"Network Connections","bin":"nm-connection-editor","desc":"Edit NetworkManager connections","type":"gui"},
   {"name":"nmtui","bin":"nmtui","desc":"Text UI for NetworkManager","type":"cli"}]},
  {"id":"web","title":"Web Security","subtitle":"Authorized web testing","icon":"web-browser","tools":[
   {"name":"Nikto","bin":"nikto","desc":"Web server configuration scanner","type":"cli","authorized":true},
   {"name":"sqlmap","bin":"sqlmap","desc":"SQL injection assessment (authorized targets only)","type":"cli","authorized":true},
   {"name":"WhatWeb","bin":"whatweb","desc":"Identify web technologies","type":"cli","authorized":true},
   {"name":"curl","bin":"curl","desc":"HTTP requests and header inspection","type":"cli"},
   {"name":"OpenSSL","bin":"openssl","desc":"TLS and certificate checks","type":"cli"},
   {"name":"Firefox ESR","bin":"firefox-esr","desc":"Browser for manual testing","type":"gui"}]},
  {"id":"wifi","title":"Wi-Fi","subtitle":"Wireless info and auditing","icon":"network-wireless","tools":[
   {"name":"iw","bin":"iw","desc":"Wireless interface and driver information","type":"cli"},
   {"name":"nmcli","bin":"nmcli","desc":"Wi-Fi status and scan via NetworkManager","type":"cli"},
   {"name":"wavemon","bin":"wavemon","desc":"Live signal and link quality monitor","type":"cli"},
   {"name":"Aircrack-ng suite","bin":"aircrack-ng","desc":"Wireless security auditing (own/authorized networks)","type":"cli","root":true,"authorized":true},
   {"name":"Kismet","bin":"kismet","desc":"Wireless network detector and sniffer","type":"cli","root":true,"authorized":true},
   {"name":"Wireshark","bin":"wireshark","desc":"Wireless packet analysis","type":"gui","root":true,"authorized":true}]},
  {"id":"forensics","title":"Forensics","subtitle":"Imaging, analysis, timelines","icon":"drive-harddisk","tools":[
   {"name":"Guymager","bin":"guymager","desc":"Forensic disk imager (dd/E01)","type":"gui","root":true},
   {"name":"ddrescue","bin":"ddrescue","desc":"Image failing disks, retries bad sectors","type":"cli","root":true},
   {"name":"dc3dd","bin":"dc3dd","desc":"Forensic dd with hashing","type":"cli","root":true},
   {"name":"ewfacquire","bin":"ewfacquire","desc":"Acquire evidence in E01 format","type":"cli","root":true},
   {"name":"fls (Sleuth Kit)","bin":"fls","desc":"List files incl. deleted entries","type":"cli","root":true},
   {"name":"mmls (Sleuth Kit)","bin":"mmls","desc":"Show partition layout of an image","type":"cli"},
   {"name":"icat (Sleuth Kit)","bin":"icat","desc":"Extract a file by inode","type":"cli","root":true},
   {"name":"PhotoRec","bin":"photorec","desc":"Carve and recover deleted files","type":"cli","root":true},
   {"name":"Foremost","bin":"foremost","desc":"File carving by signature","type":"cli"},
   {"name":"bulk_extractor","bin":"bulk_extractor","desc":"Extract emails, URLs, artifacts from images","type":"cli"},
   {"name":"Volatility 3","bin":"vol|volatility3|vol3","desc":"Memory-analysis framework","type":"cli"},
   {"name":"Plaso (log2timeline)","bin":"log2timeline.py|log2timeline","desc":"Build forensic timelines","type":"cli"}]},
  {"id":"recovery","title":"Recovery","subtitle":"Repair, partitions, backup","icon":"preferences-system","tools":[
   {"name":"GParted","bin":"gparted","desc":"Partition manager","type":"gui","root":true},
   {"name":"smartctl","bin":"smartctl","desc":"Disk health (SMART)","type":"cli","root":true},
   {"name":"TestDisk","bin":"testdisk","desc":"Recover partitions and repair boot sectors","type":"cli","root":true},
   {"name":"ddrescue","bin":"ddrescue","desc":"Rescue data from failing disks","type":"cli","root":true},
   {"name":"ntfsfix","bin":"ntfsfix","desc":"Fix common NTFS problems (Windows disks)","type":"cli","root":true},
   {"name":"efibootmgr","bin":"efibootmgr","desc":"Inspect and edit UEFI boot entries","type":"cli","root":true},
   {"name":"grub-install","bin":"grub-install","desc":"Reinstall GRUB (boot repair)","type":"cli","root":true},
   {"name":"rsync","bin":"rsync","desc":"Backup and restore files","type":"cli"},
   {"name":"lsblk","bin":"lsblk","desc":"Disks and partitions overview","type":"cli"}]},
  {"id":"analysis","title":"Analysis","subtitle":"Logs, hashes, metadata","icon":"utilities-system-monitor","tools":[
   {"name":"Hash (sha256sum)","bin":"sha256sum","desc":"Calculate and verify SHA-256 hashes","type":"cli"},
   {"name":"hashdeep","bin":"hashdeep","desc":"Recursive hash sets and audits","type":"cli"},
   {"name":"ExifTool","bin":"exiftool","desc":"Read file metadata","type":"cli"},
   {"name":"strings","bin":"strings","desc":"Extract printable strings from binaries","type":"cli"},
   {"name":"binwalk","bin":"binwalk","desc":"Analyze embedded data in files","type":"cli"},
   {"name":"YARA","bin":"yara","desc":"Pattern matching rules for files","type":"cli"},
   {"name":"GHex","bin":"ghex","desc":"Graphical hex editor","type":"gui"},
   {"name":"xxd","bin":"xxd","desc":"Hex dump","type":"cli"},
   {"name":"lnav","bin":"lnav","desc":"Log file navigator","type":"cli"},
   {"name":"journalctl","bin":"journalctl","desc":"Systemd journal logs","type":"cli"}]},
  {"id":"audit","title":"Security Audit","subtitle":"Configuration auditing","icon":"security-high","tools":[
   {"name":"Lynis","bin":"lynis","desc":"System hardening and security audit","type":"cli","root":true},
   {"name":"rkhunter","bin":"rkhunter","desc":"Rootkit and backdoor checker","type":"cli","root":true},
   {"name":"chkrootkit","bin":"chkrootkit","desc":"Local rootkit checker","type":"cli","root":true},
   {"name":"debsecan","bin":"debsecan","desc":"Known vulnerabilities in installed packages","type":"cli"},
   {"name":"OpenSCAP","bin":"oscap","desc":"Compliance and configuration scanning","type":"cli"}]},
  {"id":"utilities","title":"Utilities","subtitle":"Everyday system tools","icon":"applications-utilities","tools":[
   {"name":"Terminal","bin":"xfce4-terminal","desc":"Terminal emulator","type":"gui"},
   {"name":"Thunar","bin":"thunar","desc":"File manager","type":"gui"},
   {"name":"Mousepad","bin":"mousepad","desc":"Text editor","type":"gui"},
   {"name":"Archive Manager","bin":"file-roller","desc":"Create and extract archives","type":"gui"},
   {"name":"Disks","bin":"gnome-disks","desc":"Disk utility","type":"gui"},
   {"name":"Task Manager","bin":"xfce4-taskmanager","desc":"Processes and resources","type":"gui"},
   {"name":"Screenshot","bin":"xfce4-screenshooter","desc":"Capture the screen","type":"gui"},
   {"name":"Synaptic","bin":"synaptic","desc":"Package manager","type":"gui","root":true},
   {"name":"htop","bin":"htop","desc":"Interactive process viewer","type":"cli"},
   {"name":"ncdu","bin":"ncdu","desc":"Disk usage analyzer","type":"cli"}]}
 ]
}
JSONEOF

# ------------------------------------------------------------ the application
cat > "$APP/sanju_security_center.py" <<'PYEOF'
#!/usr/bin/env python3
"""Sanju Security Center - categorized tool launcher + system status (GTK3).

Safety: this app never runs scans or intrusive actions by itself. CLI tools open
in a terminal showing --help only; tools marked "authorized" ask for confirmation.
"""
import getpass, json, os, platform, shlex, shutil, socket, subprocess, sys

APP_DIR = os.path.dirname(os.path.abspath(__file__))
CATALOG = os.environ.get("SANJU_CATALOG", os.path.join(APP_DIR, "catalog.json"))
EXTRA_PATH = "/usr/sbin:/sbin:/usr/local/sbin"


def env():
    e = dict(os.environ)
    e["PATH"] = e.get("PATH", "/usr/bin:/bin") + ":" + EXTRA_PATH
    return e


def find(binspec):
    for b in binspec.split("|"):
        p = shutil.which(b, path=env()["PATH"])
        if p:
            return p
    return None


def load_catalog():
    with open(CATALOG, encoding="utf-8") as f:
        return json.load(f)


if "--list" in sys.argv:  # headless check, no GTK needed
    for c in load_catalog()["categories"]:
        have = [t["name"] for t in c["tools"] if find(t["bin"])]
        print(f'{c["title"]}: {len(have)}/{len(c["tools"])} installed')
        for t in c["tools"]:
            print("   ", "[x]" if find(t["bin"]) else "[ ]", t["name"])
    sys.exit(0)

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk  # noqa: E402
import psutil  # noqa: E402

CSS = b"""
window, .root { background: #0b1118; }
.brand { color: #e6f1ff; font-weight: bold; font-size: 18px; letter-spacing: 3px; }
.sub { color: #8aa0b4; font-size: 12px; }
.title { color: #e6f1ff; font-weight: bold; font-size: 15px; }
.tile { background: #111b26; border: 1px solid #1d2c3b; border-radius: 10px; padding: 18px; }
.tile:hover { border-color: #00e5ff; background: #142333; }
.toolrow { background: #111b26; border: 1px solid #1d2c3b; border-radius: 8px; padding: 10px; margin: 3px 0; }
.badge { border-radius: 4px; padding: 1px 8px; font-size: 11px; font-weight: bold; }
.gui { background: #0f3d47; color: #00e5ff; }
.cli { background: #2a2f1c; color: #d9e86b; }
.dim { opacity: 0.45; }
.statusbar { background: #0e1620; border-top: 1px solid #1d2c3b; padding: 8px 14px; }
progressbar trough { background: #1b2735; min-height: 10px; border-radius: 5px; }
progressbar progress { background: #00e5ff; min-height: 10px; border-radius: 5px; }
button.launch { background: #00a9bd; color: #04121a; font-weight: bold; }
"""

SAFE_TEXT = ("Sanju Security OS is for education, authorized testing, auditing, forensics, "
             "incident response and recovery.\n\nOnly use these tools on systems and networks "
             "you own or have explicit written permission to test. Unauthorized access is "
             "illegal in most countries.\n\nThis app never runs scans for you: CLI tools open in "
             "a terminal showing their help, and you decide what to run.")


def lbl(text, cls=None, wrap=False, xalign=0.0):
    w = Gtk.Label(label=text)
    w.set_xalign(xalign)
    w.set_line_wrap(wrap)
    if cls:
        w.get_style_context().add_class(cls)
    return w


def open_terminal(title, script):
    if not shutil.which("xfce4-terminal"):
        return False
    subprocess.Popen(["xfce4-terminal", "-T", title, "-x", "bash", "-c", script],
                     start_new_session=True, env=env())
    return True


class Status(Gtk.Box):
    def __init__(self):
        super().__init__(spacing=24)
        self.get_style_context().add_class("statusbar")
        self.bars = {}
        for key in ("CPU", "RAM", "Disk"):
            box = Gtk.Box(spacing=8)
            box.pack_start(lbl(key, "sub"), False, False, 0)
            pb = Gtk.ProgressBar(show_text=True)
            pb.set_size_request(130, -1)
            box.pack_start(pb, False, False, 0)
            self.bars[key] = pb
            self.pack_start(box, False, False, 0)
        self.net = lbl("Network: …", "sub")
        self.pack_start(self.net, True, True, 0)
        self._last = psutil.net_io_counters()
        psutil.cpu_percent(None)
        self.refresh()

    def refresh(self):
        vals = {"CPU": psutil.cpu_percent(None), "RAM": psutil.virtual_memory().percent,
                "Disk": psutil.disk_usage("/").percent}
        for k, v in vals.items():
            self.bars[k].set_fraction(v / 100)
            self.bars[k].set_text(f"{v:.0f}%")
        now = psutil.net_io_counters()
        down = (now.bytes_recv - self._last.bytes_recv) / 2 / 1024
        up = (now.bytes_sent - self._last.bytes_sent) / 2 / 1024
        self._last = now
        ifs = [n for n, s in psutil.net_if_stats().items() if s.isup and n != "lo"]
        state = ", ".join(ifs) if ifs else "offline"
        self.net.set_text(f"Network: {state}   ↓ {down:.0f} KB/s   ↑ {up:.0f} KB/s")
        return True


class Center(Gtk.Window):
    def __init__(self, data, start=None):
        super().__init__(title="Sanju Security Center")
        self.set_default_size(1100, 680)
        self.set_size_request(900, 560)
        self.set_icon_name("sanju-security-os")
        self.cats = {c["id"]: c for c in data["categories"]}
        self.order = [c["id"] for c in data["categories"]]
        self.current = None
        self.show_missing = False

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        root.get_style_context().add_class("root")
        root.pack_start(self.header(), False, False, 0)
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.add_named(self.home(), "home")
        self.page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.stack.add_named(self.page, "cat")
        root.pack_start(self.stack, True, True, 0)
        self.status = Status()
        root.pack_start(self.status, False, False, 0)
        self.add(root)
        GLib.timeout_add_seconds(2, self.status.refresh)
        self.connect("destroy", Gtk.main_quit)
        self.show_all()
        if start in self.cats:
            self.open_category(start)

    # ---- header
    def header(self):
        box = Gtk.Box(spacing=12)
        box.set_border_width(14)
        img = Gtk.Image.new_from_icon_name("sanju-security-os", Gtk.IconSize.DIALOG)
        img.set_pixel_size(44)
        box.pack_start(img, False, False, 0)
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        v.pack_start(lbl("SANJU SECURITY OS", "brand"), False, False, 0)
        info = f"Security Center  ·  {getpass.getuser()}@{socket.gethostname()}  ·  kernel {platform.release()}"
        v.pack_start(lbl(info, "sub"), False, False, 0)
        box.pack_start(v, True, True, 0)
        b = Gtk.Button(label="Safe-use notice")
        b.connect("clicked", lambda *_: self.notice())
        box.pack_end(b, False, False, 0)
        return box

    def notice(self):
        d = Gtk.MessageDialog(transient_for=self, message_type=Gtk.MessageType.INFO,
                              buttons=Gtk.ButtonsType.OK, text="Authorized use only")
        d.format_secondary_text(SAFE_TEXT)
        d.run()
        d.destroy()

    # ---- home
    def home(self):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        fb = Gtk.FlowBox()
        fb.set_selection_mode(Gtk.SelectionMode.NONE)
        fb.set_homogeneous(True)
        fb.set_min_children_per_line(2)
        fb.set_max_children_per_line(4)
        fb.set_row_spacing(12)
        fb.set_column_spacing(12)
        fb.set_border_width(14)
        fb.set_valign(Gtk.Align.START)
        for cid in self.order:
            c = self.cats[cid]
            have = sum(1 for t in c["tools"] if find(t["bin"]))
            btn = Gtk.Button()
            btn.set_relief(Gtk.ReliefStyle.NONE)
            btn.get_style_context().add_class("tile")
            v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            v.pack_start(Gtk.Image.new_from_icon_name(c["icon"], Gtk.IconSize.DIALOG), False, False, 4)
            v.pack_start(lbl(c["title"].upper(), "title", xalign=0.5), False, False, 0)
            v.pack_start(lbl(c["subtitle"], "sub", wrap=True, xalign=0.5), False, False, 0)
            v.pack_start(lbl(f"{have}/{len(c['tools'])} tools installed", "sub", xalign=0.5), False, False, 0)
            btn.add(v)
            btn.connect("clicked", lambda _b, k=cid: self.open_category(k))
            fb.add(btn)
        sw.add(fb)
        return sw

    # ---- category page
    def open_category(self, cid):
        self.current = cid
        c = self.cats[cid]
        for ch in self.page.get_children():
            self.page.remove(ch)
        bar = Gtk.Box(spacing=10)
        bar.set_border_width(12)
        back = Gtk.Button(label="←  Back")
        back.connect("clicked", lambda *_: self.stack.set_visible_child_name("home"))
        bar.pack_start(back, False, False, 0)
        bar.pack_start(lbl(c["title"].upper(), "title"), False, False, 6)
        sw_missing = Gtk.Switch(active=self.show_missing)
        sw_missing.connect("notify::active", self.toggle_missing)
        bar.pack_end(sw_missing, False, False, 0)
        bar.pack_end(lbl("Show not installed", "sub"), False, False, 0)
        self.page.pack_start(bar, False, False, 0)

        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        lb = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        lb.set_border_width(12)
        shown = 0
        for t in c["tools"]:
            path = find(t["bin"])
            if not path and not self.show_missing:
                continue
            lb.pack_start(self.row(t, path), False, False, 0)
            shown += 1
        if not shown:
            lb.pack_start(lbl("No tools installed in this category yet (Phase 4 adds them).", "sub"),
                          False, False, 20)
        sw.add(lb)
        self.page.pack_start(sw, True, True, 0)
        self.page.show_all()
        self.stack.set_visible_child_name("cat")

    def toggle_missing(self, sw, _p):
        self.show_missing = sw.get_active()
        self.open_category(self.current)

    def row(self, t, path):
        r = Gtk.Box(spacing=12)
        r.get_style_context().add_class("toolrow")
        if not path:
            r.get_style_context().add_class("dim")
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        top = Gtk.Box(spacing=8)
        top.pack_start(lbl(t["name"], "title"), False, False, 0)
        badge = lbl("GUI" if t["type"] == "gui" else "TERMINAL", "badge")
        badge.get_style_context().add_class("gui" if t["type"] == "gui" else "cli")
        top.pack_start(badge, False, False, 0)
        if t.get("root"):
            top.pack_start(lbl("needs root", "sub"), False, False, 0)
        if not path:
            top.pack_start(lbl("not installed", "sub"), False, False, 0)
        v.pack_start(top, False, False, 0)
        v.pack_start(lbl(t["desc"], "sub", wrap=True), False, False, 0)
        r.pack_start(v, True, True, 0)
        docs = Gtk.Button(label="Docs")
        docs.set_sensitive(bool(path))
        docs.connect("clicked", lambda *_: self.docs(t, path))
        go = Gtk.Button(label="Launch")
        go.get_style_context().add_class("launch")
        go.set_sensitive(bool(path))
        go.connect("clicked", lambda *_: self.launch(t, path))
        r.pack_end(go, False, False, 0)
        r.pack_end(docs, False, False, 0)
        return r

    # ---- actions
    def message(self, text, kind=Gtk.MessageType.ERROR):
        d = Gtk.MessageDialog(transient_for=self, message_type=kind,
                              buttons=Gtk.ButtonsType.OK, text=text)
        d.run()
        d.destroy()

    def confirm(self, t):
        d = Gtk.MessageDialog(transient_for=self, message_type=Gtk.MessageType.WARNING,
                              buttons=Gtk.ButtonsType.YES_NO, text=f"Open {t['name']}?")
        d.format_secondary_text("This tool can probe systems or capture traffic. Use it only on "
                                "systems and networks you own or have written permission to test.")
        ok = d.run() == Gtk.ResponseType.YES
        d.destroy()
        return ok

    def launch(self, t, path):
        if t.get("authorized") and not self.confirm(t):
            return
        if t["type"] == "gui":
            cmd = [path]
            if t.get("root"):
                e = env()
                cmd = ["pkexec", "env", f"DISPLAY={e.get('DISPLAY', ':0')}",
                       f"XAUTHORITY={e.get('XAUTHORITY', os.path.expanduser('~/.Xauthority'))}", path]
            try:
                subprocess.Popen(cmd, start_new_session=True, env=env())
            except OSError as ex:
                self.message(f"Could not start {t['name']}: {ex}")
            return
        note = "Needs root: run it with sudo." if t.get("root") else ""
        script = (f"clear; printf '\\033[1;36m== %s ==\\033[0m\\n' {shlex.quote(t['name'])}; "
                  "echo 'Authorized use only: systems you own or have written permission to test.'; "
                  f"echo {shlex.quote(note)}; echo; {shlex.quote(path)} --help 2>&1 | head -30; "
                  f"echo; echo 'Tool: {path}'; echo 'Nothing has been run. Type your command below.'; exec bash")
        if not open_terminal(t["name"], script):
            self.message("xfce4-terminal is not installed.")

    def docs(self, t, path):
        b = shlex.quote(os.path.basename(path))
        script = f"(man {b} 2>/dev/null || {shlex.quote(path)} --help 2>&1) | less -R"
        if not open_terminal(f"Docs: {t['name']}", script):
            self.message("xfce4-terminal is not installed.")


def main():
    import argparse
    ap = argparse.ArgumentParser(description="Sanju Security Center")
    ap.add_argument("--category", help="open a category directly (e.g. recon, forensics)")
    ap.add_argument("--list", action="store_true", help="print tool availability and exit")
    args = ap.parse_args()
    css = Gtk.CssProvider()
    css.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css,
                                             Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    Center(load_catalog(), args.category)
    Gtk.main()


if __name__ == "__main__":
    main()
PYEOF
chmod +x "$APP/sanju_security_center.py"

# ------------------------------------------------------------ launcher + menu entry
cat > config/includes.chroot/usr/local/bin/sanju-security-center <<'EOF'
#!/bin/sh
exec python3 /usr/lib/sanju-security-center/sanju_security_center.py "$@"
EOF
chmod +x config/includes.chroot/usr/local/bin/sanju-security-center

cat > config/includes.chroot/usr/share/applications/sanju-security-center.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Sanju Security Center
Comment=Categorized security, forensics and recovery tool launcher
Exec=sanju-security-center
Icon=sanju-security-os
Terminal=false
Categories=System;Security;
EOF

# ------------------------------------------------------------ docs
cat > docs/security-center.md <<'EOF'
# Sanju Security Center
Source: config/includes.chroot/usr/lib/sanju-security-center/
- catalog.json : every category and tool shown in the UI
- sanju_security_center.py : GTK3 app

## Add a tool
Add an entry to a category in catalog.json:
  {"name":"Nmap","bin":"nmap","desc":"...","type":"cli|gui","root":true,"authorized":true}
- bin may list alternatives: "vol|volatility3|vol3"
- authorized:true asks for a confirmation before launch
- Also add the package name to config/package-lists/ (Phase 4)

## Dev run (no ISO needed)
python3 config/includes.chroot/usr/lib/sanju-security-center/sanju_security_center.py
python3 ... --category forensics
python3 ... --list      # headless: which tools are installed
EOF

echo "Phase 3 files created."
echo "Test now:  python3 $APP/sanju_security_center.py"
echo "Then build: ./scripts/02-configure.sh && ./scripts/03-build.sh"
