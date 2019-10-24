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
  * .dots/stowit.sh
  * .dots/zsh/.zshrc

### Basic usage

#### If `git` is installed on the system

```bash
git clone https://github.com/eddinn/initial-package-install.git
cd ./initial-package-install
# Run the initial install, then post install for snap, pip and extensions
./initial-package-install.sh && ./post-initial.sh
```

#### If `git` is not already installed on the system

```bash
# Try curl, else fall back to wget
curl -L -O https://raw.githubusercontent.com/eddinn/initial-package-install/master/initial-package-install.sh || wget -L -O https://raw.githubusercontent.com/eddinn/initial-package-install/master/initial-package-install.sh
./initial-package-install.sh

# Now we have git, so lets clone the repo and finish the install
rm -Rf ./initial-package-install.sh
git clone https://github.com/eddinn/initial-package-install.git
cd ./initial-package-install
./post-initial.sh
```

---

### Dotfiles and the `stowit.sh` script

> **Remember to replace or modify the dotfiles to your needs:**

#### Example usage of the `stow` command

```bash
stow -v -R -t ~ git
# Output
LINK: .gitconfig => ./dots/git/.gitconfig
ls -latr ~ | grep .git
# Output
lrwxrwxrwx  1 USER USER       28 jun 21 16:55 .gitconfig -> ./dots/git/.gitconfig
```

> `-v` is verbose, `-R` is recursive, and `-t ~` is the target directory, e.g your Home (`$HOME`) directory.

As you can see, it's relatively straight forward and simple to use..
In the code above, we will install the git directory for only the local user as root doesn’t need that. However bash which we will do next, can be used for both local users and root. We then create a bash function named stowit to run the actual stow command with our required arguments.
The first loop is to install folders for any user, and the second has a check to install for any user unless it is the root user. So lets setup the bash directory.

#### Example output from `stowit.sh`

```bash
# Run stowit.sh
./stowit.sh
# Output
Stowing apps for user:
LINK: .profile => ./dots/bash/.profile
LINK: .bashrc => ./dots/bash/.bashrc
LINK: .gitconfig => ./dots/git/.gitconfig
LINK: .zshrc => ./dots/zsh/.zshrc

All done!
```

You can see that stow is pretty smart about linking our files and folders. It linked our new bash files. But when we ran stow again it went through our previously linked git files, re re-linked them. You can actually configure how that handles those situations with different flags. stow will also abort stowing folders when it finds new files that have not been stowed before and will tell you what files so you can fix them.

> **To install the files for root, simply use `sudo`**

```bash
sudo ./stowit.sh
```

#### The `bin` directory

Inside the `./dots/bin/bin` folder we can place any binary files and scripts we want to keep around for our system.

#### Add export path to `.zshrc` or `.bashrc`

```bash
# Example with .zshrc
vim ~/.zshrc
export PATH="$HOME/bin:$PATH"
source ~/.zshrc
# Lets check and verify our path
echo $PATH
/home/USER/bin:/home/USER/.local/bin:/home/USER/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
```

We now have `/home/USER/bin` in our path where we can use to store all our scripts and files that we need to run in our environment as an alternative to `/usr/local/bin`.
