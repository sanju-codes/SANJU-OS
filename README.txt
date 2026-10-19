SANJU SECURITY OS - build kit (Cybersecurity | Digital Forensics | Data Recovery | SIGINT/RF)
Extract everything into C:\sanju (all files in the SAME folder), then in cmd:
    cd C:\sanju
    sanju-build.bat
Already built once? Just apply the new focus and rebuild inside WSL:
    bash /mnt/c/sanju/refocus-sigint-recovery.sh ~/sanju-security-os
    cd ~/sanju-security-os && ./scripts/02-configure.sh && ./scripts/03-build.sh
Live login: user sanju / password live.
Use only on systems you own or are authorized to test; receive only signals you may legally receive.
