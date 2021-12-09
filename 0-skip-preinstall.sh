source setup.conf

mountallsubvol () {
    mount -o ${mountoptions},subvol=@home /dev/mapper/ROOT /mnt/home
    mount -o ${mountoptions},subvol=@tmp /dev/mapper/ROOT /mnt/tmp
    mount -o ${mountoptions},subvol=@.snapshots /dev/mapper/ROOT /mnt/.snapshots
    mount -o subvol=@var /dev/mapper/ROOT /mnt/var
}

timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b

echo -n "${luks_password}" | cryptsetup open ${DISK}p3 ROOT -

mkdir /mnt

mount -o ${mountoptions},subvol=@ /dev/mapper/ROOT /mnt

mountallsubvol