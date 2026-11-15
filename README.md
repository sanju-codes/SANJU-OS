# SANJU SECURITY OS

**A Debian-based cybersecurity, digital forensics, and data-recovery operating system project.**

SANJU SECURITY OS is a custom Linux distribution project focused on bringing security analysis, digital forensics, storage investigation, and system-rescue workflows together in one desktop environment.

> **Project status:** Work in progress. The design and feature set described here are project goals; not every feature is implemented or tested yet. Do not treat current source files as a production-ready operating system or assume that a bootable ISO is available.

## Vision

Build a practical, bootable operating system for security learners, researchers, and technicians, with:

- A familiar desktop experience inspired by security-focused Linux distributions.
- Tools and workflows for cybersecurity learning and authorized testing.
- Digital-forensics and data-recovery capabilities.
- Radio-frequency and software-defined-radio (SDR) research support.
- Offline-friendly utilities for lab and field use.
- A maintainable build process for creating and testing installation media.

## Planned platform

| Area | Direction |
| --- | --- |
| Base system | Debian 13 (Trixie) |
| Desktop | XFCE, with a custom Parrot-inspired visual style |
| Security dashboard | Planned Sanju Security Center (GTK3) |
| Boot support | Targeting BIOS and UEFI |
| Live environment | Live boot, with forensic/rescue workflows planned |
| Build automation | Windows/WSL build scripts and GitHub Actions workflow are planned |
| Virtualization | Windows virtual-machine workflow support is a project goal |

These are target design choices, not a guarantee that each item is already working in the current build.

## Planned tool areas

### Cybersecurity
A curated environment for learning, lab work, network inspection, and authorized security assessments.

### Digital forensics
A workflow for examining storage media and collecting digital evidence while preserving the original source wherever possible.

### Data recovery and rescue
Utilities for diagnosing storage devices, recovering accessible files, and troubleshooting systems. Recovery results depend on the device condition and the type of data loss; no tool can guarantee recovery.

### SIGINT, RF, and SDR research
Planned support for software-defined-radio workflows and compatible hardware such as RTL-SDR devices. Use only frequencies, equipment, and transmissions that you are legally authorized to monitor or analyze.

### Desktop applications
The planned desktop app set includes LibreOffice for office documents, VLC for media playback, Tor Browser launcher for privacy-focused browsing, UFW with the GUFW graphical frontend for firewall management, and Baobab (Disk Usage Analyzer) for visual storage analysis. Tor Browser requires an internet connection for its initial download and setup; package availability is checked during the build.

### Offline workflows
The project aims to make essential lab and rescue tasks usable without a continuous internet connection. Package availability and update operations may still require connectivity.

## Current development status

The repository is under active development. The items below describe the intended direction and should be checked against the source code and build output before being considered complete.

- [ ] Finalize the Debian 13 base and package selection.
- [ ] Build and theme the XFCE desktop.
- [ ] Implement the Sanju Security Center.
- [ ] Integrate and test cybersecurity, forensics, recovery, and SDR tool groups.
- [ ] Validate live boot and persistence behavior.
- [ ] Validate BIOS and UEFI boot on virtual machines and physical hardware.
- [ ] Add reproducible ISO build automation.
- [ ] Publish checksums and release notes for tested ISO builds.

## Safety and responsible use

SANJU SECURITY OS is intended for education, research, digital investigation, and authorized administration.

- Test security tools only on systems and networks you own or have explicit permission to assess.
- Respect privacy, local laws, licensing terms, and radio-frequency regulations.
- For forensic work, preserve original media when possible and document actions taken.
- Verify downloaded images and checksums before installation.
- Back up important data before partitioning, formatting, or attempting recovery.

## Contributing

Contributions, bug reports, documentation improvements, and testing feedback are welcome.

1. Fork the repository.
2. Create a focused feature branch.
3. Make and test your changes.
4. Open a pull request describing what changed, how it was tested, and any known limitations.

Please do not commit passwords, API keys, personal data, disk images, large generated ISO files, or other sensitive material.

## Testing and releases

A feature should be described as available only after it has been tested. Before publishing an ISO, document at least:

- Build environment and exact build steps.
- Supported architecture and boot mode.
- Virtual-machine and physical-hardware test results.
- Known issues and limitations.
- SHA-256 checksum for the released image.

## License

No license information is declared in this README yet. Check the repository for a LICENSE file before reusing or redistributing the project. A license should be added by the project owner to clarify permitted use.

## Repository

[ sanju-codes/SANJU-OS ](https://github.com/sanju-codes/SANJU-OS)
