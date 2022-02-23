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

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"
source /root/$SCRIPTHOME/setup.conf
if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi

# set kernel parameter for decrypting the drive
if [[ "${FS}" == "luks" ]]; then
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${encryped_partition_uuid}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi

echo -e "Pulling Xenlism-Arch Grub theme..."
THEME_SUBDIR="xenlism-grub-arch-4k/Xenlism-Arch/"
LOCAL_THEME_DIR="theme/${THEME_SUBDIR}"
THEME_DIR="/boot/grub/themes"
THEME_NAME=Xenlism-Arch
THEME_REPO="git@github.com:fhanrath/Grub-themes.git"
cd /root/$SCRIPTHOME
mkdir theme
cd theme
git init
git config core.sparseCheckout true
echo $THEME_SUBDIR >> .git/info/sparse-checkout
git remote add -f origin $THEME_REPO
git pull origin main
cd ..
echo -e "Installing ${THEME_NAME} Grub theme..."
echo -e "Creating the theme directory..."
mkdir -p "${THEME_DIR}/${THEME_NAME}"
echo -e "Copying the theme..."
cp -a ${LOCAL_THEME_DIR}/* ${THEME_DIR}/${THEME_NAME}
echo -e "Backing up Grub config..."
cp -an /etc/default/grub /etc/default/grub.bak
echo -e "Setting the theme as the default..."
grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub
echo -e "Updating grub..."
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"


echo -ne "
-------------------------------------------------------------------------
                    Enabling Login Display Manager
-------------------------------------------------------------------------
"
case $sway in
    y|Y|yes|Yes|YES)
    ;;
    *)
    systemctl enable gdm.service;;
esac

echo -ne "
-------------------------------------------------------------------------
                    Changing Shell for User to zsh
-------------------------------------------------------------------------
"
chsh -s /bin/zsh $USERNAME
echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"
systemctl enable cups.service
ntpd -qg
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth
systemctl enable portmaster
systemctl enable syncthing@$USERNAME.service
su $USERNAME -c "systemctl enable pipewire --user"
su $USERNAME -c "systemctl enable pipewire-pulse --user"
su $USERNAME -c "systemctl enable pipewire_sink --user"
case $laptop in
    y|Y|yes|Yes|YES)
    systemctl enable --now auto-cpufreq.service;;
    *) echo "not enabling laptop services";;
esac
echo -ne "
-------------------------------------------------------------------------
                    Configure pipewire
-------------------------------------------------------------------------
"
/home/$USERNAME/$SCRIPTHOME/pipewire/create_config.sh
echo -ne "
-------------------------------------------------------------------------
                    Harden System
-------------------------------------------------------------------------
"
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo -ne "
-------------------------------------------------------------------------
                    Cleaning 
-------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

rm -r /root/$SCRIPTHOME
rm -r /home/$USERNAME/$SCRIPTHOME

# Replace in the same state
cd $pwd
