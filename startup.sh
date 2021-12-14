#!/usr/bin/env bash
# This script will ask users about their prefrences like disk, file system,
logo () {
# This will be shown on every set as user is progressing
echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
------------------------------------------------------------------------
            Please select presetup settings for your system              
------------------------------------------------------------------------
"
}
filesystem () {
# This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
echo -ne "
    Please Select your file system for both boot and root
    1)      btrfs
    2)      ext4
    3)      luks with btrfs
    0)      exit
"
read FS
case $FS in
1) echo "FS=btrfs" >> setup.conf;;
2) echo "FS=ext4" >> setup.conf;;
3) 
echo -ne "Please enter your luks password: "
read luks_password
echo "luks_password=$luks_password" >> setup.conf
echo "FS=luks" >> setup.conf;;
0) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}
timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "System detected your timezone to be '$time_zone'"
echo -ne "Is this correct? yes/no:" 
read answer
case $answer in
    y|Y|yes|Yes|YES)
    echo "timezone=$time_zone" >> setup.conf;;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read new_timezone
    echo "timezone=$new_timezone" >> setup.conf;;
    *) echo "Wrong option. Try again";timezone;;
esac
}
keymap () {
# These are default key maps as presented in official arch repo archinstall
echo -ne "
Please select key board layout from this list
    -by
    -ca
    -cf
    -cz
    -de
    -dk
    -es
    -et
    -fa
    -fi
    -fr
    -gr
    -hu
    -il
    -it
    -lt
    -lv
    -mk
    -nl
    -no
    -pl
    -ro
    -ru
    -sg
    -ua
    -uk
    -us

"
read -p "Your key boards layout:" keymap
echo "keymap=$keymap" >> setup.conf
}
drivessd () {
echo -ne "
Is this an ssd? yes/no:
"
read ssd_drive

case $ssd_drive in
    y|Y|yes|Yes|YES)
    echo "mountoptions=noatime,compress=zstd,ssd,commit=120" >> setup.conf;;
    n|N|no|NO|No)
    echo "mountoptions=noatime,compress=zstd,commit=120" >> setup.conf;;
    *) echo "Wrong option. Try again";drivessd;;
esac
}
diskpart () {
lsblk
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK             
    Please make sure you know what you are doing because         
    after formating your disk there is no way to get data back      
------------------------------------------------------------------------

Please enter disk to work on: (example /dev/sda):
"
read option
echo "DISK=$option" >> setup.conf

drivessd
}
userinfo () {
echo -ne "Please enter username: "
read username
echo "username=$username" >> setup.conf
echo -ne "Please enter your password: "
read password
echo "password=$password" >> setup.conf
echo -ne "Please enter your hostname: "
read hostname
echo "hostname=$hostname" >> setup.conf
}
games () {
echo -ne "
Do you want to play games? yes/no:
"
read games

case $games in
    y|Y|yes|Yes|YES)
    echo "games=yes" >> setup.conf;;
    n|N|no|NO|No)
    echo "games=no" >> setup.conf;;
    *) echo "Wrong option. Try again";games;;
esac
}
laptop () {
echo -ne "
Do you install on a laptop or otherwise mobile device? yes/no:
"
read laptop

case $laptop in
    y|Y|yes|Yes|YES)
    echo "laptop=yes" >> setup.conf;;
    n|N|no|NO|No)
    echo "laptop=no" >> setup.conf;;
    *) echo "Wrong option. Try again";laptop;;
esac
}
swapfile () {
echo -ne "
How big should your swap file be? (in GB, 0 = no swap)
"
read swapgb

if [[ $swapgb ]] && [ $swapgb -eq $swapgb 2>/dev/null ] && [ $swapgb -ge 0 ]
then
    swapmb=$(($swapgb*1024))
    echo $swapmb >> setup.conf
else
    echo "Not a positive integer. Try again"
    swapfile
fi
}
# More features in future
# language (){}
rm -rf setup.conf &>/dev/null
userinfo
clear
logo
diskpart
clear
logo
filesystem
clear
logo
timezone
clear
logo
keymap
games
laptop
swapfile