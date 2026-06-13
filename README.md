# Initial Package Install

Scripts for installing a personal baseline of workstation packages, Snap apps, Python CLI tools, GNOME extensions, VS Code extensions, themes, and dotfiles on Ubuntu and Fedora.

Supported distributions:

- Ubuntu, detected by `/etc/os-release` `ID=ubuntu`
- Fedora, detected by `/etc/os-release` `ID=fedora`

## What it does

`initial-package-install.sh` runs as root and installs/updates distro packages plus Chrome and TeamViewer.

`post-initial.sh` runs as your normal user and then calls:

- `apps/pip-apps.sh` for Python CLI tools through `pipx`
- `apps/snap-apps.sh` for Snap apps
- `ext/gnome-ext.sh` for GNOME Shell extensions
- `ext/themes-ext.sh` for the Qogir theme
- `ext/vscode-ext.sh` for VS Code extensions
- `ext/zsh-ext.sh` for Oh My Zsh
- `dots/stowit.sh` for dotfiles through GNU Stow

## Usage

### If Git is already installed

```bash
git clone https://github.com/eddinn/initial-package-install.git
cd initial-package-install
sudo ./initial-package-install.sh
./post-initial.sh
```

### If Git is not installed yet

```bash
curl -fsSLO https://raw.githubusercontent.com/eddinn/initial-package-install/master/initial-package-install.sh || \
  wget https://raw.githubusercontent.com/eddinn/initial-package-install/master/initial-package-install.sh

chmod +x ./initial-package-install.sh
sudo ./initial-package-install.sh
rm -f ./initial-package-install.sh

git clone https://github.com/eddinn/initial-package-install.git
cd initial-package-install
./post-initial.sh
```

## Dotfiles

Dotfiles live under `dots/` and are linked into `$HOME` with GNU Stow.

Example:

```bash
cd dots
stow -v -R -t ~ git
```

To stow the configured baseline:

```bash
cd dots
./stowit.sh
```

To install the root-compatible dotfiles for root:

```bash
cd dots
sudo ./stowit.sh
```

The `bin` stow package links scripts from `dots/bin/bin` into `~/bin`. Make sure `~/bin` is in your `PATH`.

## Notes

- The scripts install current distro package names where practical, but package availability still depends on enabled repositories.
- The VS Code extension list intentionally removes old/deprecated extensions where VS Code now has built-in functionality or a maintained replacement.
- The Python CLI tools are installed with `pipx` instead of modifying the system Python environment. That avoids modern distro Python packaging headaches. Progress, not self-inflicted pain.
