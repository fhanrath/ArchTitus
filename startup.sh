#!/usr/bin/env bash
# This script will ask users about their prefrences 
# like disk, file system, timezone, keyboard layout,
# user name, password, etc.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# set up a config file
CONFIG_FILE=$SCRIPT_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists
    touch -f $CONFIG_FILE # create file if not exists
fi

# set options in setup.conf
set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}
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
1) set_option FS btrfs;;
2) set_option FS ext4;;
3) 
echo -ne "Please enter your luks password: "
read -s luks_password # read password without echo
set_option luks_password $luks_password
set_option FS luks;;
0) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}
timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "System detected your timezone to be '$time_zone' \n"
echo -ne "Is this correct? yes/no:" 
read answer
case $answer in
    y|Y|yes|Yes|YES)
    set_option TIMEZONE $time_zone;;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read new_timezone
    set_option TIMEZONE $new_timezone;;
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
set_option KEYMAP $keymap
}

drivessd () {
echo -ne "
Is this an ssd? yes/no:
"
read ssd_drive

case $ssd_drive in
    y|Y|yes|Yes|YES)
    set_option mountoptions noatime,compress=zstd,ssd,commit=120;;
    n|N|no|NO|No)
    set_option mountoptions noatime,compress=zstd,commit=120;;
    *) echo "Wrong option. Try again";drivessd;;
esac
}

# selection for disk type
diskpart () {
# show disks present on system
lsblk -n --output TYPE,KNAME | awk '$1=="disk"{print NR,"/dev/"$2}' # show disks with /dev/ prefix
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK             
    Please make sure you know what you are doing because         
    after formating your disk there is no way to get data back      
------------------------------------------------------------------------

Please enter full path to disk: (example /dev/sda):
"
read option

drivessd
set_option DISK $option
}
userinfo () {
read -p "Please enter your username: " username
set_option USERNAME ${username,,} # convert to lower case as in issue #109 
echo -ne "Please enter your password: \n"
read -s password # read password without echo
set_option PASSWORD $password
read -rep "Please enter your hostname: " nameofmachine
set_option nameofmachine $nameofmachine
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
    set_option laptop yes;;
    n|N|no|NO|No)
    set_option laptop no;;
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
    set_option swapmb $swapmb
else
    echo "Not a positive integer. Try again"
    swapfile
fi
}
sway () {
echo -ne "
Do you want to install sway? (gnome will be installed otherwise) yes/no:
"
read sway

case $sway in
    y|Y|yes|Yes|YES)
    set_option sway yes;;
    n|N|no|NO|No)
    set_option sway no;;
    *) echo "Wrong option. Try again";sway;;
esac
}
# More features in future
# language (){}

# Starting functions
clear
logo
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
sway
games
laptop
swapfile