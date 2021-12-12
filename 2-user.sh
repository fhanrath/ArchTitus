#!/usr/bin/env bash
echo -ne "
-------------------------------------------------------------------------
   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
                        SCRIPTHOME: $SCRIPTHOME
-------------------------------------------------------------------------

Installing AUR Softwares
"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.
source ~/$SCRIPTHOME/setup.conf


echo -ne "
-------------------------------------------------------------------------
                    Manual Installs
-------------------------------------------------------------------------
"
mkdir ~/build
cd ~/build
git clone "https://aur.archlinux.org/paru.git"
cd ~/paru
rustup toolchain install stable
makepkg -si --noconfirm
cd ~/build

echo -ne "
-------------------------------------------------------------------------
                    Install Portmaster
-------------------------------------------------------------------------
"
# Clone the repository
git clone https://github.com/safing/portmaster-packaging

# Enter the repo and build/install the package (it's under linux/)
cd portmaster-packaging/linux
makepkg -si --noconfirm

cd ~

echo -ne "
-------------------------------------------------------------------------
                    Install AUR Packages
-------------------------------------------------------------------------
"

paru -S --noconfirm --needed - < ~/$SCRIPTHOME/pkg-files/aur-pkgs.txt

case $games in
    y|Y|yes|Yes|YES)
    paru -S --noconfirm --needed - < ~/$SCRIPTHOME/pkg-files/aur-pkgs-gaming.txt;;
    *) echo "not installing gaming packages";;
esac

case $laptop in
    y|Y|yes|Yes|YES)
    paru -S --noconfirm --needed - < ~/$SCRIPTHOME/pkg-files/aur-pkgs-laptop.txt;;
    *) echo "not installing laptop packages";;
esac

touch "~/.cache/zshhistory"
cd ~
git clone "https://github.com/fhanrath/dotfiles"
cd dotfiles
./copy_dotfiles.sh
cd ~

export PATH=$PATH:~/.local/bin


echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
exit
