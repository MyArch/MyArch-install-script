# !/bin/bash
#
# Written by Carl Duff for Architect Linux
#
# Modified for MyArch by Nandcire
#
# This program is free software, provided under the GNU General Public License
# as published by the Free Software Foundation. So feel free to copy, distribute,
# or modify it as you wish.
#

################################################################################
##
## Variables
##
################################################################################

# Create a temporary file to store menu selections
ANSWER="/tmp/.install"          # Basic menu selections
PACKAGES="/tmp/.packages"       # Packages to install
BTRFS_OPTS="/tmp/.btrfs_opts"   # BTRFS mount options
# Save retyping
VERSION="Installation script for Archlinux"
# Installation
BASE_DEVEL=0            # Has base-devel group been installed ?
DM_INST=""							# Which DMs have been installed?
DM_ENABLED=0						# Has a display manager been enabled?
NM_INST=""							# Which NMs have been installed?
NM_ENABLED=0						# Has a network connection manager been enabled?
BOOTLOADER="n/a"        # Which bootloader has been installed?
KEYMAP="us"             # Virtual console keymap. Default is "us"
XKBMAP="us"             # X11 keyboard layout. Default is "us"
ZONE=""                 # For time
SUBZONE=""              # For time
LOCALE="en_US.UTF-8"    # System locale. Default is "en_US.UTF-8"
KERNEL=0                   # Has the LTS Kernel been installed?
GRAPHIC_CARD=""         # graphics card
INTEGRATED_GC=""        # Integrated graphics card for NVIDIA
NVIDIA_INST=0           # Indicates if NVIDIA proprietary driver has been installed
NVIDIA=""               # NVIDIA driver(s) to install depending on kernel(s)
VB_MOD=""               # Virtualbox guest modules to install depending on kernel
SHOW_ONCE=0             # Show de_wm information only once
# Architecture
ARCHI=`uname -m`        # Display whether 32 or 64 bit system
SYSTEM="Unknown"        # Display whether system is BIOS or UEFI. Default is "unknown"
ROOT_PART=""            # ROOT partition
UEFI_PART=""            # UEFI partition
UEFI_MOUNT=""           # UEFI mountpoint
# Menu highlighting (automated step progression)
HIGHLIGHT=0             # Highlight items for Main Menu
HIGHLIGHT_SUB=0         # Highlight items for submenus
SUB_MENU=""             # Submenu to be highlighted
# Logical Volume Management
LVM=0                   # Logical Volume Management Detected?
LVM_ROOT=0              # LVM used for Root?
LVM_SEP_BOOT=0          # 1 = Seperate /boot, 2 = seperate /boot & LVM
LVM_DISABLE=0           # Option to allow user to deactive existing LVM
LVM_VG=""               # Name of volume group to create
LVM_VG_MB=0             # MB remaining of VG
LVM_LV_NAME=""          # Name of LV to create
LV_SIZE_INVALID=0       # Is LVM LV size entered valid?
VG_SIZE_TYPE=""         # Is VG in Gigabytes or Megabytes?
# LUKS
LUKS=0                  # Luks Detected?
# Installation
PACOPT=-1               # Option for confirmation with pacstrap
MOUNTPOINT="/mnt"       # Installation: Root mount
MOUNT=""                # Installation: All other mounts branching from Root
BTRFS=0                 # BTRFS used? "1" = btrfs alone, "2" = btrfs + subvolume(s)
BTRFS_MNT=""            # used for syslinux where /mnt is a btrfs subvolume
F2FS=0                   # F2FS used? "1" = yes.
# Language Support
CURR_LOCALE="en_US.UTF-8"   # Default Locale
FONT=""                 # Set new font if necessary
# Edit Files
FILE=""                 # Which file is to be opened?
FILE2=""                # Which second file is to be opened?

################################################################################
##
## Core Functions
##
################################################################################

# General dialog function with backtitle
DIALOG() {
  dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" "$@"
}

# Redefine pacstrap for asking during installation
PACSTRAP() {
  if ! arch_chroot "pacman -Q $@" > /dev/null ; then
    clear
    if [[ PACOPT == 0 ]] ; then
      pacstrap -i ${MOUNTPOINT} "$@"
    else
      pacstrap ${MOUNTPOINT} "$@"
    fi
  fi
}

# Add locale on-the-fly and sets source translation file for installer
select_language() {
  # Set english as base in case some language miss some translation
  source ./language/english.trans
  DIALOG --title " Select Language " \
  --menu "\nLanguage / sprache / taal / språk / lingua / idioma / nyelv / língua" 0 0 12 \
  "1" $"English		(en)" \
  "2" $"Italian 		(it)" \
  "3" $"Russian 		(ru)" \
  "4" $"Turkish 		(tr)" \
  "5" $"Dutch 		(nl)" \
  "6" $"Greek 		(el)" \
  "7" $"Danish 		(da)" \
  "8" $"Hungarian 	(hu)" \
  "9" $"Portuguese 	(pt)" \
  "10" $"German	 	(de)" \
  "11" $"French		(fr)" \
  "12" $"Polish		(pl)" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    CURR_LOCALE="en_US.UTF-8"
    ;;
    "2")
    source ./language/italian.trans
    CURR_LOCALE="it_IT.UTF-8"
    ;;
    "3")
    source ./language/russian.trans
    CURR_LOCALE="ru_RU.UTF-8"
    FONT="LatKaCyrHeb-14.psfu"
    ;;
    "4")
    source ./language/turkish.trans
    CURR_LOCALE="tr_TR.UTF-8"
    FONT="LatKaCyrHeb-14.psfu"
    ;;
    "5")
    source ./language/dutch.trans
    CURR_LOCALE="nl_NL.UTF-8"
    ;;
    "6")
    source ./language/greek.trans
    CURR_LOCALE="el_GR.UTF-8"
    FONT="iso07u-16.psfu"
    ;;
    "7")
    source ./language/danish.trans
    CURR_LOCALE="da_DK.UTF-8"
    ;;
    "8")
    source ./language/hungarian.trans
    CURR_LOCALE="hu_HU.UTF-8"
    FONT="lat2-16.psfu"
    ;;
    "9")
    source ./language/portuguese.trans
    CURR_LOCALE="pt_BR.UTF-8"
    ;;
    "10")
    source ./language/german.trans
    CURR_LOCALE="de_DE.UTF-8"
    ;;
    "11")
    source ./language/french.trans
    CURR_LOCALE="fr_FR.UTF-8"
    ;;
    "12")
    source ./language/polish.trans
    CURR_LOCALE="pl_PL.UTF-8"
    FONT="latarcyrheb-sun16"
    ;;
    *)
    exit 0
    ;;
  esac
  # Generate the chosen locale and set the language
  sed -i "s/#${CURR_LOCALE}/${CURR_LOCALE}/" /etc/locale.gen
  locale-gen >/dev/null 2>&1
  export LANG=${CURR_LOCALE}
  [[ $FONT != "" ]] && setfont $FONT
}

# Check user is root, and that there is an active internet connection
# Seperated the checks into seperate "if" statements for readability.
check_requirements() {
  DIALOG --title "$_ChkTitle" --infobox "$_ChkBody" 0 0
  sleep 2
  if [[ `whoami` != "root" ]]; then
    DIALOG --title "$_RtFailTitle" --msgbox "$_RtFailBody" 0 0
    exit 1
  fi
  if [[ ! $(ping -c 1 google.com) ]]; then
    DIALOG --title "$_ConFailTitle" --msgbox "$_ConFailBody" 0 0
    exit 1
  fi
  # This will only be executed where neither of the above checks are true.
  # The error log is also cleared, just in case something is there from a previous use of the installer.
  DIALOG --title "$_ReqMetTitle" --msgbox "$_ReqMetBody" 0 0
  clear
  echo "" > /tmp/.errlog
}

# Adapted from AIS. Checks if system is made by Apple, whether the system is
# BIOS or UEFI, and for LVM and/or LUKS.
id_system() {
  # Apple System Detection
  if [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Inc.' ]] || [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Computer, Inc.' ]]; then
    modprobe -r -q efivars || true  # if MAC
  else
    modprobe -q efivarfs            # all others
  fi
  # BIOS or UEFI Detection
  if [[ -d "/sys/firmware/efi/" ]]; then
    # Mount efivarfs if it is not already mounted
    if [[ -z $(mount | grep /sys/firmware/efi/efivars) ]]; then
      mount -t efivarfs efivarfs /sys/firmware/efi/efivars
    fi
    SYSTEM="UEFI"
  else
    SYSTEM="BIOS"
  fi
  # Encryption (LUKS) Detection
  [[ $(lsblk -o TYPE | grep "crypt") == "" ]] && LUKS=0 || LUKS=1
}

# Adapted from AIS. An excellent bit of code!
arch_chroot() {
  arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
}

# If there is an error, display it, clear the log and then go back to the main menu (no point in continuing).
check_for_error() {
  if [[ $? -eq 1 ]] && [[ $(cat /tmp/.errlog | grep -i "error") != "" ]]; then
    DIALOG --title "$_ErrTitle" --msgbox "$(cat /tmp/.errlog)" 0 0
    echo "" > /tmp/.errlog
    main_menu_online
  fi
}

# Ensure that a partition is mounted
check_mount() {
  if [[ $(lsblk -o MOUNTPOINT | grep ${MOUNTPOINT}) == "" ]]; then
    DIALOG --title "$_ErrTitle" --msgbox "$_ErrNoMount" 0 0
    main_menu_online
  fi
}

# Ensure that Arch has been installed
check_base() {
  if [[ ! -e ${MOUNTPOINT}/etc ]]; then
    DIALOG --title "$_ErrTitle" --msgbox "$_ErrNoBase" 0 0
    main_menu_online
  fi
}

# Simple code to show devices / partitions.
show_devices() {
  lsblk -o NAME,MODEL,TYPE,FSTYPE,SIZE,MOUNTPOINT | grep "disk\|part\|lvm\|crypt\|NAME\|MODEL\|TYPE\|FSTYPE\|SIZE\|MOUNTPOINT" > /tmp/.devlist
  DIALOG --title "$_DevShowOpt" --textbox /tmp/.devlist 0 0
}

checklist_of_user() {
  USER_LIST=""
  user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
  for i in ${user_list[@]}; do
    USER_LIST="${USER_LIST} ${i} - off"
  done
}

################################################################################
##
## Configuration Functions
##
################################################################################

# Originally adapted from AIS. Added option to allow users to edit the mirrorlist.
configure_mirrorlist() {

  # Generate a mirrorlist based on the country chosen.
  mirror_by_country() {
    COUNTRY_LIST=""
    countries_list="AU Australia AT Austria BY Belarus BE Belgium BR Brazil BG Bulgaria CA Canada CL Chile CN China CO Colombia CZ Czech_Republic DK Denmark EE Estonia FI Finland FR France DE Germany GB United_Kingdom GR Greece HU Hungary IN India IE Ireland IL Israel IT Italy JP Japan KZ Kazakhstan KR Korea LV Latvia LU Luxembourg MK Macedonia NL Netherlands NC New_Caledonia NZ New_Zealand NO Norway PL Poland PT Portugal RO Romania RU Russia RS Serbia SG Singapore SK Slovakia ZA South_Africa ES Spain LK Sri_Lanka SE Sweden CH Switzerland TW Taiwan TR Turkey UA Ukraine US United_States UZ Uzbekistan VN Vietnam"
    for i in ${countries_list}; do
      COUNTRY_LIST="${COUNTRY_LIST} ${i}"
    done
    DIALOG --title "$_MirrorbyCountry" --menu "$_MirrorCntryBody" 0 0 0 $COUNTRY_LIST 2>${ANSWER} || prep_menu
    URL="https://www.archlinux.org/mirrorlist/?country=$(cat ${COUNTRY_CODE})&use_mirror_status=on"
    MIRROR_TEMP=$(mktemp --suffix=-mirrorlist)
    # Get latest mirror list and save to tmpfile
    DIALOG --title "$_MirrorGenTitle" --infobox "$_PlsWaitBody" 0 0
    curl -so ${MIRROR_TEMP} ${URL} 2>/tmp/.errlog
    check_for_error
    sed -i 's/^#Server/Server/g' ${MIRROR_TEMP}
    nano ${MIRROR_TEMP}
    DIALOG --title "$_MirrorGenTitle" --yesno "$_MirrorGenQ" 0 0
    if [[ $? -eq 0 ]];then
      mv -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
      mv -f ${MIRROR_TEMP} /etc/pacman.d/mirrorlist
      chmod +r /etc/pacman.d/mirrorlist
      DIALOG --title "$_MirrorGenTitle" --infobox "$_MirrorGenDone" 0 0
      sleep 2
    else
      prep_menu
    fi
  }

  DIALOG --title "$_MirrorlistTitle" \
  --menu "$_MirrorlistBody" 0 0 5 \
  "1" "$_MirrorbyCountry" \
  "2" "$_MirrorEdit" \
  "3" "$_MirrorRankTitle" \
  "4" "$_MirrorRestTitle" \
  "5" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    mirror_by_country
    ;;
    "2")
    nano /etc/pacman.d/mirrorlist
    ;;
    "3")
    DIALOG --title "$_MirrorRankTitle" --infobox "$_MirrorRankBody $_PlsWaitBody" 0 0
    cp -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    rankmirrors -n 10 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist 2>/tmp/.errlog
    check_for_error
    DIALOG --title "$_MirrorRankTitle" --infobox "$_MirrorRankDone" 0 0
    sleep 2
    ;;
    "4")
    if [[ -e /etc/pacman.d/mirrorlist.orig ]]; then
      mv -f /etc/pacman.d/mirrorlist.orig /etc/pacman.d/mirrorlist
      DIALOG --title "$_MirrorRestTitle" --msgbox "$_MirrorRestDone" 0 0
    else
      DIALOG --title "$_ErrTitle" --msgbox "$_MirrorNoneBody" 0 0
    fi
    ;;
    *)
    prep_menu
    ;;
  esac
  configure_mirrorlist
}

# virtual console keymap
set_keymap() {
  KEYMAPS=""
  for i in $(ls -R /usr/share/kbd/keymaps | grep "map.gz" | sed 's/\.map\.gz//g' | sort); do
    KEYMAPS="${KEYMAPS} ${i} -"
  done
  DIALOG --title "$_VCKeymapTitle" \
  --menu "$_VCKeymapBody" 20 40 16 ${KEYMAPS} 2>${ANSWER} || prep_menu
  KEYMAP=$(cat ${ANSWER})
  loadkeys $KEYMAP 2>/tmp/.errlog
  check_for_error
  echo -e "KEYMAP=${KEYMAP}\nFONT=${FONT}" > /tmp/vconsole.conf
}

# Set keymap for X11
set_xkbmap() {
  XKBMAP_LIST=""
  keymaps_xkb=("af Afghani al Albanian am Armenian ara Arabic at German-Austria az Azerbaijani ba Bosnian bd Bangla be Belgian bg Bulgarian br Portuguese-Brazil bt Dzongkha bw Tswana by Belarusian ca French-Canada cd French-DR-Congo ch German-Switzerland cm English-Cameroon cn Chinese cz Czech de German dk Danish ee Estonian epo Esperanto es Spanish et Amharic fo Faroese fi Finnish fr French gb English-UK ge Georgian gh English-Ghana gn French-Guinea gr Greek hr Croatian hu Hungarian ie Irish il Hebrew iq Iraqi ir Persian is Icelandic it Italian jp Japanese ke Swahili-Kenya kg Kyrgyz kh Khmer-Cambodia kr Korean kz Kazakh la Lao latam Spanish-Lat-American lk Sinhala-phonetic lt Lithuanian lv Latvian ma Arabic-Morocco mao Maori md Moldavian me Montenegrin mk Macedonian ml Bambara mm Burmese mn Mongolian mt Maltese mv Dhivehi ng English-Nigeria nl Dutch no Norwegian np Nepali ph Filipino pk Urdu-Pakistan pl Polish pt Portuguese ro Romanian rs Serbian ru Russian se Swedish si Slovenian sk Slovak sn Wolof sy Arabic-Syria th Thai tj Tajik tm Turkmen tr Turkish tw Taiwanese tz Swahili-Tanzania ua Ukrainian us English-US uz Uzbek vn Vietnamese za English-S-Africa")
  for i in ${keymaps_xkb}; do
    XKBMAP_LIST="${XKBMAP_LIST} ${i}"
  done
  DIALOG --title "$_PrepKBLayout" --menu "$_XkbmapBody" 0 0 16 ${XKBMAP_LIST} 2>${ANSWER} || config_base_menu
  XKBMAP=$(cat ${ANSWER} |sed 's/_.*//')
  echo -e "Section "\"InputClass"\"\nIdentifier "\"system-keyboard"\"\nMatchIsKeyboard "\"on"\"\nOption "\"XkbLayout"\" "\"${XKBMAP}"\"\nEndSection" > /tmp/00-keyboard.conf
}

# locale array generation code adapted from the Manjaro 0.8 installer
set_locale() {
  LOCALES=""
  for i in $(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8); do
    LOCALES="${LOCALES} ${i} -"
  done
  DIALOG --title "$_LocateTitle" --menu "$_localeBody" 0 0 16 ${LOCALES} 2>${ANSWER} || config_base_menu
  LOCALE=$(cat ${ANSWER})
  echo "LANG=\"${LOCALE}\"" > ${MOUNTPOINT}/etc/locale.conf
  sed -i "s/#${LOCALE}/${LOCALE}/" ${MOUNTPOINT}/etc/locale.gen 2>/tmp/.errlog
  arch_chroot "locale-gen" >/dev/null 2>>/tmp/.errlog
  check_for_error
}

# Set Zone and Sub-Zone
set_timezone() {
  ZONE=""
  for i in $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud); do
    ZONE="$ZONE ${i} -"
  done
  DIALOG --title "$_ConfBseTimeHC" --menu "$_TimeZBody" 0 0 10 ${ZONE} 2>${ANSWER} || config_base_menu
  ZONE=$(cat ${ANSWER})
  SUBZONE=""
  for i in $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "${ZONE}/" | sed "s/${ZONE}\///g" | sort -ud); do
    SUBZONE="$SUBZONE ${i} -"
  done
  DIALOG --title "$_ConfBseTimeHC" --menu "$_TimeSubZBody" 0 0 11 ${SUBZONE} 2>${ANSWER} || config_base_menu
  SUBZONE=$(cat ${ANSWER})
  DIALOG --title "$_ConfBseTimeHC" --yesno "$_TimeZQ ${ZONE}/${SUBZONE} ?" 0 0
  if [[ $? -eq 0 ]]; then
    arch_chroot "ln -s /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime" 2>/tmp/.errlog
    check_for_error
  else
    config_base_menu
  fi
}

set_hw_clock() {
  DIALOG --title "$_ConfBseTimeHC" --menu "$_HwCBody" 0 0 2 \
  "utc" "-" \
  "localtime" "-" 2>${ANSWER}
  [[ $(cat ${ANSWER}) != "" ]] && arch_chroot "hwclock --systohc --$(cat ${ANSWER})"  2>/tmp/.errlog && check_for_error
}

# Function will not allow incorrect UUID type for installed system.
generate_fstab() {
  DIALOG --title "$_ConfBseFstab" --menu "$_FstabBody" 0 0 4 \
  "genfstab -p" "$_FstabDevName" \
  "genfstab -L -p" "$_FstabDevLabel" \
  "genfstab -U -p" "$_FstabDevUUID" \
  "genfstab -t PARTUUID -p" "$_FstabDevPtUUID" 2>${ANSWER}
  if [[ $(cat ${ANSWER}) != "" ]]; then
    if ([[ $SYSTEM == "BIOS" ]] && [[ $(cat ${ANSWER}) == "genfstab -t PARTUUID -p" ]]) \
    || ([[ $SYSTEM == "UEFI" ]] && [[ $(cat ${ANSWER}) == "genfstab -U -p" ]] ); then
      DIALOG --title " $_ErrTitle " --msgbox "$_FstabErr ($SYSTEM)\n\n" 0 0
      generate_fstab
    fi
    $(cat ${ANSWER}) ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab 2>/tmp/.errlog
    check_for_error
    [[ -f ${MOUNTPOINT}/swapfile ]] && sed -i "s/\\${MOUNTPOINT}//" ${MOUNTPOINT}/etc/fstab
  fi
}

set_hostname() {
  DIALOG --title "$_ConfBseHost" --inputbox "$_HostNameBody" 0 0 \
  "arch" 2>${ANSWER} || config_base_menu
  echo $(cat ${ANSWER}) > ${MOUNTPOINT}/etc/hostname 2>/tmp/.errlog
  echo -e "#<ip-address>\t<hostname.domain.org>\t<hostname>\n127.0.0.1\tlocalhost.localdomain\tlocalhost\t$(cat ${HOST_NAME})\n::1\tlocalhost.localdomain\tlocalhost\t$(cat {HOST_NAME})" > ${MOUNTPOINT}/etc/hosts 2>>/tmp/.errlog
  check_for_error
}

# Adapted and simplified from the Manjaro 0.8 and Antergos 2.0 installers
set_root_password() {
  DIALOG --title "$_ConfUsrRoot" --clear --insecure --passwordbox "$_PassRtBody" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD=$(cat ${ANSWER})
  DIALOG --title "$_ConfUsrRoot" --clear --insecure --passwordbox "$_PassRtBody2" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD2=$(cat ${ANSWER})
  if [[ $PASSWD == $PASSWD2 ]]; then
    echo -e "${PASSWD}\n${PASSWD}" > /tmp/.passwd
    arch_chroot "passwd root" < /tmp/.passwd >/dev/null 2>/tmp/.errlog
    rm /tmp/.passwd
    check_for_error
  else
    DIALOG --title "$_ErrTitle" --msgbox "$_PassRtErrBody" 0 0
    set_root_password
  fi
}

# Originally adapted from the Antergos 2.0 installer
create_new_user() {
  DIALOG --title "$_NUsrTitle" --inputbox "$_NUsrBody" 0 0 "" 2>${ANSWER} || config_user_menu
  USER=$(cat ${ANSWER})
  # Loop while user name is blank, has spaces, or has capital letters in it.
  while [[ ${#USER} -eq 0 ]] || [[ $USER =~ \ |\' ]] || [[ $USER =~ [^a-z0-9\ ] ]]; do
    DIALOG --title "$_NUsrTitle" --inputbox "$_NUsrErrBody" 0 0 "" 2>${ANSWER} || config_user_menu
    USER=$(cat ${ANSWER})
  done
  # Enter password. This step will only be reached where the loop has been skipped or broken.
  DIALOG --title "$_ConfUsrNew" --clear --insecure --passwordbox "$_PassNUsrBody $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD=$(cat ${ANSWER})
  DIALOG --title "$_ConfUsrNew" --clear --insecure --passwordbox "$_PassNUsrBody2 $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD2=$(cat ${ANSWER})
  # loop while passwords entered do not match.
  while [[ $PASSWD != $PASSWD2 ]]; do
    DIALOG --title "$_ErrTitle" --msgbox "$_PassNUsrErrBody" 0 0
    DIALOG --title "$_ConfUsrNew" --clear --insecure --passwordbox "$_PassNUsrBody $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
    PASSWD=$(cat ${ANSWER})
    DIALOG --title "$_ConfUsrNew" --clear --insecure --passwordbox "$_PassNUsrBody2 $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
    PASSWD2=$(cat ${ANSWER})
  done
  # create new user. This step will only be reached where the password loop has been skipped or broken.
  DIALOG --title "$_ConfUsrNew" --infobox "$_NUsrSetBody" 0 0
  sleep 2
  # Create the user, set password, then remove temporary password file
  arch_chroot "useradd ${USER} -m -g users -G wheel,storage,power,network,video,audio,lp -s /bin/bash" 2>/tmp/.errlog
  check_for_error
  echo -e "${PASSWD}\n${PASSWD}" > /tmp/.passwd
  arch_chroot "passwd ${USER}" < /tmp/.passwd >/dev/null 2>/tmp/.errlog
  rm /tmp/.passwd
  check_for_error
  # Set up basic configuration files and permissions for user
  arch_chroot "cp /etc/skel/.bashrc /home/${USER}"
  arch_chroot "chown -R ${USER}:users /home/${USER}"
  sed -i '/%wheel ALL=(ALL) ALL/s/^#//' ${MOUNTPOINT}/etc/sudoers
}

run_mkinitcpio() {
  clear
  # If $LVM is being used, add the lvm2 hook
  [[ $LVM -eq 1 ]] && sed -i 's/block filesystems/block lvm2 filesystems/g' ${MOUNTPOINT}/etc/mkinitcpio.conf
  # Amend command depending on kernel(s) installed
  ([[ $KERNEL -eq 1 ]] || [[ $KERNEL -eq 3 ]]) && arch_chroot "mkinitcpio -p linux" 2>/tmp/.errlog
  ([[ $KERNEL -eq 2 ]] || [[ $KERNEL -eq 3 ]]) && arch_chroot "mkinitcpio -p linux-lts" 2>>/tmp/.errlog
  check_for_error
}

################################################################################
##
## System and Partitioning Functions
##
################################################################################

# Unmount partitions.
umount_partitions(){
  MOUNTED=""
  MOUNTED=$(mount | grep "${MOUNTPOINT}" | awk '{print $3}' | sort -r)
  swapoff -a
  for i in ${MOUNTED[@]}; do
    umount $i >/dev/null 2>>/tmp/.errlog
  done
  check_for_error
}

# Revised to deal with partion sizes now being displayed to the user
confirm_mount() {
  if [[ $(mount | grep $1) ]]; then
    DIALOG --title "$_MntStatusTitle" --infobox "$_MntStatusSucc" 0 0
    sleep 2
    PARTITIONS=$(echo $PARTITIONS | sed "s~${PARTITION} [0-9]*[G-M]~~" | sed "s~${PARTITION} [0-9]*\.[0-9]*[G-M]~~" | sed s~${PARTITION}$' -'~~)
    NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS - 1 ))
  else
    DIALOG --title "$_MntStatusTitle" --infobox "$_MntStatusFail" 0 0
    sleep 2
    prep_menu
  fi
}

# btrfs specific for subvolumes
confirm_mount_btrfs() {
  if [[ $(mount | grep $1) ]]; then
    DIALOG --title "$_MntStatusTitle" --infobox "$_MntStatusSucc\n$(cat ${BTRFS_OPTS})",subvol="${BTRFS_MSUB_VOL}\n\n" 0 0
    sleep 2
  else
    DIALOG --title "$_MntStatusTitle" --infobox "$_MntStatusFail" 0 0
    sleep 2
    prep_menu
  fi
}

# This function does not assume that the formatted device  is the Root installation device as
# more than one device may be formatted. Root is set in the mount_partitions function.
select_device() {
  DEVICE=""
  devices_list=$(lsblk -lno NAME,SIZE,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u);
  for i in ${devices_list[@]}; do
    DEVICE="${DEVICE} ${i}"
  done
  DIALOG --title "$_DevSelTitle" --menu "$_DevSelBody" 0 0 4 ${DEVICE} 2>${ANSWER} || prep_menu
  DEVICE=$(cat ${ANSWER})
}

create_partitions(){

  # Securely destroy all data on a given device.
  secure_wipe(){
    # Warn the user. If they proceed, wipe the selected device.
    DIALOG --title " $_PartOptWipe " --yesno "$_AutoPartWipeBody1 ${DEVICE} $_AutoPartWipeBody" 0 0
    if [[ $? -eq 0 ]]; then
      clear
      # Install wipe where not already installed. Much faster than dd
      if [[ ! -e /usr/bin/wipefs ]]; then
        pacman -Sy --noconfirm wipe 2>/tmp/.errlog
        check_for_error
        clear
      fi
      clear
      wipe -Ifre ${DEVICE}
      # Alternate dd command - requires pv to be installed
      #dd if=/dev/zero | pv | dd of=${DEVICE} iflag=nocache oflag=direct bs=4096 2>/tmp/.errlog
      check_for_error
    else
      create_partitions
    fi
  }

  # BIOS and UEFI
  auto_partition(){
    DIALOG --title "$_PrepPartDisk" --yesno "$_AutoPartBody1 $DEVICE $_AutoPartBody2" 0 0
    if [[ $? -eq 0 ]]; then
      # Delete existing partitions
      parted -s ${DEVICE} print | awk '/^ / {print $1}' > /tmp/.del_parts
      for del_part in $(tac /tmp/.del_parts); do
        parted -s ${DEVICE} rm ${del_part} 2>/tmp/.errlog
        check_for_error
      done
      # Identify the partition table
      part_table=$(parted -s ${DEVICE} print | grep -i 'partition table' | awk '{print $3}')
      # Create partition table if one does not already exist
      ([[ $SYSTEM == "BIOS" ]] && [[ $part_table != "msdos" ]]) && parted -s ${DEVICE} mklabel msdos 2>/tmp/.errlog
      ([[ $SYSTEM == "UEFI" ]] && [[ $part_table != "gpt" ]]) && parted -s ${DEVICE} mklabel gpt 2>/tmp/.errlog
      check_for_error
      # Create paritions (same basic partitioning scheme for BIOS and UEFI)
      if [[ $SYSTEM == "BIOS" ]]; then
        parted -s ${DEVICE} mkpart primary ext3 1MiB 513MiB 2>/tmp/.errlog
      else
        parted -s ${DEVICE} mkpart ESP fat32 1MiB 513MiB 2>/tmp/.errlog
      fi
      parted -s ${DEVICE} set 1 boot on 2>>/tmp/.errlog
      parted -s ${DEVICE} mkpart primary ext3 513MiB 100% 2>>/tmp/.errlog
      check_for_error
      # Show created partitions
      lsblk ${DEVICE} -o NAME,TYPE,FSTYPE,SIZE > /tmp/.devlist
      DIALOG --title "" --textbox /tmp/.devlist 0 0
    else
      create_partitions
    fi
  }

  # Partitioning Menu
  DIALOG --title "$_PrepPartDisk" --menu "$_PartToolBody" 0 0 7 \
  "$_PartOptWipe" "BIOS & UEFI" \
  "$_PartOptAuto" "BIOS & UEFI" \
  "parted" "BIOS & UEFI" \
  "cfdisk" "BIOS/MBR" \
  "cgdisk" "UEFI/GPT" \
  "fdisk"  "BIOS & UEFI" \
  "gdisk"  "UEFI/GPT" 2>${ANSWER}
  clear
  # If something selected
  if [[ $(cat ${ANSWER}) != "" ]]; then
    if ([[ $(cat ${ANSWER}) != $_PartOptWipe ]] &&  [[ $(cat ${ANSWER}) != $_PartOptAuto ]]); then
      cat ${ANSWER} ${DEVICE}
      prep_menu
    else
      [[ $(cat ${ANSWER}) == $_PartOptWipe ]] && secure_wipe && create_partitions
      [[ $(cat ${ANSWER}) == $_PartOptAuto ]] && auto_partition
    fi
  fi
}

# Revised to include partition sizes. Finds all available partitions and
# generate a list of them. This also includes partitions on different devices.
find_partitions() {
  PARTITIONS=""
  NUMBER_PARTITIONS=0
  partition_list=$(lsblk -lno NAME,SIZE,TYPE | grep 'part\|lvm\|crypt' | sed 's/part/\/dev\//g' | sed 's/lvm\|crypt/\/dev\/mapper\//g' | awk '{print $3$1 " " $2}' | sort -u)
  for i in ${partition_list[@]}; do
    PARTITIONS="${PARTITIONS} ${i}"
    NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS + 1 ))
  done
  # Divide by two as partition sizes are also counted.
  NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS / 2 ))
  # Deal with incorrect partitioning
  if ([[ $SYSTEM == "UEFI" ]] && [[ $NUMBER_PARTITIONS -lt 2 ]]) || ([[ $SYSTEM == "BIOS" ]] && [[ $NUMBER_PARTITIONS -eq 0 ]]); then
    DIALOG --title "$_ErrTitle" --msgbox "$_PartErrBody" 0 0
    create_partitions
  fi
}

# Set static list of filesystems rather than on-the-fly. Partially as most require additional flags, and
# partially because some don't seem to be viable.
select_filesystem(){
  # Clear special FS type flags
  BTRFS=0
  F2FS=0
  DIALOG --title "$_FSTitle" --menu "$_FSBody" 0 0 12 \
  "$_FSSkip" "-" \
  "mkfs.btrfs -f" "btrfs" \
  "mkfs.ext2 -q" "ext2" \
  "mkfs.ext3 -q" "ext3" \
  "mkfs.ext4 -q" "ext4" \
  "mkfs.f2fs" "f2fs" \
  "mkfs.jfs -q" "jfs" \
  "mkfs.nilfs2 -q" "nilfs2" \
  "mkfs.ntfs -q" "ntfs" \
  "mkfs.reiserfs -q" "reiserfs" \
  "mkfs.vfat -F32" "vfat" \
  "mkfs.xfs -f" "xfs" 2>${ANSWER}
  [[ $(cat ${ANSWER}) == "" ]] && prep_menu || FILESYSTEM=$(cat ${ANSWER});
  # if f2fs selected modprobe and flag f2fs package for installation
  [[ $FILESYSTEM == "mkfs.f2fs" ]] && modprobe f2fs && F2FS=1
  # If brtfs selected, modprobe, ask if subvolumes are needed, and flag btrfs for installation
  if [[ $FILESYSTEM == "mkfs.btrfs -f" ]]; then
    modprobe btrfs
    DIALOG --title "$_btrfsSVTitle" --yesno "$_btrfsSVBody" 0 0
    [[ $? -eq 0 ]] && BTRFS=2 || BTRFS=1
  fi
}

mount_partitions() {

  # subfunction for btrfs
  btrfs_subvols() {
    BTRFS_MSUB_VOL=""
    BTRFS_OSUB_VOL=""
    BTRFS_MNT=""
    BTRFS_VOL_LIST="/tmp/.vols"
    echo "" > ${BTRFS_VOL_LIST}
    BTRFS_OSUB_NUM=1
    # Name initial subvolume from which other (optional) subvolumes may branch from
    DIALOG --title "$_btrfsSVTitle" --inputbox "$_btrfsMSubBody1 ${MOUNTPOINT}${MOUNT} $_btrfsMSubBody2" 0 0 "" 2>${ANSWER} || select_filesystem
    BTRFS_MSUB_VOL=$(cat ${ANSWER})
    # if root, then create boot flag for syslinux, systemd-boot and rEFInd bootloaders
    [[ ${MOUNT} == "" ]] && BTRFS_MNT="rootflags=subvol="$BTRFS_MSUB_VOL
    # Loop while subvolume is blank or has spaces.
    while [[ ${#BTRFS_MSUB_VOL} -eq 0 ]] || [[ $BTRFS_MSUB_VOL =~ \ |\' ]]; do
      DIALOG --title "$_ErrTitle" --inputbox "$_btrfsSVErrBody" 0 0 "" 2>${ANSWER} || select_filesystem
      BTRFS_MSUB_VOL=$(cat ${ANSWER})
      # if root, then create flag for syslinux, systemd-boot and rEFInd bootloaders
      [[ ${MOUNT} == "" ]] && BTRFS_MNT="rootflags=subvol="$BTRFS_MSUB_VOL
    done
    # change dir
    cd ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    btrfs subvolume create ${BTRFS_MSUB_VOL} 2>>/tmp/.errlog
    cd
    umount ${PARTITION} 2>>/tmp/.errlog
    check_for_error
    # Get any mount options and mount
    btrfs_mount_opts
    if [[ $(cat ${BTRFS_OPTS}) != "" ]]; then
      mount -o $(cat ${BTRFS_OPTS})",subvol="${BTRFS_MSUB_VOL} ${PARTITION} ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    else
      mount -o "subvol="${BTRFS_MSUB_VOL} ${PARTITION} ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    fi
    # Check for error and confirm successful mount
    check_for_error
    confirm_mount_btrfs ${MOUNTPOINT}${MOUNT}
    # Now change dir and create the subvolumes
    cd ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    check_for_error
    # Loop while the termination character has not been entered
    while [[ $BTRFS_OSUB_VOL != "*" ]]; do
      DIALOG --title "$_btrfsSVTitle ($BTRFS_MSUB_VOL) " --inputbox "$_btrfsSVBody1 $BTRFS_OSUB_NUM $_btrfsSVBody2 $BTRFS_MSUB_VOL.$_btrfsSVBody3 $(cat ${BTRFS_VOL_LIST})" 0 0 "" 2>${ANSWER} || select_filesystem
      BTRFS_OSUB_VOL=$(cat ${ANSWER})
      # Loop while subvolume is blank or has spaces.
      while [[ ${#BTRFS_OSUB_VOL} -eq 0 ]] || [[ $BTRFS_SUB_VOL =~ \ |\' ]]; do
        DIALOG --title "$_ErrTitle ($BTRFS_MSUB_VOL) " --inputbox "$_btrfsSVErrBody ($BTRFS_OSUB_NUM)." 0 0 "" 2>${ANSWER} || select_filesystem
        BTRFS_OSUB_VOL=$(cat ${ANSWER})
      done
      btrfs subvolume create ${BTRFS_OSUB_VOL} 2>/tmp/.errlog
      check_for_error
      BTRFS_OSUB_NUM=$(( BTRFS_OSUB_NUM + 1 ))
      echo $BTRFS_OSUB_VOL" " >> ${BTRFS_VOL_LIST}
    done
    # Show the subvolumes created
    echo -e "btrfs subvols:\n" > /tmp/.subvols
    ls  >> /tmp/.subvols
    DIALOG --textbox /tmp/.subvols 0 0
    cd
  }

  # This function allows for btrfs-specific mounting options to be applied. Written as a seperate function
  # for neatness.
  btrfs_mount_opts() {
    echo "" > ${BTRFS_OPTS}
    DIALOG --title "$_btrfsSVTitle" --checklist "$_btrfsMntBody" 0 0 16 \
    "autodefrag" "-" off \
    "compress=zlib" "-" off \
    "compress=lzo" "-" off \
    "compress=no" "-" off \
    "compress-force=zlib" "-" off \
    "compress-force=lzo" "-" off \
    "discard" "-" off \
    "noacl" "-" off \
    "noatime" "-" off \
    "nodatasum" "-" off \
    "nospace_cache" "-" off \
    "recovery" "-" off \
    "skip_balance" "-" off \
    "space_cache" "-" off \
    "ssd" "-" off \
    "ssd_spread" "-" off 2>${BTRFS_OPTS}
    # Now clean up the file
    sed -i 's/ /,/g' ${BTRFS_OPTS}
    sed -i '$s/,$//' ${BTRFS_OPTS}
    if [[ $(cat ${BTRFS_OPTS}) != "" ]]; then
      DIALOG --title "$_btrfsSVTitle" --yesno "$_btrfsMntConfBody $(cat $BTRFS_OPTS)\n" 0 0
      [[ $? -eq 1 ]] && btrfs_mount_opts
    fi
  }

  # Save repetition of code
  mount_current_partition(){
    # Make the mount directory
    mkdir -p ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    # If btrfs without subvolumes has been selected
    [[ $BTRFS -eq 1 ]] && btrfs_mount_opts
    # If btrfs & btrfs mount options. Otherwise, standard mount
    if [[ $BTRFS -eq 1 ]] && [[ $(cat ${BTRFS_OPTS}) != "" ]]; then
      mount -o $(cat ${BTRFS_OPTS}) ${PARTITION} ${MOUNTPOINT}${MOUNT} 2>>/tmp/.errlog
    else
      mount ${PARTITION} ${MOUNTPOINT}${MOUNT} 2>>/tmp/.errlog
    fi
    # Check for error, confirm mount, and deal with BTRFS with subvolumes if applicable
    check_for_error
    confirm_mount ${MOUNTPOINT}${MOUNT}
    # Deal with BTRFS with subvolumes if applicable
    [[ $BTRFS -eq 2 ]] && btrfs_subvols
  }

  # prep variable
  MOUNT=""
  # LVM Detection. If detected, activate.
  detect_lvm
  if [[ $LVM -eq 1 ]]; then
    DIALOG --title "$_PrepMntPart" --infobox "$_LvmDetBody2" 0 0
    sleep 2
    modprobe dm-mod 2>/tmp/.errlog
    check_for_error
    vgscan >/dev/null 2>&1
    vgchange -ay >/dev/null 2>&1
  fi
  # Ensure partitions are unmounted (i.e. where mounted previously), and then list available partitions
  umount_partitions
  find_partitions
  # Identify and mount root
  DIALOG --title "$_PrepMntPart" --menu "$_SelRootBody" 0 0 4 ${PARTITIONS} 2>${ANSWER} || prep_menu
  PARTITION=$(cat ${ANSWER})
  ROOT_PART=${PARTITION}
  # Identify if root is LVM
  [[ $(echo $ROOT_PART | grep "/dev/mapper/") == "" ]] && LVM_ROOT=0 || LVM_ROOT=1
  select_filesystem
  [[ $FILESYSTEM != $_FSSkip ]] && ${FILESYSTEM} ${PARTITION} >/dev/null 2>/tmp/.errlog
  check_for_error
  # Make the directory and mount
  mount_current_partition
  # Identify and create swap, if applicable
  DIALOG --title "$_PrepMntPart" --menu "$_SelSwpBody" 0 0 4 "$_SelSwpNone" $"-" "$_SelSwpFile" $"-" ${PARTITIONS} 2>${ANSWER} || prep_menu
  if [[ $(cat ${ANSWER}) != "$_SelSwpNone" ]]; then
    PARTITION=$(cat ${ANSWER})
    if [[ $PARTITION == "$_SelSwpFile" ]]; then
      total_memory=`grep MemTotal /proc/meminfo | awk '{print $2/1024}' | sed 's/\..*//'`
      fallocate -l ${total_memory}M ${MOUNTPOINT}/swapfile >/dev/null 2>/tmp/.errlog
      check_for_error
      chmod 600 ${MOUNTPOINT}/swapfile >/dev/null 2>&1
      mkswap ${MOUNTPOINT}/swapfile >/dev/null 2>&1
      swapon ${MOUNTPOINT}/swapfile >/dev/null 2>&1
    else
      # Only create a swap if not already in place
      [[ $(lsblk -o FSTYPE  ${PARTITION} | grep -i "swap") != "swap" ]] &&  mkswap ${PARTITION} >/dev/null 2>/tmp/.errlog
      swapon  ${PARTITION} >/dev/null 2>>/tmp/.errlog
      check_for_error
      # Since a partition was used, remove that partition from the list
      PARTITIONS=$(echo $PARTITIONS | sed "s~${PARTITION} [0-9]*[G-M]~~" | sed "s~${PARTITION} [0-9]*\.[0-9]*[G-M]~~" | sed s~${PARTITION}$' -'~~)
      NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS - 1 ))
    fi
  fi
  # Extra Step for VFAT UEFI Partition. This cannot be in an LVM container.
  if [[ $SYSTEM == "UEFI" ]]; then
    DIALOG --title "$_PrepMntPart" --menu "$_SelUefiBody" 0 0 4 ${PARTITIONS} 2>${ANSWER} || config_base_menu
    PARTITION=$(cat ${ANSWER})
    UEFI_PART=${PARTITION}
    # If it is already a fat/vfat partition...
    if [[ $(fsck -N /dev/$PARTITION | grep fat) ]]; then
      DIALOG --title "$_PrepMntPart" --yesno "$_FormUefiBody $PARTITION $_FormUefiBody2" 0 0 && mkfs.vfat -F32 ${PARTITION} >/dev/null 2>/tmp/.errlog
    else
      mkfs.vfat -F32 ${PARTITION} >/dev/null 2>/tmp/.errlog
    fi
    check_for_error
    # Inform users of the mountpoint options and consequences
    DIALOG --title "$_PrepMntPart" --menu "$_MntUefiBody"  0 0 2 \
    "/boot" "systemd-boot"\
    "/boot/efi" "refind-efi" 2>${ANSWER}
    [[ $(cat ${ANSWER}) != "" ]] && UEFI_MOUNT=$(cat ${ANSWER}) || config_base_menu
    mkdir -p ${MOUNTPOINT}${UEFI_MOUNT} 2>/tmp/.errlog
    mount ${PARTITION} ${MOUNTPOINT}${UEFI_MOUNT} 2>>/tmp/.errlog
    check_for_error
    confirm_mount ${MOUNTPOINT}${UEFI_MOUNT}
  fi
  # All other partitions
  while [[ $NUMBER_PARTITIONS > 0 ]]; do
    DIALOG --title "$_PrepMntPart" --menu "$_ExtPartBody" 0 0 4 \
    "$_Done" $"-" ${PARTITIONS} 2>${ANSWER} || config_base_menu
    PARTITION=$(cat ${ANSWER})
    if [[ $PARTITION == $_Done ]]; then
      break;
    else
      MOUNT=""
      select_filesystem
      [[ $FILESYSTEM != $_FSSkip ]] && ${FILESYSTEM} ${PARTITION} >/dev/null 2>/tmp/.errlog
      check_for_error
      MOUNT=$(cat ${ANSWER})
      # loop while the mountpoint specified is incorrect (is only '/', is blank, or has spaces).
      while [[ ${MOUNT:0:1} != "/" ]] || [[ ${#MOUNT} -le 1 ]] || [[ $MOUNT =~ \ |\' ]]; do
        # Warn user about naming convention
        DIALOG --title "$_ErrTitle" --msgbox "$_ExtErrBody" 0 0
        # Ask user for mountpoint again
        DIALOG --title "$_PrepMntPart $PARTITON " --inputbox "$_ExtPartBody1$MNT_EXAMPLES\n" 0 0 "/" 2>${ANSWER} || config_base_menu
        MOUNT=$(cat ${ANSWER})
      done
      # Create directory and mount.
      mount_current_partition
      # Determine if a seperate /boot is used. Necessary LVM-realted bootloader configuration
      LVM_SEP_BOOT=0
      [[ $MOUNT == "/boot" ]] && LVM_SEP_BOOT=1 || LVM_SEP_BOOT=2
    fi
  done
}

################################################################################
##
## Logical Volume Management Functions
##
################################################################################

# LVM Detection.
detect_lvm() {
  LVM_PV=$(pvs -o pv_name --noheading 2>/dev/null)
  LVM_VG=$(vgs -o vg_name --noheading 2>/dev/null)
  LVM_LV=$(lvs -o vg_name,lv_name --noheading --separator - 2>/dev/null)
  if [[ $LVM_LV = "" ]] && [[ $LVM_VG = "" ]] && [[ $LVM_PV = "" ]]; then
    LVM=0
  else
    LVM=1
  fi
}

# Where existing LVM is found, offer to deactivate it. Code adapted from the Manjaro installer.
# NEED TO ADD COMMAND TO REMOVE LVM2 FSTYPE.
deactivate_lvm() {
  LVM_DISABLE=0
  if [[ $LVM -eq 1 ]]; then
    DIALOG --title "$_LvmDetTitle" --yesno "$_LvmDetBody1" 0 0 \
    && LVM_DISABLE=1 || LVM_DISABLE=0
  fi
  if [[ $LVM_DISABLE -eq 1 ]]; then
    DIALOG --title "$_LvmRmTitle" --infobox "$_LvmRmBody" 0 0
    sleep 2
    for i in ${LVM_LV}; do
      lvremove -f /dev/mapper/${i} >/dev/null 2>&1
    done
    for i in ${LVM_VG}; do
      vgremove -f ${i} >/dev/null 2>&1
    done
    for i in ${LV_PV}; do
      pvremove -f ${i} >/dev/null 2>&1
    done
    # This step will remove old lvm metadata on partitions where identified.
    LVM_PT=$(lvmdiskscan | grep 'LVM physical volume' | grep 'sd\|hd\|vd\|nvme\|mmc' | sed 's/\/dev\///' | awk '{print $1}')
    for i in ${LVM_PT}; do
      dd if=/dev/zero bs=512 count=512 of=/dev/${i} >/dev/null 2>&1
    done
  fi
}

# Find and create a list of partitions that can be used for LVM. Partitions already used are excluded.
find_lvm_partitions() {
  LVM_PARTITIONS=""
  NUMBER_LVM_PARTITIONS=0
  lvm_partition_list=$(lsblk -lno NAME,SIZE,TYPE | grep 'part\|crypt' | awk '{print $1 " " $2}' | sort -u)
  for i in ${lvm_partition_list[@]}; do
    LVM_PARTITIONS="${LVM_PARTITIONS} ${i}"
    NUMBER_LVM_PARTITIONS=$(( NUMBER_LVM_PARTITIONS + 1 ))
  done
}

# This simplifies the creation of the PV and VG into a single step.
create_lvm() {

  # subroutine to save a lot of repetition.
  check_lv_size() {
    LV_SIZE_INVALID=0
    LV_SIZE_TYPE=$(echo ${LVM_LV_SIZE:$(( ${#LVM_LV_SIZE} - 1 )):1})
    chars=0
    # Check to see if anything was actually entered
    [[ ${#LVM_LV_SIZE} -eq 0 ]] && LV_SIZE_INVALID=1
    # Check if there are any non-numeric characters prior to the last one
    while [[ $chars -lt $(( ${#LVM_LV_SIZE} - 1 )) ]]; do
      if [[ ${LVM_LV_SIZE:chars:1} != [0-9] ]]; then
        LV_SIZE_INVALID=1
        break;
      fi
      chars=$(( chars + 1 ))
    done
    # Check to see if first character is '0'
    [[ ${LVM_LV_SIZE:0:1} -eq "0" ]] && LV_SIZE_INVALID=1
    # Check to see if last character is "G" or "M", and if so, whether the value is greater than
    # or equal to the LV remaining Size. If not, convert into MB for VG space remaining.
    if [[ ${LV_SIZE_INVALID} -eq 0 ]]; then
      case ${LV_SIZE_TYPE} in
        "G")
        if [[ $(( $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) * 1000 )) -ge ${LVM_VG_MB} ]]; then
          LV_SIZE_INVALID=1
        else
          LVM_VG_MB=$(( LVM_VG_MB - $(( $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) * 1000 )) ))
        fi
        ;;
        "M")
        if [[ $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) -ge ${LVM_VG_MB} ]]; then
          LV_SIZE_INVALID=1
        else
          LVM_VG_MB=$(( LVM_VG_MB - $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) ))
        fi
        ;;
        *)
        LV_SIZE_INVALID=1
        ;;
      esac
    fi
  }

  # Check that there is at least one partition available for LVM
  if [[ $NUMBER_LVM_PARTITIONS -lt 1 ]]; then
    DIALOG --title "$_LvmPartErrTitle" --msgbox "$_LvmPartErrBody" 0 0
    prep_menu
  fi
  # Create a temporary file to store the partition(s) selected. This is later used for the vgcreate command. 'x' is used as a marker.
  echo "x" > /tmp/.vgcreate
  # Name the Volume Group
  LVM_VG=""
  DIALOG --title "$_LvmNameVgTitle" --inputbox "$_LvmNameVgBody" 0 0 "" 2>${ANSWER} || prep_menu
  LVM_VG=$(cat ${ANSWER})
  # Loop while the Volume Group name starts with a "/", is blank, has spaces, or is already being used
  while [[ ${LVM_VG:0:1} == "/" ]] || [[ ${#LVM_VG} -eq 0 ]] || [[ $LVM_VG =~ \ |\' ]] || [[ $(lsblk | grep ${LVM_VG}) != "" ]]; do
    DIALOG --title "$_LvmNameVgErrTitle" --msgbox "$_LvmNameVgErr" 0 0

    DIALOG --title "$_LvmNameVgTitle" --inputbox "$_LvmNameVgBody" 0 0 "" 2>${ANSWER} || prep_menu
    LVM_VG=$(cat ${ANSWER})
  done
  # Select the first or only partition for the Volume Group
  DIALOG --title "$_LvmPvSelTitle" --menu "$_LvmPvSelBody" 0 0 4 ${LVM_PARTITIONS} 2>${ANSWER} || prep_menu
  LVM_PARTITION=$(cat ${ANSWER})
  # add the partition to the temporary file for the vgcreate command
  # Remove selected partition from the list and deduct number of LVM viable partitions remaining
  # FIX TO INCLUDE PARTITION SIZES
  sed -i "s/x/\/dev\/${LVM_PARTITION} x/" /tmp/.vgcreate
  LVM_PARTITIONS="$(echo $LVM_PARTITIONS | sed s/${LVM_PARTITION}$' -'//)"
  NUMBER_LVM_PARTITIONS=$(( NUMBER_LVM_PARTITIONS - 1 ))
  DIALOG --title "$_LvmPvCreateTitle" --infobox "\n$_Done\n\n" 0 0
  sleep 1
  # Where there are viable partitions still remaining, run loop
  while [[ $NUMBER_LVM_PARTITIONS -gt 0 ]]; do
    DIALOG --title "$_LvmPvSelTitle" --menu "$_LvmPvSelBody" 0 0 4 $"Done" $"-" ${LVM_PARTITIONS} 2>${ANSWER} || prep_menu
    LVM_PARTITION=$(cat ${ANSWER})
    if [[ $LVM_PARTITION == "Done" ]]; then
      break;
    else
      sed -i "s/x/\/dev\/${LVM_PARTITION} x/" /tmp/.vgcreate
      LVM_PARTITIONS="$(echo $LVM_PARTITIONS | sed s/${LVM_PARTITION}$' -'//)"
      NUMBER_LVM_PARTITIONS=$(( NUMBER_LVM_PARTITIONS - 1 ))
      DIALOG --title "$_LvmPvCreateTitle" --infobox "\n$_Done\n\n" 0 0
      sleep 1
    fi
  done
  # Once all the partitions have been selected, remove 'x' from the .vgcreate file, then use it in 'vgcreate' command.
  # Also determine the size of the VG, to use for creating LVs for it.
  VG_PARTS=$(cat /tmp/.vgcreate | sed 's/x//')
  DIALOG --title "$_LvmPvConfTitle" --yesno "$_LvmPvConfBody1${LVM_VG} $_LvmPvConfBody2${VG_PARTS}" 0 0
  if [[ $? -eq 0 ]]; then
    DIALOG --title "$_LvmPvActTitle" --infobox "$_LvmPvActBody1${LVM_VG}.$_LvmPvActBody2" 0 0
    sleep 2
    vgcreate -f ${LVM_VG} ${VG_PARTS} >/dev/null 2>/tmp/.errlog
    check_for_error
    VG_SIZE=$(vgdisplay | grep 'VG Size' | awk '{print $3}' | sed 's/\..*//')
    VG_SIZE_TYPE=$(vgdisplay | grep 'VG Size' | awk '{print $4}' | sed 's/\..*//')
    DIALOG --title "$_LvmPvDoneTitle" --msgbox "$_LvmPvDoneBody1 '${LVM_VG}' $_LvmPvDoneBody2 (${VG_SIZE} ${VG_SIZE_TYPE}).\n\n" 0 0
    sleep 2
  else
    prep_menu
  fi
  # Convert the VG size into GB and MB. These variables are used to keep tabs on space available and remaining
  [[ ${VG_SIZE_TYPE:0:1} == "G" ]] && LVM_VG_MB=$(( VG_SIZE * 1000 )) || LVM_VG_MB=$VG_SIZE
  # Specify number of Logical volumes to create.
  DIALOG --title "$_LvmLvNumTitle" --inputbox "$_LvmLvNumBody1 ${LVM_VG}.$_LvmLvNumBody2" 0 0 "" 2>${ANSWER} || prep_menu
  NUMBER_LOGICAL_VOLUMES=$(cat ${ANSWER})
  # Loop if the number of LVs is no 1-9 (including non-valid characters)
  while [[ $NUMBER_LOGICAL_VOLUMES != [1-9] ]]; do
    DIALOG --title "$_LvmLvNumErrTitle" --msgbox "$_LvmLvNumErrBody" 0 0
    DIALOG --title "$_LvmLvNumTitle" --inputbox "$_LvmLvNumBody1 ${LVM_VG}.$_LvmLvNumBody2" 0 0 "" 2>${ANSWER} || prep_menu
    NUMBER_LOGICAL_VOLUMES=$(cat ${ANSWER})
  done
  # Loop while the number of LVs is greater than 1. This is because the size of the last LV is automatic.
  while [[ $NUMBER_LOGICAL_VOLUMES -gt 1 ]]; do
    DIALOG --title "$_LvmLvNameTitle" --inputbox "$_LvmLvNameBody1" 0 0 "lvol" 2>${ANSWER} || prep_menu
    LVM_LV_NAME=$(cat ${ANSWER})
    # Loop if preceeded with a "/", if nothing is entered, if there is a space, or if that name already exists.
    while [[ ${LVM_LV_NAME:0:1} == "/" ]] || [[ ${#LVM_LV_NAME} -eq 0 ]] || [[ ${LVM_LV_NAME} =~ \ |\' ]] || [[ $(lsblk | grep ${LVM_LV_NAME}) != "" ]]; do
      DIALOG --title "$_LvmLvNameErrTitle" --msgbox "$_LvmLvNameErrBody" 0 0
      DIALOG --title "$_LvmLvNameTitle" --inputbox "$_LvmLvNameBody1" 0 0 "lvol" 2>${ANSWER} || prep_menu
      LVM_LV_NAME=$(cat ${ANSWER})
    done
    DIALOG --title "$_LvmLvSizeTitle" --inputbox "\n${LVM_VG}: ${VG_SIZE}${VG_SIZE_TYPE} (${LVM_VG_MB}MB $_LvmLvSizeBody1).$_LvmLvSizeBody2" 0 0 "" 2>${ANSWER} || prep_menu
    LVM_LV_SIZE=$(cat ${ANSWER})
    check_lv_size
    # Loop while an invalid value is entered.
    while [[ $LV_SIZE_INVALID -eq 1 ]]; do
      DIALOG --title "$_LvmLvSizeErrTitle" --msgbox "$_LvmLvSizeErrBody" 0 0
      DIALOG --title "$_LvmLvSizeTitle" --inputbox "\n${LVM_VG}: ${VG_SIZE}${VG_SIZE_TYPE} (${LVM_VG_MB}MB $_LvmLvSizeBody1).$_LvmLvSizeBody2" 0 0 "" 2>${ANSWER} || prep_menu
      LVM_LV_SIZE=$(cat ${ANSWER})
      check_lv_size
    done
    # Create the LV
    lvcreate -L ${LVM_LV_SIZE} ${LVM_VG} -n ${LVM_LV_NAME} 2>/tmp/.errlog
    check_for_error
    DIALOG --title "$_LvmLvDoneTitle" --msgbox "\n$_Done\n\nLV ${LVM_LV_NAME} (${LVM_LV_SIZE}) $_LvmPvDoneBody2.\n\n" 0 0
    NUMBER_LOGICAL_VOLUMES=$(( NUMBER_LOGICAL_VOLUMES - 1 ))
  done
  # Now the final LV. Size is automatic.
  DIALOG --title "$_LvmLvNameTitle" --inputbox "$_LvmLvNameBody1 $_LvmLvNameBody2 (${LVM_VG_MB}MB)." 0 0 "lvol" 2>${ANSWER} || prep_menu
  LVM_LV_NAME=$(cat ${ANSWER})
  # Loop if preceeded with a "/", if nothing is entered, if there is a space, or if that name already exists.
  while [[ ${LVM_LV_NAME:0:1} == "/" ]] || [[ ${#LVM_LV_NAME} -eq 0 ]] || [[ ${LVM_LV_NAME} =~ \ |\' ]] || [[ $(lsblk | grep ${LVM_LV_NAME}) != "" ]]; do
    DIALOG --title "$_LvmLvNameErrTitle" --msgbox "$_LvmLvNameErrBody" 0 0
    DIALOG --title "$_LvmLvNameTitle" --inputbox "$_LvmLvNameBody1 $_LvmLvNameBody2 (${LVM_VG_MB}MB)." 0 0 "lvol" 2>${ANSWER} || prep_menu
    LVM_LV_NAME=$(cat ${ANSWER})
  done
  # Create the final LV
  lvcreate -l +100%FREE ${LVM_VG} -n ${LVM_LV_NAME} 2>/tmp/.errlog
  check_for_error
  NUMBER_LVM_PARTITIONS=$(( NUMBER_LVM_PARTITIONS - 1 ))
  DIALOG --title "$_LvmCompTitle" --yesno "$_LvmCompBody" 0 0 \
  && show_devices || prep_menu
}

################################################################################
##
## Installation Functions
##
################################################################################

# The linux kernel package will be removed from the base group as it and/or the lts version will be
# selected by the user. Two installation methods are available: Standard (group package based) and
# Advanced (individual package based). Neither will allow progress without selecting a kernel.
install_base() {
  # Prep variables
  echo "" > ${PACKAGES}
  echo "" > ${ANSWER}
  BTRF_CHECK=""
  F2FS_CHECK=""
  BASE_LIST=""
  # Need a seperate base-devel package list as there are so many duplicates with the base group.
  base_list=$(echo $(pacman -Sqg base) | sed s/" linux "/" "/ | sort -u)
  BASE_DEV_LIST=$(echo "autoconf automake binutils bison fakeroot flex gcc groff libtool m4 make patch pkg-config sudo" \
  | sed s/" "/" base-devel on "/g | sed s/$/" base-devel on "/g)
  for i in ${base_list}; do
    BASE_LIST="${BASE_LIST} ${i} base on"
  done
  # If btrfs and/or f2fs was used, auto-select the necessary packages for installation
  [[ $BTRFS -gt 0 ]] && BTRF_CHECK=$(echo "btrfs-progs" "-" on) || BTRF_CHECK=$(echo "btrfs-progs" "-" off)
  [[ $F2FS -gt 0 ]] && F2FS_CHECK=$(echo "f2fs-tools" "-" on) || F2FS_CHECK=$(echo "f2fs-tools" "-" off)
  # User to select "standard" or "advanced" installation Method
  DIALOG --title "$_InstBseTitle" --menu "$_InstBseBody" 0 0 2 \
  "1" "$_InstStandBase" \
  "2" "$_InstAdvBase" 2>${ANSWER}
  # "Standard" installation method
  if [[ $(cat ${ANSWER}) -eq 1 ]]; then
    DIALOG --title "$_InstBseTitle" --checklist "$_InstStandBseBody$_UseSpaceBar" 0 0 6 \
    "linux" "-" on "linux-lts" "-" off "base-devel" "-" on $BTRF_CHECK $F2FS_CHECK "sudo" "-" on 2>${PACKAGES}
  elif [[ $(cat ${ANSWER}) -eq 2 ]]; then
    # "Advanced" installation method
    DIALOG --title "$_InstBseTitle" --checklist "$_InstAdvBseBody $_UseSpaceBar" 0 0 0 \
    "linux" "base" on "linux-lts" "core" off $BASE_LIST $BASE_DEV_LIST $BTRF_CHECK $F2FS_CHECK 2>${PACKAGES}
  fi
  # Determine kernel type(s) selected for installation.
  if 	[[ $(cat ${PACKAGES}) != "" ]]; then
    [[ $(cat ${PACKAGES} | grep \^linux$" ") != "" ]] && [[ $(cat ${PACKAGES} | grep "linux-lts") != "" ]] && KERNEL=3
    [[ $(cat ${PACKAGES} | grep \^linux$" ") == "" ]] && [[ $(cat ${PACKAGES} | grep "linux-lts") != "" ]] && KERNEL=2
    [[ $(cat ${PACKAGES} | grep \^linux$" ") != "" ]] && [[ $(cat ${PACKAGES} | grep "linux-lts") == "" ]] && KERNEL=1
    [[ $(cat ${PACKAGES} | grep \^linux$" ") == "" ]] && [[ $(cat ${PACKAGES} | grep "linux-lts") == "" ]] && KERNEL=0
    if [[ $KERNEL -gt 0 ]]; then
      [[ $(cat ${ANSWER}) -eq 1 ]] && PACSTRAP $(pacman -Sqg base | sed 's/linux//' | sed 's/util-/util-linux/') $(cat ${PACKAGES}) 2>/tmp/.errlog
      [[ $(cat ${ANSWER}) -eq 2 ]] && PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
      # If the virtual console has been set, then copy config file to installation
      [[ -e /tmp/vconsole.conf ]] && cp /tmp/vconsole.conf ${MOUNTPOINT}/etc/vconsole.conf 2>/tmp/.errlog
      check_for_error
    else
      DIALOG --title "$_ErrTitle" --msgbox "$_ErrNoKernel" 0 0
      install_base
    fi
  fi
}

# Install an AUR helper for managing AUR packages
install_aur() {
  local archfrrepo="[archlinuxfr]
  SigLevel = Never
  Server = http:/:repo.archlinux.fr/\$arch"
  if [[ $BASE_DEVEL -eq 0 ]] ; then
    DIALOG --title "$_NeedBaseDevelTitle" \
    --yesno "$_NeedBaseDevelBody" 0 0
    if [[ $? == 0 ]]; then
      PACSTRAP base-devel
      [[ $? -eq 0 ]] && BASE_DEVEL=1
      check_for_error
    else
      install_base_menu
    fi
  fi
  DIALOG --title "$_InstAurTitle" \
  --menu "$_InstAurBody" 0 0 10 \
  "1" "Yaourt" \
  "99" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    clear
    arch_chroot "echo ${archfrrepo} >> /etc/pacman.conf" 2>/tmp/.errlog
    arch_chroot "pacman -Syy" 2>>/tmp/.errlog
    check_for_error
    PACSTRAP yaourt
    ;;
    *)
    install_base_menu
    ;;
  esac
  check_for_error
}

install_bootloader() {

  # Grub auto-detects installed kernels, etc. Syslinux does not, hence the extra code for it.
  bios_bootloader() {
    DIALOG --title "$_InstBiosBtTitle" --menu "$_InstBiosBtBody" 0 0 3 \
    "grub" "-" \
    "grub + os-prober" "-" \
    "syslinux" "-" 2>${PACKAGES}
    # If something has been selected, act
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      sed -i 's/+\|\"//g' ${PACKAGES}
      PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
      # If Grub, select device
      if [[ $(cat ${PACKAGES} | grep "grub") != "" ]]; then
        select_device
        # If a device has been selected, configure
        if [[ $DEVICE != "" ]]; then
          clear
          arch_chroot "grub-install --target=i386-pc --debug --recheck $DEVICE" 2>/tmp/.errlog
          arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>>/tmp/.errlog
          check_for_error
          # if /boot is LVM then amend /boot/grub/grub.cfg accordingly
          if ( [[ $LVM_ROOT -eq 1 ]] && [[ $LVM_SEP_BOOT -eq 0 ]] ) || [[ $LVM_SEP_BOOT -eq 2 ]]; then
            sed -i '/### BEGIN \/etc\/grub.d\/00_header ###/a insmod lvm' ${MOUNTPOINT}/boot/grub/grub.cfg
          fi
        fi
      else
        # Syslinux
        DIALOG --title "$_InstSysTitle" --menu "$_InstSysBody" 0 0 2 \
        "syslinux-install_update -iam" "[MBR]" \
        "syslinux-install_update -i" "[/]" 2>${PACKAGES}
        # If an installation method has been chosen, run it
        if [[ $(cat ${PACKAGES}) != "" ]]; then
          arch_chroot "$(cat ${PACKAGES})" 2>/tmp/.errlog
          check_for_error
          # Amend configuration file to specify root.
          sed -i "s~APPEND.*~APPEND root=${ROOT_PART} rw~g" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
          # Amend configuration file for kernel(s) installed
          if [[ $KERNEL -eq 3 ]]; then
            sed -i "/INITRD \.\.\/initramfs-linux\.img/a--insert--\nLABEL arch-lts\n\tMENU LABEL Arch Linux LTS\n\tLINUX \.\.\/vmlinuz-linux-lts\n\tAPPEND root=$ROOT_PART rw\n\tINITRD \.\./initramfs-linux-lts\.img" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
            sed -i "/INITRD \.\.\/initramfs-linux-fallback\.img/a--insert--\nLABEL archfallback-lts\n\tMENU LABEL Arch Linux Fallback LTS\n\tLINUX \.\.\/vmlinuz-linux-lts\n\tAPPEND root=$ROOT_PART rw\n\tINITRD \.\./initramfs-linux-fallback-lts\.img" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
            sed -i s/--insert--//g ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
          elif [[ $KERNEL -eq 2 ]]; then
            sed -i 's/linux/linux-lts/g' ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
          fi
          # If BTRFS Subvolume mount
          [[ $BTRFS_MNT != "" ]] && sed -i "s/rw/rw $BTRFS_MNT/g" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        fi
      fi
    fi
  }

  uefi_bootloader() {
    #Ensure again that efivarfs is mounted
    [[ -z $(mount | grep /sys/firmware/efi/efivars) ]] && mount -t efivarfs efivarfs /sys/firmware/efi/efivars
    DIALOG --title "$_InstUefiBtTitle" \
    --menu "$_InstUefiBtBody" 0 0 3 \
    "grub" "-" \
    "refind-efi" "-" \
    "[systemd-boot]" "-" 2>${PACKAGES}
    case $(cat ${ANSWER}) in
      "1")
      # Grub2
      PACSTRAP grub os-prober efibootmgr dosfstools
      check_for_error
      DIALOG --title " Grub-install " --infobox "$_PlsWaitBody" 0 0
      sleep 1
      arch_chroot "grub-install --target=x86_64-efi --efi-directory=${UEFI_MOUNT} --bootloader-id=arch_grub --recheck" 2>/tmp/.errlog
      arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>>/tmp/.errlog
      check_for_error
      # Ask if user wishes to set Grub as the default bootloader and act accordingly
      DIALOG --title "$_SetGrubDefTitle" --yesno "$_SetGrubDefBody ${UEFI_MOUNT}/EFI/boot $_SetGrubDefBody2" 0 0
      if [[ $? -eq 0 ]]; then
        arch_chroot "mkdir ${UEFI_MOUNT}/EFI/boot" 2>/tmp/.errlog
        arch_chroot "cp -r ${UEFI_MOUNT}/EFI/arch_grub/grubx64.efi ${UEFI_MOUNT}/EFI/boot/bootx64.efi" 2>>/tmp/.errlog
        check_for_error
        DIALOG --title "$_SetDefDoneTitle" --infobox "\nGrub $_SetDefDoneBody" 0 0
        sleep 2
      fi
      BOOTLOADER="Grub"
      ;;
      "2")
      # rEFInd
      # Ensure that UEFI partition has been mounted to /boot/efi due to bug in script. Could "fix" it for installation, but
      # This could result in unknown consequences should the script be updated at some point.
      if [[ $UEFI_MOUNT == "/boot/efi" ]]; then
        PACSTRAP refind-efi efibootmgr dosfstools
        check_for_error
        DIALOG --title "$_SetRefiDefTitle" --yesno "$_SetRefiDefBody ${UEFI_MOUNT}/EFI/boot $_SetRefiDefBody2" 0 0
        if [[ $? -eq 0 ]]; then
          clear
          arch_chroot "refind-install --usedefault ${UEFI_PART} --alldrivers" 2>/tmp/.errlog
        else
          clear
          arch_chroot "refind-install" 2>/tmp/.errlog
        fi
        check_for_error
        # Now generate config file to pass kernel parameters. Default read only (ro) changed to read-write (rw),
        # and amend where using btfs subvol root
        arch_chroot "refind-mkrlconf" 2>/tmp/.errlog
        check_for_error
        sed -i 's/ro /rw /g' ${MOUNTPOINT}/boot/refind_linux.conf
        [[ $BTRFS_MNT != "" ]] && sed -i "s/rw/rw $BTRFS_MNT/g" ${MOUNTPOINT}/boot/refind_linux.conf
        BOOTLOADER="rEFInd"
      else
        DIALOG --title "$_RefiErrTitle" --msgbox "$_RefiErrBody" 0 0
        uefi_bootloader
      fi
      ;;
      "3")
      # systemd-boot
      PACSTRAP efibootmgr dosfstools
      arch_chroot "bootctl --path=${UEFI_MOUNT} install" 2>>/tmp/.errlog
      check_for_error
      # Deal with LVM Root
      if [[ $(echo $ROOT_PART | grep "/dev/mapper/") == "" ]]; then
        sysdb_root=$(blkid -s PARTUUID ${ROOT_PART} | sed 's/.*=//g' | sed 's/"//g')
      else
        sysdb_root=$ROOT_PAR
      fi
      # Deal with LTS Kernel
      if [[ $LTS -eq 1 ]]; then
        echo -e "title\tArch Linux\nlinux\t/vmlinuz-linux-lts\ninitrd\t/initramfs-linux-lts.img\noptions\troot=PARTUUID=${sysdb_root} rw" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/arch.conf
      else
        echo -e "title\tArch Linux\nlinux\t/vmlinuz-linux\ninitrd\t/initramfs-linux.img\noptions\troot=PARTUUID=${sysdb_root} rw" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/arch.conf
      fi
      # Fix LVM Root installations, and deal with btrfs root subvolume mounting
      [[ $LVM_ROOT -eq 1 ]] && sed -i "s/PARTUUID=//g" ${MOUNTPOINT}/boot/loader/entries/arch.conf
      [[ $BTRFS_MNT != "" ]] && sed -i "s/rw/rw $BTRFS_MNT/g" ${MOUNTPOINT}/boot/loader/entries/arch.conf
      BOOTLOADER="systemd-boot"
      # Set the loader file
      echo -e "default  arch\ntimeout  5" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/loader.conf 2>/tmp/.errlog
      check_for_error
      ;;
      *)
      install_base_menu
      ;;
    esac
  }

  check_mount
  # Set the default PATH variable
  arch_chroot "PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/core_perl" 2>/tmp/.errlog
  check_for_error
  if [[ $SYSTEM == "BIOS" ]]; then
    bios_bootloader
  else
    uefi_bootloader
  fi
}

#
install_network_menu() {

  # ntp not exactly wireless, but this menu is the best fit.
  install_wireless_packages(){
    WIRELESS_PACKAGES="dialog iw rp-pppoe wireless_tools wpa_actiond"
    if [[ $(lspci | grep -i "Network Controller") != "" ]]; then
      WIRELESS_PACKAGES=$(echo $WIRELESS_PACKAGES | sed s/" "/" wifi on "/g | sed s/$/" wifi on "/g)
    else
      WIRELESS_PACKAGES=$(echo $WIRELESS_PACKAGES | sed s/" "/" wifi off "/g | sed s/$/" wifi off "/g)
    fi
    DIALOG --title " $_InstNMMenuPkg " --checklist "$_InstNMMenuPkgBody\n\n$_UseSpaceBar" 0 0 11 \
    $WIRELESS_PACKAGES \
    "ntp" "-" off \
    "b43-fwcutter" "Broadcom 802.11b/g/n" off \
    "bluez-firmware" "Broadcom BCM203x / STLC2300 Bluetooth" off \
    "ipw2100-fw" "Intel PRO/Wireless 2100" off \
    "ipw2200-fw" "Intel PRO/Wireless 2200" off \
    "zd1211-firmware" "ZyDAS ZD1211(b) 802.11a/b/g USB WLAN" off 2>${PACKAGES}
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
    fi
  }

  install_cups(){
    DIALOG --title " $_InstNMMenuCups " --checklist "$_InstCupsBody\n\n$_UseSpaceBar" 0 0 11 \
    "cups" "-" on \
    "cups-pdf" "-" off \
    "ghostscript" "-" on \
    "gsfonts" "-" on \
    "samba" "-" off 2>${PACKAGES}
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
      if [[ $(cat ${PACKAGES} | grep "cups") != "" ]]; then
        DIALOG --title " $_InstNMMenuCups " --yesno "$_InstCupsQ" 0 0
        if [[ $? -eq 0 ]]; then
          arch_chroot "systemctl enable org.cups.cupsd.service" 2>/tmp/.errlog
          check_for_error
          DIALOG --infobox "$_Done!" 0 0
          sleep 2
        fi
      fi
    fi
  }

  if [[ $SUB_MENU != "install_network_packages" ]]; then
    SUB_MENU="install_network_packages"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 5 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title " $_InstNMMenuTitle " --menu "$_InstNMMenuBody" 0 0 5 \
  "1" "$_SeeWirelessDev" \
  "2" "$_InstNMMenuPkg" \
  "3" "$_InstNMMenuNM" \
  "4" "$_InstNMMenuCups" \
  "5" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    # Identify the Wireless Device
    lspci -k | grep -i -A 2 "network controller" > /tmp/.wireless
    if [[ $(cat /tmp/.wireless) != "" ]]; then
      DIALOG --title "$_WirelessShowTitle" --textbox /tmp/.wireless 0 0
    else
      DIALOG --title "$_WirelessShowTitle" --msgbox "$_WirelessErrBody" 7 30
    fi
    ;;
    "2")
    install_wireless_packages
    ;;
    "3")
    install_nm
    ;;
    "4")
    install_cups
    ;;
    *)
    main_menu_online
    ;;
  esac
}

# Install alsa, xorg and input drivers. Also copy the xkbmap configuration file created earlier to the installed system
# This will run only once.
install_xorg_input() {
  echo "" > ${PACKAGES}
  DIALOG --title "$_AXITitle" --checklist "$_AXIBody$_UseSpaceBar" 0 0 11 \
  "wayland" "-" off \
  "xorg-server" "-" on \
  "xorg-server-common" "-" off \
  "xorg-server-utils" "-" on \
  "xorg-xinit" "-" on \
  "xorg-server-xwayland" "-" off \
  "xf86-input-evdev" "-" off \
  "xf86-input-joystick" "-" off \
  "xf86-input-keyboard" "-" on \
  "xf86-input-mouse" "-" on \
  "xf86-input-synaptics" "-" on 2>${PACKAGES}
  # If at least one package, install.
  if [[ $(cat ${PACKAGES}) != "" ]]; then
    PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
    check_for_error
  fi
  # copy the keyboard configuration file, if generated
  [[ -e /tmp/00-keyboard.conf ]] && cp /tmp/00-keyboard.conf ${MOUNTPOINT}/etc/X11/xorg.conf.d/00-keyboard.conf
  # now copy across .xinitrc for all user accounts
  user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
  for i in ${user_list[@]}; do
    cp -f ${MOUNTPOINT}/etc/X11/xinit/xinitrc ${MOUNTPOINT}/home/$i
    arch_chroot "chown -R ${i}:users /home/${i}"
  done
}

setup_graphics_card() {

  # Save repetition
  install_intel(){
    PACSTRAP xf86-video-intel libva-intel-driver intel-ucode
    sed -i 's/MODULES=""/MODULES="i915"/' ${MOUNTPOINT}/etc/mkinitcpio.conf
    # Intel microcode (Grub, Syslinux and systemd-boot). rEFInd is yet to be added.
    # Done as seperate if statements in case of multiple bootloaders.
    if [[ -e ${MOUNTPOINT}/boot/grub/grub.cfg ]]; then
      DIALOG --title " grub-mkconfig " --infobox "$_PlsWaitBody" 0 0
      sleep 1
      arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>>/tmp/.errlog
    fi
    if [[ -e ${MOUNTPOINT}/boot/syslinux/syslinux.cfg ]]; then
      sed -i 's/..\/initramfs-linux.img/..\/intel-ucode.img,..\/initramfs-linux.img/g' ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
      sed -i 's/..\/initramfs-linux-lts.img/..\/intel-ucode.img,..\/initramfs-linux-lts.img/g' ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
      sed -i 's/..\/initramfs-linux-fallback.img/..\/intel-ucode.img,..\/initramfs-linux-fallback.img/g' ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
      sed -i 's/..\/initramfs-linux-lts-fallback.img/..\/intel-ucode.img,..\/initramfs-linux-lts-fallback.img/g' ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
    fi
    if [[ -e ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/arch.conf ]]; then
      sed -i '/linux \//a initrd \/intel-ucode.img' ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/arch.conf
    fi
  }

  # Save repetition
  install_ati(){
    PACSTRAP xf86-video-ati
    sed -i 's/MODULES=""/MODULES="radeon"/' ${MOUNTPOINT}/etc/mkinitcpio.conf
  }

  # Main menu. Correct option for graphics card should be automatically highlighted.
  NVIDIA=""
  VB_MOD=""
  GRAPHIC_CARD=""
  INTEGRATED_GC="N/A"
  GRAPHIC_CARD=$(lspci | grep -i "vga" | sed 's/.*://' | sed 's/(.*//' | sed 's/^[ \t]*//')
  # Highlight menu entry depending on GC detected. Extra work is needed for NVIDIA
  if 	[[ $(echo $GRAPHIC_CARD | grep -i "nvidia") != "" ]]; then
    # If NVIDIA, first need to know the integrated GC
    [[ $(lscpu | grep -i "intel\|lenovo") != "" ]] && INTEGRATED_GC="Intel" || INTEGRATED_GC="ATI"
    # Second, identity the NVIDIA card and driver / menu entry
    if [[ $(dmesg | grep -i 'chipset' | grep -i 'nvc\|nvd\|nve') != "" ]]; then
      HIGHLIGHT_SUB_GC=4
    elif [[ $(dmesg | grep -i 'chipset' | grep -i 'nva\|nv5\|nv8\|nv9'﻿) != "" ]]; then
      HIGHLIGHT_SUB_GC=5
    elif [[ $(dmesg | grep -i 'chipset' | grep -i 'nv4\|nv6') != "" ]]; then
      HIGHLIGHT_SUB_GC=6
    else
      HIGHLIGHT_SUB_GC=3
    fi
    # All non-NVIDIA cards / virtualisation
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'intel\|lenovo') != "" ]]; then
    HIGHLIGHT_SUB_GC=2
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'ati') != "" ]]; then
    HIGHLIGHT_SUB_GC=1
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'via') != "" ]]; then
    HIGHLIGHT_SUB_GC=7
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'virtualbox') != "" ]]; then
    HIGHLIGHT_SUB_GC=8
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'vmware') != "" ]]; then
    HIGHLIGHT_SUB_GC=9
  else
    HIGHLIGHT_SUB_GC=10
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB_GC} --title "$_GCtitle" \
  --menu "$GRAPHIC_CARD\n" 0 0 10 \
  "1" $"xf86-video-ati" \
  "2" $"xf86-video-intel" \
  "3" $"xf86-video-nouveau (+ $INTEGRATED_GC)" \
  "4" $"Nvidia (+ $INTEGRATED_GC)" \
  "5" $"Nvidia-340xx (+ $INTEGRATED_GC)" \
  "6" $"Nvidia-304xx (+ $INTEGRATED_GC)" \
  "7" $"xf86-video-openchrome" \
  "8" $"virtualbox-guest-xxx" \
  "9" $"xf86-video-vmware" \
  "10" "$_GCUnknOpt / xf86-video-fbdev" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    # ATI/AMD
    install_ati
    ;;
    "2")
    # Intel
    install_intel
    ;;
    "3")
    # Nouveau / NVIDIA
    [[ $INTEGRATED_GC == "ATI" ]] &&  install_ati || install_intel
    PACSTRAP xf86-video-nouveau
    sed -i 's/MODULES=""/MODULES="nouveau"/' ${MOUNTPOINT}/etc/mkinitcpio.conf
    ;;
    "4")
    # NVIDIA-GF
    [[ $INTEGRATED_GC == "ATI" ]] &&  install_ati || install_intel
    arch_chroot "pacman -Rdds --noconfirm mesa-libgl mesa"
    # Set NVIDIA driver(s) to install depending on installed kernel(s)
    [[ $KERNEL == 3 ]] && NVIDIA="nvidia nvidia-lts"
    [[ $KERNEL == 2 ]] && NVIDIA="nvidia-lts"
    [[ $KERNEL == 1 ]] && NVIDIA="nvidia"
    PACSTRAP ${NVIDIA} nvidia-libgl nvidia-utils pangox-compat 2>/tmp/.errlog
    NVIDIA_INST=1
    ;;
    "5")
    # NVIDIA-340
    [[ $INTEGRATED_GC == "ATI" ]] &&  install_ati || install_intel
    arch_chroot "pacman -Rdds --noconfirm mesa-libgl mesa"
    # Set NVIDIA driver(s) to install depending on installed kernel(s)
    [[ $KERNEL == 3 ]] && NVIDIA="nvidia-340xx nvidia-340xx-lts"
    [[ $KERNEL == 2 ]] && NVIDIA="nvidia-340xx-lts"
    [[ $KERNEL == 1 ]] && NVIDIA="nvidia-340xx"
    PACSTRAP ${NVIDIA} nvidia-340xx-libgl nvidia-340xx-utils 2>/tmp/.errlog
    NVIDIA_INST=1
    ;;
    "6")
    # NVIDIA-304
    [[ $INTEGRATED_GC == "ATI" ]] &&  install_ati || install_intel
    arch_chroot "pacman -Rdds --noconfirm mesa-libgl mesa"
    # Set NVIDIA driver(s) to install depending on installed kernel(s)
    [[ $KERNEL == 3 ]] && NVIDIA="nvidia-304xx nvidia-304xx-lts"
    [[ $KERNEL == 2 ]] && NVIDIA="nvidia-304xx-lts"
    [[ $KERNEL == 1 ]] && NVIDIA="nvidia-304xx"
    PACSTRAP ${NVIDIA} nvidia-304xx-libgl nvidia-304xx-utils 2>/tmp/.errlog
    NVIDIA_INST=1
    ;;
    "7")
    # Via
    PACSTRAP xf86-video-openchrome
    ;;
    "8")
    # VirtualBox
    # Set VB modules to install depending on installed kernel(s)
    [[ $KERNEL == 3 ]] && VB_MOD="virtualbox-guest-modules virtualbox-guest-modules-lts"
    [[ $KERNEL == 2 ]] && VB_MOD="virtualbox-guest-modules-lts"
    [[ $KERNEL == 1 ]] && VB_MOD="virtualbox-guest-modules"
    DIALOG --title "$_VBoxInstTitle" --msgbox "$_VBoxInstBody" 0 0
    PACSTRAP virtualbox-guest-utils ${VB_MOD} 2>/tmp/.errlog
    # Load modules and enable vboxservice.
    arch_chroot "modprobe -a vboxguest vboxsf vboxvideo"
    arch_chroot "systemctl enable vboxservice"
    echo -e "vboxguest\nvboxsf\nvboxvideo" > ${MOUNTPOINT}/etc/modules-load.d/virtualbox.conf
    ;;
    "9")
    # VMWare
    PACSTRAP xf86-video-vmware xf86-input-vmmouse
    ;;
    "10")
    # Generic / Unknown
    PACSTRAP xf86-video-fbdev
    ;;
    *)
    install_desktop_menu
    ;;
  esac
  check_for_error
  # Create a basic xorg configuration file for NVIDIA proprietary drivers where installed
  # if that file does not already exist.
  if [[ $NVIDIA_INST == 1 ]] && [[ ! -e ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf ]]; then
    echo "Section "\"Device"\"" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "        Identifier "\"Nvidia Card"\"" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "        Driver "\"nvidia"\"" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "        VendorName "\"NVIDIA Corporation"\"" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "        Option "\"NoLogo"\" "\"true"\"" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "        #Option "\"UseEDID"\" "\"false"\"" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "        #Option "\"ConnectedMonitor"\" "\"DFP"\"" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "        # ..." >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
    echo "EndSection" >> ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
  fi
  # Where NVIDIA has been installed allow user to check and amend the file
  if [[ $NVIDIA_INST == 1 ]]; then
    DIALOG --title "$_NvidiaConfTitle" --msgbox "$_NvidiaConfBody" 0 0
    nano ${MOUNTPOINT}/etc/X11/xorg.conf.d/20-nvidia.conf
  fi
}

install_de_wm() {
  # Only show this information box once
  if [[ $SHOW_ONCE -eq 0 ]]; then
    DIALOG --title "$_InstDETitle" --msgbox "$_DEInfoBody" 0 0
    SHOW_ONCE=1
  fi
  # DE/WM Menu
  DIALOG --title "$_InstDETitle" --checklist "$_InstDEBody $_UseSpaceBar" 0 0 12 \
  "cinnamon" "-" off \
  "deepin" "-" off \
  "deepin-extra" "-" off \
  "enlightenment + terminology" "-" off \
  "gnome-shell" "-" off \
  "gnome" "-" off \
  "gnome-extra" "-" off \
  "plasma-desktop" "-" off \
  "plasma" "-" off \
  "kde-applications" "-" off \
  "lxde" "-" off \
  "lxqt + oxygen-icons" "-" off \
  "mate" "-" off \
  "mate-extra" "-" off \
  "mate-gtk3" "-" off \
  "mate-extra-gtk3" "-" off \
  "xfce4" "-" off \
  "xfce4-goodies" "-" off \
  "awesome + vicious" "-" off \
  "fluxbox + fbnews" "-" off \
  "i3-wm + i3lock + i3status" "-" off \
  "icewm + icewm-themes" "-" off \
  "openbox + openbox-themes" "-" off \
  "pekwm + pekwm-themes" "-" off \
  "windowmaker" "-" off 2>${PACKAGES}
  # If something has been selected, install
  if [[ $(cat ${PACKAGES}) != "" ]]; then
    sed -i 's/+\|\"//g' ${PACKAGES}
    PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
    check_for_error
    # Clear the packages file for installation of "common" packages
    echo "" > ${PACKAGES}
    # Offer to install various "common" packages.
    DIALOG --title "$_InstComTitle" --checklist "$_InstComBody $_UseSpaceBar" 0 50 14 \
    "bash-completion" "-" on \
    "gamin" "-" on \
    "gksu" "-" on \
    "gnome-icon-theme" "-" on \
    "gnome-keyring" "-" on \
    "gvfs" "-" on \
    "gvfs-afc" "-" on \
    "gvfs-smb" "-" on \
    "polkit" "-" on \
    "poppler" "-" on \
    "python2-xdg" "-" on \
    "ntfs-3g" "-" on \
    "ttf-dejavu" "-" on \
    "xdg-user-dirs" "-" on \
    "xdg-utils" "-" on \
    "xterm" "-" on 2>${PACKAGES}
    # If at least one package, install.
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
    fi
  fi
}

# Display Manager
install_dm() {

  # Save repetition of code
  enable_dm() {
    arch_chroot "systemctl enable $(cat ${PACKAGES})" 2>/tmp/.errlog
    check_for_error
    DM_ENABLED=1
  }

  if [[ $DM_ENABLED -eq 0 ]]; then
    # Prep variables
    echo "" > ${PACKAGES}
    dm_list="gdm lxdm lightdm sddm"
    DM_LIST=""
    DM_INST=""
    # Generate list of DMs installed with DEs, and a list for selection menu
    for i in ${dm_list}; do
      [[ -e ${MOUNTPOINT}/usr/bin/${i} ]] && DM_INST="${DM_INST} ${i}"
      DM_LIST="${DM_LIST} ${i} -"
    done
    DIALOG --title "$_DmChTitle" --menu "$_AlreadyInst$DM_INST\n\n$_DmChBody" 0 0 5 \
    ${DM_LIST} 2>${PACKAGES}
    clear
    # If a selection has been made, act
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      # check if selected dm already installed. If so, enable and break loop.
      for i in ${DM_INST}; do
        [[ $(cat ${PACKAGES}) == ${i} ]] && enable_dm && break;
      done
      # If no match found, install and enable DM
      if [[ $DM_ENABLED -eq 0 ]]; then
        # Where lightdm selected, add gtk greeter package
        sed -i 's/lightdm/lightdm lightdm-gtk-greeter/' ${PACKAGES}
        PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
        # Where lightdm selected, now remove the greeter package
        sed -i 's/lightdm-gtk-greeter//' ${PACKAGES}
        enable_dm
      fi
    fi
  fi
  # Show after successfully installing or where attempting to repeat when already completed.
  [[ $DM_ENABLED -eq 1 ]] && DIALOG --title "$_DmChTitle" --msgbox "$_DmDoneBody" 0 0
}

# Network Manager
install_nm() {

  # Save repetition of code
  enable_nm() {
    if [[ $(cat ${PACKAGES}) == "NetworkManager" ]]; then
      arch_chroot "systemctl enable NetworkManager.service && systemctl enable NetworkManager-dispatcher.service" >/tmp/.symlink 2>/tmp/.errlog
    else
      arch_chroot "systemctl enable $(cat ${PACKAGES})" 2>/tmp/.errlog
    fi
    check_for_error
    NM_ENABLED=1
  }

  if [[ $NM_ENABLED -eq 0 ]]; then
    # Prep variables
    echo "" > ${PACKAGES}
    nm_list="connman CLI dhcpcd CLI netctl CLI NetworkManager GUI wicd GUI"
    NM_LIST=""
    NM_INST=""
    # Generate list of DMs installed with DEs, and a list for selection menu
    for i in ${nm_list}; do
      [[ -e ${MOUNTPOINT}/usr/bin/${i} ]] && NM_INST="${NM_INST} ${i}"
      NM_LIST="${NM_LIST} ${i}"
    done
    # Remove netctl from selectable list as it is a PITA to configure via arch_chroot
    NM_LIST=$(echo $NM_LIST | sed "s/netctl CLI//")
    DIALOG --title "$_InstNMTitle" --menu "$_AlreadyInst $NM_INST\n$_InstNMBody" 0 0 4 \
    ${NM_LIST} 2> ${PACKAGES}
    clear
    # If a selection has been made, act
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      # check if selected nm already installed. If so, enable and break loop.
      for i in ${NM_INST}; do
        [[ $(cat ${PACKAGES}) == ${i} ]] && enable_nm && break
      done
      # If no match found, install and enable NM
      if [[ $NM_ENABLED -eq 0 ]]; then
        # Where networkmanager selected, add network-manager-applet
        sed -i 's/NetworkManager/networkmanager network-manager-applet/' ${PACKAGES}
        PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
        # Where networkmanager selected, now remove network-manager-applet
        sed -i 's/networkmanager network-manager-applet/NetworkManager/g' ${PACKAGES}
        enable_nm
      fi
    fi
  fi
  # Show after successfully installing or where attempting to repeat when already completed.
  [[ $NM_ENABLED -eq 1 ]] && DIALOG --title "$_InstNMTitle" --msgbox "$_InstNMErrBody" 0 0
}

install_multimedia_menu(){

  install_alsa_pulse(){
    # Prep Variables
    echo "" > ${PACKAGES}
    PULSE_EXTRA=""
    pulse_extra=$(pacman -Ss pulseaudio- | awk '{print $1}' | sed "s/extra\///g" | grep "pulseaudio-" | sort -u)
    for i in ${pulse_extra}; do
      PULSE_EXTRA="${PULSE_EXTRA} ${i} - off"
    done
    DIALOG --title "$_AXITitle" --checklist "$_AXIBody$_UseSpaceBar" 0 0 10 \
    "alsa-firmware" "-" off \
    "alsa-plugins" "-" on \
    "alsa-tools" "-" off \
    "alsa-utils" "-" on \
    "pulseaudio" "-" off \
    $PULSE_EXTRA \
    "paprefs" "pulseaudio GUI" off \
    "pavucontrol" "pulseaudio GUI" off \
    "ponymix" "pulseaudio CLI" off \
    "volumeicon" "ALSA GUI" off \
    "volwheel" "ASLA GUI" off 2>${PACKAGES}
    # If at least one package, install.
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
    fi
  }

  install_codecs(){
    # Prep Variables
    echo "" > ${PACKAGES}
    GSTREAMER=""
    gstreamer=$(pacman -Ss gstreamer | awk '{print $1}' | grep "/gstreamer" | sed "s/extra\///g" | sed "s/community\///g" | sort -u)
    echo $gstreamer
    for i in ${gstreamer}; do
      GSTREAMER="${GSTREAMER} ${i} - off"
    done
    DIALOG --title " $_InstMulCodec " --checklist "$_InstMulCodBody$_UseSpaceBar" 0 0 14 \
    $GSTREAMER "xine-lib" "-" off 2>${PACKAGES}
    # If at least one package, install.
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
    fi
  }

  install_cust_pkgs(){
    echo "" > ${PACKAGES}
    DIALOG --title " $_InstMulCust " --inputbox "$_InstMulCustBody" 0 0 "" 2>${PACKAGES} || install_multimedia_menu
    # If at least one package, install.
    if [[ $(cat ${PACKAGES}) != "" ]]; then
      PACSTRAP $(cat ${PACKAGES}) 2>/tmp/.errlog
      check_for_error
    fi
  }

  if [[ $SUB_MENU != "install_multimedia_menu" ]]; then
    SUB_MENU="install_multimedia_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 5 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi

  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_InstMultMenuTitle" --menu "$_InstMultMenuBody" 0 0 5 \
  "1" "$_InstMulSnd" \
  "2" "$_InstMulCodec" \
  "3" "$_InstMulAcc" \
  "4" "$_InstMulCust" \
  "5" "$_Back" 2>${ANSWER}

  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    install_alsa_pulse
    ;;
    "2")
    install_codecs
    ;;
    "3")
    install_acc_menu
    ;;
    "4")
    install_cust_pkgs
    ;;
    *)
    main_menu_online
    ;;
  esac
}

# Let the user choose a shell
install_shell() {

  zsh_config() {
    DIALOG --title "$_ZshConfMenuTitle" \
    --menu "$_ZshConfMenuBody" 0 0 10 \
    "1" "Vanilla" \
    "2" "ohMyZsh" \
    "3" "antigen" 2>${ANSWER}
    case $(cat ${ANSWER}) in
      "2" | "3")
      arch_chroot "pacman -Q git curl" 2>/tmp/.errlog
      check_for_error
      if [ $? == 1 ] ; then
        if DIALOG --yesno "$_ZshConfInstAdd" 0 0 ; then
          PACSTRAP git curl
        else
          install_add_menu
        fi
      fi
      checklist_of_user
      if [[ -n $USER_LIST ]] ; then
        DIALOG --title "$_ZshConfUserTitle" --checklist "$_ZshConfUserBody" 0 0 10 \
        ${USER_LIST} 2>${ANSWER} || install_add_menu
        for i in $(cat ${ANSWER}); do
          if [[ $(cat ${ANSWER}) == "2" ]]; then
            arch_chroot "git clone git://github.com/robbyrussell/oh-my-zsh.git /home/${i}/.oh-my-zsh" 2>/tmp/.errlog
            arch_chroot "cp /home/${i}/.oh-my-zsh/templates/zshrc.zsh-template /home/${i}/.zshrc" 2>>/tmp/.errlog
          else
            arch_chroot "git clone https://github.com/zsh-users/antigen.git /home/${i}/.antigen" 2>/tmp/.errlog
          fi
          check_for_error
        done
      fi
      ;;
      *)
      install_add_menu
      ;;
    esac
    install_add_menu
  }

  DIALOG --title "$_InstShellTitle" \
  --menu "$_InstShellBody" 0 0 10 \
  "1" "bash" \
  "2" "dash" \
  "3" "fish" \
  "4" "mksh" \
  "5" "tcsh" \
  "6" "zsh" \
  "99" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    PACSTRAP bash
    SH="bash"
    ;;
    "2")
    PACSTRAP dash
    SH="dash"
    ;;
    "3")
    PACSTRAP fish
    SH="fish"
    ;;
    "4")
    PACSTRAP mksh
    SH="mksh"
    ;;
    "5")
    PACSTRAP tcsh
    SH="tcsh"
    ;;
    "6")
    PACSTRAP zsh
    zsh_config
    SH="zsh"
    ;;
    *)
    install_add_menu
    ;;
  esac
  check_for_error
  # Ask for changing user's shell
  checklist_of_user
  if [[ -n $USER_LIST ]] && DIALOG --yesno "$_InstShellChsh" 0 0 ; then
    DIALOG --title "$_ChangeShTitle" --checklist "$_ChangeShBody" 0 0 10 \
    ${USER_LIST} 2>${ANSWER} || install_add_menu
    for i in $(cat ${ANSWER}); do
      arch_chroot "chsh -s /bin/${SH} ${i}" 2>/tmp/.errlog
      check_for_error
    done
  fi
}

# Let the user install an editor
install_editor() {
  DIALOG --title "$_InstEditorTitle" \
  --menu "$_InstEditorBody" 0 0 10 \
  "1" "emacs" \
  "2" "emacs without X" \
  "3" "vim" \
  "99" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    PACSTRAP emacs
    ;;
    "2")
    PACSTRAP emacs-nox
    ;;
    "3")
    PACSTRAP vim
    ;;
    *)
    install_add_menu
    ;;
  esac
  check_for_error
}

# Let the user install a browser
install_browser() {
  DIALOG --title "$_InstBrowserTitle" \
  --menu "$_InstBrowserBody" 0 0 10 \
  "1" "Chromium" \
  "2" "Firefox" \
  "3" "Opera" \
  "99" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    PACSTRAP chromium
    ;;
    "2")
    PACSTRAP firefox
    ;;
    "3")
    PACSTRAP opera
    ;;
    *)
    install_add_menu
    ;;
  esac
  check_for_error
}

test() {
  ping -c 3 google.com > /tmp/.outfile &
  DIALOG --title "checking" --no-kill --tailboxbg /tmp/.outfile 20 60
}

################################################################################
##
## Main Interfaces
##
################################################################################

# Greet the user when first starting the installer
greeting() {
  DIALOG --title "$_WelTitle $VERSION " --msgbox "$_WelBody" 0 0
}

# Preparation
prep_menu() {
  if [[ $SUB_MENU != "prep_menu" ]]; then
    SUB_MENU="prep_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 7 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_PrepMenuTitle" --menu "$_PrepMenuBody" 0 0 7 \
  "1" "$_VCKeymapTitle" \
  "2" "$_DevShowOpt" \
  "3" "$_PrepPartDisk" \
  "4" "$_PrepLUKS" \
  "5" "$_PrepLVM" \
  "6" "$_PrepMntPart" \
  "7" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    set_keymap
    ;;
    "2")
    show_devices
    ;;
    "3")
    umount_partitions
    select_device
    create_partitions
    ;;
    "4")
    echo "" >/dev/null # LUKS here
    ;;
    "5")
    detect_lvm
    deactivate_lvm
    find_lvm_partitions
    create_lvm
    ;;
    "6")
    mount_partitions
    ;;
    *)
    main_menu_online
    ;;
  esac
  prep_menu
}

# Base Installation
install_base_menu() {
  if [[ $SUB_MENU != "install_base_menu" ]]; then
    SUB_MENU="install_base_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 6 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  if [ $PACOPT == -1 ] && DIALOG --yesno "$_InstAskPac" 0 0 ; then
    PACOPT=0
  elif [ $PACOPT == -1 ]; then
    PACOPT=1
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_InstBsMenuTitle" \
  --menu "$_InstBseMenuBody" 0 0 5 \
  "1"	"$_PrepMirror" \
  "2" "$_PrepPacKey" \
  "3" "$_InstBse" \
  "4" "$_InstAur" \
  "5" "$_InstBootldr" \
  "6" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    configure_mirrorlist
    ;;
    "2")
    clear
    pacman-key --init
    pacman-key --populate archlinux
    pacman-key --refresh-keys
    ;;
    "3")
    install_base
    ;;
    "4")
    install_aur
    ;;
    "5")
    install_bootloader
    ;;
    "6")
    install_wireless_packages
    ;;
    *)
    main_menu_online
    ;;
  esac
  install_base_menu
}

# Base Configuration
config_base_menu() {
  # Set the default PATH variable
  arch_chroot "PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/core_perl" 2>/tmp/.errlog
  check_for_error
  if [[ $SUB_MENU != "config_base_menu" ]]; then
    SUB_MENU="config_base_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 8 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_ConfBseTitle" --menu "$_ConfBseBody" 0 0 8 \
  "1" "$_ConfBseFstab" \
  "2" "$_ConfBseHost" \
  "3" "$_ConfBseSysLoc" \
  "4" "$_ConfBseTimeHC" \
  "5" "$_ConfUsrRoot" \
  "6" "$_ConfUsrNew" \
  "7" "$_MMRunMkinit" \
  "8" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    generate_fstab
    ;;
    "2")
    set_hostname
    ;;
    "3")
    set_locale
    ;;
    "4")
    set_timezone
    set_hw_clock
    ;;
    "5")
    set_root_password
    ;;
    "6")
    create_new_user
    ;;
    "7")
    run_mkinitcpio
    ;;
    *)
    main_menu_online
    ;;
  esac
  config_base_menu
}

install_graphics_menu() {
  if [[ $SUB_MENU != "install_graphics_menu" ]]; then
    SUB_MENU="install_graphics_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 6 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title " $_InstGrMenuTitle " --menu "$_InstGrMenuBody" 0 0 6 \
  "1" "$_InstGrMenuDS" \
  "2" "$_InstGrMenuDD" \
  "3" "$_InstGrMenuGE" \
  "4" "$_InstGrMenuDM" \
  "5"	"$_PrepKBLayout" \
  "6" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    install_xorg_input
    ;;
    "2")
    setup_graphics_card
    ;;
    "3")
    install_de_wm
    ;;
    "4")
    install_dm
    ;;
    "5")
    set_xkbmap
    ;;
    *)
    main_menu_online
    ;;
  esac
  install_desktop_menu
}

# Install Accessibility Applications
install_acc_menu() {
  echo "" > ${PACKAGES}
  DIALOG --title "$_InstAccTitle" --checklist "$_InstAccBody" 0 0 15 \
  "accerciser" "-" off \
  "at-spi2-atk" "-" off \
  "at-spi2-core" "-" off \
  "brltty" "-" off \
  "caribou" "-" off \
  "dasher" "-" off \
  "espeak" "-" off \
  "espeakup" "-" off \
  "festival" "-" off \
  "java-access-bridge" "-" off \
  "java-atk-wrapper" "-" off \
  "julius" "-" off \
  "orca" "-" off \
  "qt-at-spi" "-" off \
  "speech-dispatcher" "-" off 2>${PACKAGES}
  clear
  # If something has been selected, install
  if [[ $(cat ${PACKAGES}) != "" ]]; then
    PACSTRAP ${PACKAGES} 2>/tmp/.errlog
    check_for_error
  fi
}

# Install additional software
install_add_menu() {
  if [[ $SUB_MENU != "install_add_menu" ]]; then
    SUB_MENU="install_add_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 99 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_InstAddMenuTitle" \
  --menu "$_InstAddMenuBody" 0 0 10 \
  "1" "Shell" \
  "2" "Editor" \
  "3" "Browser" \
  "99" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    install_shell
    ;;
    "2")
    install_editor
    ;;
    "3")
    install_browser
    ;;
    *)
    main_menu_online
    ;;
  esac
  check_for_error
  install_add_menu
}

edit_configs() {
  # Clear the file variables
  FILE=""
  FILE2=""
  user_list=""
  if [[ $SUB_MENU != "edit configs" ]]; then
    SUB_MENU="edit configs"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 10 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_SeeConfOptTitle" \
  --menu "$_SeeConfOptBody" 0 0 10 \
  "1" "/etc/vconsole.conf" \
  "2" "/etc/locale.conf" \
  "3" "/etc/hostname" \
  "4" "/etc/hosts" \
  "5" "/etc/sudoers" \
  "6" "/etc/mkinitcpio.conf" \
  "7" "/etc/fstab" \
  "8" "sys" \
  "9" "$DM" \
  "10" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    FILE="${MOUNTPOINT}/etc/vconsole.conf"
    ;;
    "2")
    FILE="${MOUNTPOINT}/etc/locale.conf"
    ;;
    "3")
    FILE="${MOUNTPOINT}/etc/hostname"
    ;;
    "4")
    FILE="${MOUNTPOINT}/etc/hosts"
    ;;
    "5")
    FILE="${MOUNTPOINT}/etc/sudoers"
    ;;
    "6")
    FILE="${MOUNTPOINT}/etc/mkinitcpio.conf"
    ;;
    "7")
    FILE="${MOUNTPOINT}/etc/fstab"
    ;;
    "8")
    FILE="${MOUNTPOINT}/boot/syslinux/syslinux.cfg"
    #case $BOOTLOADER in
    #          "Grub") FILE="${MOUNTPOINT}/etc/default/grub"
    #                  ;;
    #      "Syslinux") FILE="${MOUNTPOINT}/boot/syslinux/syslinux.cfg"
    #                  ;;
    #  "systemd-boot") FILE="${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/arch.conf"
    #                  FILE2="${MOUNTPOINT}${UEFI_MOUNT}/loader/loader.conf"
    #                  ;;
    #        "rEFInd") [[ -e ${MOUNTPOINT}${UEFI_MOUNT}/EFI/refind/refind.conf ]] \
    #                  && FILE="${MOUNTPOINT}${UEFI_MOUNT}/EFI/refind/refind.conf" || FILE="${MOUNTPOINT}${UEFI_MOUNT}/EFI/BOOT/refind.conf"
    #                  FILE2="${MOUNTPOINT}/boot/refind_linux.conf"
    #                  ;;
    #     esac
    ;;
    "9")
    case $DM in
      "LXDM")
      FILE="${MOUNTPOINT}/etc/lxdm/lxdm.conf"
      ;;
      "LightDM")
      FILE="${MOUNTPOINT}/etc/lightdm/lightdm.conf"
      ;;
      "SDDM")
      FILE="${MOUNTPOINT}/etc/sddm.conf"
      ;;
      "SLiM")
      FILE="${MOUNTPOINT}/etc/slim.conf"
      ;;
    esac
    ;;
    *)
    main_menu_online
    ;;
  esac
  # open file(s) with nano
  if [[ -e $FILE ]] && [[ $FILE2 != "" ]]; then
    nano $FILE $FILE2
  elif [[ -e $FILE ]]; then
    nano $FILE
  else
    DIALOG --title "$_ErrTitle" --msgbox "$_SeeConfErrBody" 0 0
  fi
  edit_configs
}

main_menu_online() {
  if [[ $HIGHLIGHT != 8 ]]; then
    HIGHLIGHT=$(( HIGHLIGHT + 1 ))
  fi
  DIALOG --default-item ${HIGHLIGHT} --title "$_MMTitle" \
  --menu "$_MMBody" 0 0 8 \
  "1" "$_PrepMenuTitle" \
  "2" "$_InstBsMenuTitle" \
  "3" "$_ConfBseMenuTitle" \
  "4" "$_InstGrMenuTitle" \
  "5" "$_InstNMMenuTitle" \
  "6" "$_MMAddSoft" \
  "7" "$_InstMultMenuTitle" \
  "8" "$_SeeConfOptTitle" \
  "9" "$_Done" 2>${ANSWER}
  HIGHLIGHT=$(cat ${ANSWER})
  # Depending on the answer, first check whether partition(s) are mounted and whether base has been installed
  if [[ $(cat ${ANSWER}) -eq 2 ]]; then
    check_mount
  fi
  if [[ $(cat ${ANSWER}) -ge 3 ]] && [[ $(cat ${ANSWER}) -le 7 ]]; then
    check_mount
    check_base
  fi
  case $(cat ${ANSWER}) in
    "1")
    prep_menu
    ;;
    "2")
    install_base_menu
    ;;
    "3")
    config_base_menu
    ;;
    "4")
    install_graphics_menu
    ;;
    "5")
    install_network_menu
    ;;
    "6")
    install_add_menu
    ;;
    "7")
    install_multimedia_menu
    ;;
    "8")
    edit_configs
    ;;
    *)
    DIALOG --yesno "$_CloseInstBody" 0 0
    if [[ $? -eq 0 ]]; then
      umount_partitions
      clear
      exit 0
    else
      main_menu_online
    fi
    ;;
  esac
  main_menu_online
}

################################################################################
##
## Execution
##
################################################################################

id_system
select_language
check_requirements
greeting

while true; do
  main_menu_online
done
