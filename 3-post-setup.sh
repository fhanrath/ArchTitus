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

echo -e "Installing CyberRe Grub theme..."
THEME_DIR="/boot/grub/themes"
THEME_NAME=CyberRe
echo -e "Creating the theme directory..."
mkdir -p "${THEME_DIR}/${THEME_NAME}"
echo -e "Copying the theme..."
cd ${HOME}/$SCRIPTHOME
cp -a ${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}
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
systemctl enable gdm.service
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
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

rm -r /root/$SCRIPTHOME
rm -r /home/$USERNAME/$SCRIPTHOME

# Replace in the same state
cd $pwd
