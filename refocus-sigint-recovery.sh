#!/usr/bin/env bash
# Sanju Security OS - REFOCUS: Cybersecurity + Digital Forensics + Data Recovery + SIGINT/RF
# Not a "complete hacking OS": offensive tools (sqlmap, aircrack-ng) removed, SIGINT/RF + recovery added.
# Run after phases 1-4 (and 2b). Safe to re-run.
# Usage: ./refocus-sigint-recovery.sh ~/sanju-security-os
set -euo pipefail
ROOT="${1:-$HOME/sanju-security-os}"
APP="$ROOT/config/includes.chroot/usr/lib/sanju-security-center"
[ -f "$APP/catalog.json" ] || { echo "Run phases 1-4 first"; exit 1; }
cd "$ROOT"
INC=config/includes.chroot
mkdir -p $INC/etc/modprobe.d $INC/etc/skel/Desktop

# ------------------------------------------------------------ 1. new tool catalog (7 categories)
cat > "$APP/catalog.json" <<'JSONEOF'
{
 "categories": [
  {"id":"cyber","title":"Cybersecurity","subtitle":"Assessment, hardening, malware checks","icon":"security-high","tools":[
   {"name":"Nmap","bin":"nmap","desc":"Network discovery and service enumeration","type":"cli","authorized":true},
   {"name":"arp-scan","bin":"arp-scan","desc":"Find devices on your local network","type":"cli","root":true,"authorized":true},
   {"name":"Lynis","bin":"lynis","desc":"System hardening and security audit","type":"cli","root":true},
   {"name":"OpenSCAP","bin":"oscap","desc":"Compliance and configuration scanning","type":"cli"},
   {"name":"debsecan","bin":"debsecan","desc":"Known vulnerabilities in installed packages","type":"cli"},
   {"name":"ClamAV","bin":"clamscan","desc":"Antivirus / malware scanning","type":"cli"},
   {"name":"rkhunter","bin":"rkhunter","desc":"Rootkit and backdoor checker","type":"cli","root":true},
   {"name":"chkrootkit","bin":"chkrootkit","desc":"Local rootkit checker","type":"cli","root":true},
   {"name":"Suricata","bin":"suricata","desc":"Intrusion detection (IDS) engine","type":"cli","root":true,"authorized":true},
   {"name":"testssl.sh","bin":"testssl.sh|testssl","desc":"Check TLS configuration of your own servers","type":"cli","authorized":true},
   {"name":"Nikto","bin":"nikto","desc":"Web server configuration scanner (own sites)","type":"cli","authorized":true},
   {"name":"YARA","bin":"yara","desc":"Pattern rules for malware/artifact matching","type":"cli"}]},
  {"id":"network","title":"Network","subtitle":"Diagnostics and packet analysis","icon":"network-workgroup","tools":[
   {"name":"Wireshark","bin":"wireshark","desc":"Packet capture and protocol analysis","type":"gui","root":true,"authorized":true},
   {"name":"tshark","bin":"tshark","desc":"Command-line Wireshark","type":"cli","root":true,"authorized":true},
   {"name":"tcpdump","bin":"tcpdump","desc":"Command-line packet capture","type":"cli","root":true,"authorized":true},
   {"name":"iftop","bin":"iftop","desc":"Live bandwidth per connection","type":"cli","root":true},
   {"name":"ss","bin":"ss","desc":"Sockets and listening ports","type":"cli"},
   {"name":"ip","bin":"ip","desc":"Interfaces, addresses, routes","type":"cli"},
   {"name":"dig","bin":"dig","desc":"DNS lookups","type":"cli"},
   {"name":"whois","bin":"whois","desc":"Domain/IP registration info","type":"cli"},
   {"name":"mtr","bin":"mtr","desc":"Path and latency diagnostics","type":"cli"},
   {"name":"iperf3","bin":"iperf3","desc":"Throughput testing between your own hosts","type":"cli"},
   {"name":"ethtool","bin":"ethtool","desc":"Ethernet adapter settings","type":"cli","root":true},
   {"name":"Network Connections","bin":"nm-connection-editor","desc":"Edit NetworkManager connections","type":"gui"},
   {"name":"nmtui","bin":"nmtui","desc":"Text UI for NetworkManager","type":"cli"}]},
  {"id":"forensics","title":"Digital Forensics","subtitle":"Imaging, analysis, timelines","icon":"drive-harddisk","tools":[
   {"name":"Guymager","bin":"guymager","desc":"Forensic disk imager (dd/E01)","type":"gui","root":true},
   {"name":"dc3dd","bin":"dc3dd","desc":"Forensic dd with hashing","type":"cli","root":true},
   {"name":"ewfacquire","bin":"ewfacquire","desc":"Acquire evidence in E01 format","type":"cli","root":true},
   {"name":"mmls (Sleuth Kit)","bin":"mmls","desc":"Partition layout of an image","type":"cli"},
   {"name":"fls (Sleuth Kit)","bin":"fls","desc":"List files including deleted entries","type":"cli","root":true},
   {"name":"icat (Sleuth Kit)","bin":"icat","desc":"Extract a file by inode","type":"cli","root":true},
   {"name":"bulk_extractor","bin":"bulk_extractor","desc":"Extract emails, URLs, artifacts from images","type":"cli"},
   {"name":"Volatility 3","bin":"vol|volatility3|vol3","desc":"Memory analysis framework","type":"cli"},
   {"name":"Plaso (log2timeline)","bin":"log2timeline.py|log2timeline","desc":"Build forensic timelines","type":"cli"},
   {"name":"ExifTool","bin":"exiftool","desc":"File metadata","type":"cli"},
   {"name":"ssdeep","bin":"ssdeep","desc":"Fuzzy hashing to find similar files","type":"cli"},
   {"name":"dislocker","bin":"dislocker","desc":"Open BitLocker volumes (with your key/password)","type":"cli","root":true}]},
  {"id":"recovery","title":"Data Recovery","subtitle":"Lost files, bad disks, repair","icon":"preferences-system","tools":[
   {"name":"PhotoRec","bin":"photorec","desc":"Recover deleted files by signature","type":"cli","root":true},
   {"name":"TestDisk","bin":"testdisk","desc":"Recover lost partitions, repair boot sectors","type":"cli","root":true},
   {"name":"ddrescue","bin":"ddrescue","desc":"Rescue data from failing disks","type":"cli","root":true},
   {"name":"safecopy","bin":"safecopy","desc":"Copy data from damaged media","type":"cli","root":true},
   {"name":"Scalpel","bin":"scalpel","desc":"File carving","type":"cli","root":true},
   {"name":"Foremost","bin":"foremost","desc":"File carving by header/footer","type":"cli","root":true},
   {"name":"recoverjpeg","bin":"recoverjpeg","desc":"Recover JPEG photos from damaged disks","type":"cli","root":true},
   {"name":"magicrescue","bin":"magicrescue","desc":"Recover files by magic bytes","type":"cli","root":true},
   {"name":"GParted","bin":"gparted","desc":"Partition manager","type":"gui","root":true},
   {"name":"smartctl","bin":"smartctl","desc":"Disk health (SMART)","type":"cli","root":true},
   {"name":"nvme","bin":"nvme","desc":"NVMe drive health and info","type":"cli","root":true},
   {"name":"hdparm","bin":"hdparm","desc":"Drive parameters and info","type":"cli","root":true},
   {"name":"ntfsfix","bin":"ntfsfix","desc":"Fix common NTFS problems","type":"cli","root":true},
   {"name":"efibootmgr","bin":"efibootmgr","desc":"Inspect/edit UEFI boot entries","type":"cli","root":true},
   {"name":"grub-install","bin":"grub-install","desc":"Reinstall GRUB (boot repair)","type":"cli","root":true},
   {"name":"rsync","bin":"rsync","desc":"Backup and restore","type":"cli"},
   {"name":"lsblk","bin":"lsblk","desc":"Disks and partitions overview","type":"cli"}]},
  {"id":"sigint","title":"SIGINT / RF","subtitle":"Spectrum, SDR, signal analysis","icon":"network-wireless","notice":"Passive reception and analysis only. Receive signals you are legally allowed to receive (spectrum survey, ADS-B aircraft, weather satellites, amateur radio, your own sensors/devices). Do not intercept or decode private communications. Radio rules differ by country: check your local law.","tools":[
   {"name":"GQRX","bin":"gqrx","desc":"SDR receiver and spectrum viewer","type":"gui"},
   {"name":"CubicSDR","bin":"CubicSDR|cubicsdr","desc":"Cross-platform SDR receiver","type":"gui"},
   {"name":"GNU Radio Companion","bin":"gnuradio-companion","desc":"Build signal-processing flowgraphs","type":"gui"},
   {"name":"Inspectrum","bin":"inspectrum","desc":"Analyze recorded radio signals","type":"gui"},
   {"name":"GPredict","bin":"gpredict","desc":"Satellite tracking and pass prediction","type":"gui"},
   {"name":"rtl_test","bin":"rtl_test","desc":"Test RTL-SDR dongle","type":"cli"},
   {"name":"rtl_power","bin":"rtl_power","desc":"Wideband spectrum survey (RTL-SDR)","type":"cli"},
   {"name":"rtl_433","bin":"rtl_433","desc":"Decode ISM-band sensors (weather, temperature…)","type":"cli"},
   {"name":"dump1090 (ADS-B)","bin":"dump1090-mutability|dump1090|dump1090-fa","desc":"Receive aircraft ADS-B broadcasts","type":"cli"},
   {"name":"multimon-ng","bin":"multimon-ng","desc":"Decode public digital modes (e.g. pagers/AFSK test signals)","type":"cli"},
   {"name":"fldigi","bin":"fldigi","desc":"Amateur-radio digital modes","type":"gui"},
   {"name":"WSJT-X","bin":"wsjtx","desc":"Amateur-radio weak-signal modes","type":"gui"},
   {"name":"Direwolf","bin":"direwolf","desc":"Amateur packet radio / APRS","type":"cli"},
   {"name":"SoapySDR","bin":"SoapySDRUtil","desc":"Detect and test SDR hardware","type":"cli"},
   {"name":"HackRF info","bin":"hackrf_info","desc":"HackRF device information","type":"cli"},
   {"name":"Kismet","bin":"kismet","desc":"Passive Wi-Fi/Bluetooth/RF survey","type":"cli","root":true,"authorized":true},
   {"name":"iw","bin":"iw","desc":"Wireless interface information","type":"cli"},
   {"name":"wavemon","bin":"wavemon","desc":"Wi-Fi signal and link monitor","type":"cli"},
   {"name":"SoX","bin":"sox","desc":"Audio/signal file processing","type":"cli"}]},
  {"id":"analysis","title":"Analysis","subtitle":"Logs, hashes, binaries","icon":"utilities-system-monitor","tools":[
   {"name":"sha256sum","bin":"sha256sum","desc":"Calculate and verify SHA-256 hashes","type":"cli"},
   {"name":"hashdeep","bin":"hashdeep","desc":"Recursive hash sets and audits","type":"cli"},
   {"name":"binwalk","bin":"binwalk","desc":"Find embedded data in files","type":"cli"},
   {"name":"strings","bin":"strings","desc":"Printable strings from binaries","type":"cli"},
   {"name":"GHex","bin":"ghex","desc":"Graphical hex editor","type":"gui"},
   {"name":"xxd","bin":"xxd","desc":"Hex dump","type":"cli"},
   {"name":"lnav","bin":"lnav","desc":"Log file navigator","type":"cli"},
   {"name":"journalctl","bin":"journalctl","desc":"Systemd journal logs","type":"cli"}]},
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

# ------------------------------------------------------------ 2. show the category notice in the Security Center UI
python3 - "$APP/sanju_security_center.py" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "c.get(\"notice\")" not in s:
    old = "        self.page.pack_start(bar, False, False, 0)\n\n        sw = Gtk.ScrolledWindow()"
    new = ("        self.page.pack_start(bar, False, False, 0)\n"
           "        if c.get(\"notice\"):\n"
           "            nb = lbl(\"⚠  \" + c[\"notice\"], \"sub\", wrap=True)\n"
           "            nb.set_margin_start(14); nb.set_margin_end(14); nb.set_margin_bottom(6)\n"
           "            self.page.pack_start(nb, False, False, 0)\n\n"
           "        sw = Gtk.ScrolledWindow()")
    assert old in s, "anchor not found - Security Center file was changed"
    open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
    print("Security Center: category notice added")
PYEOF

# ------------------------------------------------------------ 3. packages
CORE=config/package-lists/sanju-tools-core.list.chroot
for pkg in tshark arp-scan hdparm nvme-cli exfatprogs btrfs-progs xfsprogs ssdeep sox bluez; do
  grep -qx "$pkg" "$CORE" || echo "$pkg" >> "$CORE"
done

cat > $INC/usr/share/sanju/optional-packages.txt <<'EOF'
nikto
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
scalpel
safecopy
recoverjpeg
magicrescue
dislocker
clamav
suricata
testssl.sh
rtl-sdr
gqrx-sdr
cubicsdr
gnuradio
gr-osmosdr
soapysdr-tools
hackrf
rtl-433
dump1090-mutability
multimon-ng
gpredict
inspectrum
fldigi
wsjtx
direwolf
EOF

# SDR dongles: stop the kernel TV driver from grabbing RTL-SDR devices
cat > $INC/etc/modprobe.d/blacklist-sanju-rtlsdr.conf <<'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF

# ------------------------------------------------------------ 4. desktop shortcuts for the new focus
rm -f $INC/etc/skel/Desktop/*.desktop
mk() { printf '[Desktop Entry]\nVersion=1.0\nType=Application\nName=%s\nExec=%s\nIcon=%s\nTerminal=false\n' "$1" "$2" "$3" > "$INC/etc/skel/Desktop/$4.desktop"; chmod +x "$INC/etc/skel/Desktop/$4.desktop"; }
mk "🛡 Cybersecurity"    "sanju-launch cyber"     security-high             cyber
mk "🌐 Network"          "sanju-launch network"   network-workgroup         network
mk "💾 Digital Forensics" "sanju-launch forensics" drive-harddisk           forensics
mk "♻ Data Recovery"    "sanju-launch recovery"  preferences-system        recovery
mk "📡 SIGINT / RF"      "sanju-launch sigint"    network-wireless          sigint
mk "📊 Analysis"         "sanju-launch analysis"  utilities-system-monitor  analysis
mk "⚙ Settings"         "xfce4-settings-manager" preferences-desktop       settings

# ------------------------------------------------------------ 5. check
python3 -c "import json;d=json.load(open('$APP/catalog.json'));print('catalog OK:',len(d['categories']),'categories,',sum(len(c['tools']) for c in d['categories']),'tools')"
python3 -m py_compile "$APP/sanju_security_center.py" && echo "Security Center compiles"
echo "Refocus applied. Rebuild:  ./scripts/02-configure.sh && ./scripts/03-build.sh"
