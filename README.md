# Initial Package Install

Set up an Ubuntu or Fedora workstation with system packages, desktop apps, VS Code extensions, Python CLI tools, GNOME extensions, and dotfiles.

The installer recognizes Ubuntu 24.04 LTS, 26.04 LTS, and 26.10, and Fedora Workstation 44 and 45. The package baseline targets x86-64. Chrome is included on Ubuntu amd64, and the VS Code repository is selected for supported architectures. Some desktop apps depend on which packages and Snap builds are available for your architecture. Fedora Atomic desktops need a different package installation workflow.

## Run the installer

Clone the [public GitHub mirror](https://github.com/eddinn/initial-package-install), or use your Forgejo clone URL on the LAN. Run the installer as your normal user.

```bash
git clone https://github.com/eddinn/initial-package-install.git
cd initial-package-install
./initial-package-install.sh
```

The installer prompts for sudo for system packages and Snap operations. It uses your user account for pipx, VS Code, GNOME extensions, and dotfiles. You can run either stage separately, from any working directory.

```bash
./initial-package-install.sh --system
./initial-package-install.sh --user
./initial-package-install.sh --user --only=vscode
```

The old commands `sudo ./initial-package-install.sh` and `./post-initial.sh` still run the system and user stages respectively. The scripts under `apps/` and `ext/` also work as shortcuts for their individual components. To bootstrap a system without Git, download and review the installer, then run it with `--system`. Clone the repository before running the user stage so GNU Stow has the dotfiles.

```bash
./initial-package-install.sh --upgrade
./initial-package-install.sh --user --repair
```

A regular run fills in missing components. Use `--upgrade` to update system packages and the managed user apps and extensions. Use `--repair` to rebuild existing pipx environments and refresh GNOME extensions and Oh My Zsh. Failures are listed at the end and produce a nonzero exit status. Independent user components can still finish when another fails. On Ubuntu, if an optional package would cause APT to remove an installed package, the installer skips it, names the proposed removals, and installs the rest of the batch.

On Ubuntu, a full run or `--system` replaces the Spotify, Steam, Slack, and VS Code Snaps after the corresponding APT package is installed. The installer saves a Snap snapshot before each removal. Use `sudo snap saved` to find the snapshots. Settings and Steam libraries stored inside a Snap require a separate migration into the APT app.

## What gets installed

- **System packages** use APT or DNF. Chrome on Ubuntu and VS Code on Ubuntu and Fedora use the vendors' signed repositories. On x86-64 Ubuntu, Spotify, Steam, and Slack use signed vendor APT repositories. Steam enables Ubuntu's i386 architecture for its 32-bit libraries. Slack uses the ALSA client library with the existing audio server. Fedora uses RPM Fusion for Steam.
- **Snap apps** include GitKraken and Discord. Fedora also uses Snap for Slack and Spotify. Fedora's system stage enables Snap's socket and configures the classic Snap path. If newly installed Snap launchers are missing from the desktop, log out and back in. A failed refresh is reported and the installed Snap is kept.
- **Python tools** use pipx for Ansible, ansible-lint, and AWX CLI. WinRM support is installed into Ansible's environment. Fedora 45 uses its packaged Python 3.14 for these environments.
- **VS Code** installs 18 baseline extensions. Python installs Pylance through its extension pack. Ruby LSP replaces the old Ruby extension. Existing extensions stay installed, including any you added outside the baseline.
- **GNOME** gets published Dash to Panel and gTile builds matched to the installed GNOME Shell version. After a fresh install, log in again and enable them in GNOME Extensions. The retired Touchpad Indicator and Panel OSD are omitted.
- **Oh My Zsh** installs under your account. Repair backs up the previous installation and carries its `custom/` files forward. Your login shell is yours to select.
- **Dotfiles** use GNU Stow and point into this checkout, so keep the checkout at a stable path. The installer selects Bash or Zsh based on your login shell. Override that with `DOTFILES_SHELL=bash` or `DOTFILES_SHELL=zsh`. It reports conflicting links and files under `~/bin` before replacing regular top-level dotfiles, and prints the backup directory when it creates one.

To stow just the configured dotfiles, run `./dots/stowit.sh`. To explicitly stow the root-compatible shell dotfiles, run `sudo -H ./dots/stowit.sh`.
