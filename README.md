# Initial-package-install

Scripts that installs selective base user packages and extensions for initial setup of users workspase in Ubuntu/Fedora.

---

## Files TOC

* Root:
  * ./initial-package-install.sh
  * ./post-initial.sh
* Extensions dir:
  * ./ext/
  * ./ext/gnome-ext.sh
  * ./ext/vscode-ext.sh
* Applications dir:
  * ./apps/
  * ./apps/pip.sh
  * ./apps/snap.sh
* Dotfiles dir:
  * ./dots/
  * ./dots/bash/.profile
  * ./dots/bash/.bashrc
  * ./dots/bin/
  * ./dots/bin/bin/
  * ./dots/bin/bin/apt-cleanup.sh
  * ./dots/bin/bin/remove-old-snaps.sh
  * .dots/git/.gitconfig
  * .dots/LICENSE
  * .dots/README.md
  * .dots/stowit.sh
  * .dots/zsh/.zshrc

### Basic usage

#### If `git` is installed on the system

```bash
git clone https://github.com/eddinn/initial-package-install.git
cd ./initial-package-install
# Run the initial install, then post install for snap, pip and extensions
bash ./initial-package-install.sh && bash ./post-initial.sh
```

#### If `git` is not already installed on the system

```bash
# Try curl, else fall back to wget
curl -L -O https://raw.githubusercontent.com/eddinn/initial-package-install/master/initial-package-install.sh || wget -L -O https://raw.githubusercontent.com/eddinn/initial-package-install/master/initial-package-install.sh
bash ./initial-package-install.sh

# Now we have git, so lets clone the repo and finish the install
rm -Rf ./initial-package-install.sh
git clone https://github.com/eddinn/initial-package-install.git
cd ./initial-package-install
bash ./post-initial.sh
```
