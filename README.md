# Personal Installer Scripts
Various installer scripts are kept here for easy access

## Arch Linux Install Script `arch-install.sh`
This script will install Arch Linux to `/mnt` on archiso when `/mnt` and `/mnt/efi` are both mounted. The script will ask for hostname and username to be used respectively. User password is also asked at the end of installation.

Arch will be installed with `systemd-boot` as bootloader and will auto boot to itself by default

To run the script
```sh
bash -c "$(curl https://raw.githubusercontent.com/naborisk/installers/main/arch-install.sh)"
```

## macOS Applications Install Script `setup-macos.sh`
This script will install my commonly used applications on macOS (via brew & mas). For the full list, refer to `PACKAGES`, `CASK_PACKAGES`, and `MAS_APPS` in the script. It will also install brew if not already installed.
