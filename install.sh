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
ANSWER="/tmp/.install"
# Save retyping
VERSION="Installation script for Archlinux"
# Installation
KDE_INSTALLED=0         # Has KDE been installed?
GNOME_INSTALLED=0       # Has Gnome been installed?
LXDE_INSTALLED=0        # Has LXDE been installed?
LXQT_INSTALLED=0        # Has LXQT been installed?
DM_INSTALLED=0          # Has a display manager been installed?
COMMON_INSTALLED=0      # Has the common-packages option been taken?
NM_INSTALLED=0          # Has a network connection manager been installed and enabled?
AXI_INSTALLED=0         # Have the ALSA, Xorg, and xf86-input packages been installed?
BOOTLOADER="n/a"        # Which bootloader has been installed?
EVOBOXFM=""             # Which file manager has been selected for EvoBox?
EVOBOXIB=""             # Which Internet Browser has been selected for EvoBox?
DM="n/a"                # Which display manager has been installed?
KEYMAP="us"             # Virtual console keymap. Default is "us"
XKBMAP="us"             # X11 keyboard layout. Default is "us"
ZONE=""                 # For time
SUBZONE=""              # For time
LOCALE="en_US.UTF-8"    # System locale. Default is "en_US.UTF-8"
LTS=0                   # Has the LTS Kernel been installed?
GRAPHIC_CARD=""         # graphics card
INTEGRATED_GC=""        # Integrated graphics card for NVIDIA
NVIDIA_INST=0           # Indicates if NVIDIA proprietary driver has been installed
SHOW_ONCE=0             # Show de_wm information only once
# Architecture
ARCHI=`uname -m`        # Display whether 32 or 64 bit system
SYSTEM="Unknown"        # Display whether system is BIOS or UEFI. Default is "unknown"
ROOT_PART=""            # ROOT partition
UEFI_PART=""            # UEFI partition
UEFI_MOUNT=""           # UEFI mountpoint
INST_DEV=""             # Device where system has been installed
HIGHLIGHT=0             # Highlight items for Main Menu
HIGHLIGHT_SUB=0         # Highlight items for submenus
SUB_MENU=""             # Submenu to be highlighted
# Logical Volume Management
LVM=0                   # Logical Volume Management Detected?
LUKS=0                  # Luks Detected?
LVM_ROOT=0              # LVM used for Root?
LVM_SEP_BOOT=0          # 1 = Seperate /boot, 2 = seperate /boot & LVM
LVM_DISABLE=0           # Option to allow user to deactive existing LVM
LVM_VG=""               # Name of volume group to create
LVM_VG_MB=0             # MB remaining of VG
LVM_LV_NAME=""          # Name of LV to create
LV_SIZE_INVALID=0       # Is LVM LV size entered valid?
VG_SIZE_TYPE=""         # Is VG in Gigabytes or Megabytes?
# Installation
AUTO=-1
MOUNTPOINT="/mnt"       # Installation
MOUNT_TYPE=""           # "/dev/" for standard partitions, "/dev/mapper" for LVM
BTRFS=0                 # BTRFS used? "1" = btrfs alone, "2" = btrfs + subvolume(s)
BTRFS_OPTS="/tmp/.btrfs_opts" #BTRFS Mount options
BTRFS_MNT=""            # used for syslinux where /mnt is a btrfs subvolume
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
  clear
  if [[ AUTO -eq 0 ]]; then
    pacstrap -i "$@"
  else
    pacstrap "$@"
  fi
}

# Add locale on-the-fly and sets source translation file for installer
select_language() {
  # Set english as base in case some language miss some translation
  source ./english.trans
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
    source ./italian.trans
    CURR_LOCALE="it_IT.UTF-8"
    ;;
    "3")
    source ./russian.trans
    CURR_LOCALE="ru_RU.UTF-8"
    FONT="LatKaCyrHeb-14.psfu"
    ;;
    "4")
    source ./turkish.trans
    CURR_LOCALE="tr_TR.UTF-8"
    FONT="LatKaCyrHeb-14.psfu"
    ;;
    "5")
    source ./dutch.trans
    CURR_LOCALE="nl_NL.UTF-8"
    ;;
    "6")
    source ./greek.trans
    CURR_LOCALE="el_GR.UTF-8"
    FONT="iso07u-16.psfu"
    ;;
    "7")
    source ./danish.trans
    CURR_LOCALE="da_DK.UTF-8"
    ;;
    "8")
    source ./hungarian.trans
    CURR_LOCALE="hu_HU.UTF-8"
    FONT="lat2-16.psfu"
    ;;
    "9")
    source ./portuguese.trans
    CURR_LOCALE="pt_BR.UTF-8"
    ;;
    "10")
    source ./german.trans
    CURR_LOCALE="de_DE.UTF-8"
    ;;
    "11")
    source ./french.trans
    CURR_LOCALE="fr_FR.UTF-8"
    ;;
    "12")
    source ./polish.trans
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
  pacman -Sy
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
  lsblk -o NAME,MODEL,TYPE,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop" | grep -v "rom" | grep -v "arch_airootfs" > /tmp/.devlist
  DIALOG --title "$_DevShowTitle" --textbox /tmp/.devlist 0 0
}

################################################################################
##
## Configuration Functions
##
################################################################################

# Adapted from AIS. Added option to allow users to edit the mirrorlist.
configure_mirrorlist() {

  # Generate a mirrorlist based on the country chosen.
  mirror_by_country() {
    COUNTRY_LIST=""
    countries_list=("AU_Australia AT_Austria BY_Belarus BE_Belgium BR_Brazil BG_Bulgaria CA_Canada CL_Chile CN_China CO_Colombia CZ_Czech_Republic DK_Denmark EE_Estonia FI_Finland FR_France DE_Germany GB_United_Kingdom GR_Greece HU_Hungary IN_India IE_Ireland IL_Israel IT_Italy JP_Japan KZ_Kazakhstan KR_Korea LV_Latvia LU_Luxembourg MK_Macedonia NL_Netherlands NC_New_Caledonia NZ_New_Zealand NO_Norway PL_Poland PT_Portugal RO_Romania RU_Russia RS_Serbia SG_Singapore SK_Slovakia ZA_South_Africa ES_Spain LK_Sri_Lanka SE_Sweden CH_Switzerland TW_Taiwan TR_Turkey UA_Ukraine US_United_States UZ_Uzbekistan VN_Vietnam")
    for i in ${countries_list}; do
      COUNTRY_LIST="${COUNTRY_LIST} ${i} -"
    done
    DIALOG --title "$_MirrorCntryTitle" --menu "$_MirrorCntryBody" 0 0 16 ${COUNTRY_LIST} 2>${ANSWER} || prep_menu
    COUNTRY_CODE=$(cat ${ANSWER} |sed 's/_.*//')
    URL="https://www.archlinux.org/mirrorlist/?country=${COUNTRY_CODE}&use_mirror_status=on"
    MIRROR_TEMP=$(mktemp --suffix=-mirrorlist)
    # Get latest mirror list and save to tmpfile
    DIALOG --title "$_MirrorGenTitle" --infobox "$_MirrorGenBody" 0 0
    curl -so ${MIRROR_TEMP} ${URL} 2>/tmp/.errlog
    check_for_error
    sed -i 's/^#Server/Server/g' ${MIRROR_TEMP}
    nano ${MIRROR_TEMP}
    DIALOG --yesno "$_MirrorGenQ" 0 0
    if [[ $? -eq 0 ]];then
      mv -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
      mv -f ${MIRROR_TEMP} /etc/pacman.d/mirrorlist
      chmod +r /etc/pacman.d/mirrorlist
      DIALOG --infobox "$_DoneMsg" 0 0
      sleep 2
    else
      prep_menu
    fi
  }

  DIALOG --title "$_MirrorlistTitle" \
  --menu "$_MirrorlistBody" 0 0 5 \
  "1" "$_MirrorbyCountry" \
  "2" "$_MirrorEdit" \
  "3" "$_MirrorRank" \
  "4" "$_MirrorRestore" \
  "5" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    mirror_by_country
    ;;
    "2")
    nano /etc/pacman.d/mirrorlist
    ;;
    "3")
    DIALOG --title "$_MirrorRankTitle" --infobox "$_MirrorRankBody" 0 0
    cp -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    rankmirrors -n 10 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist 2>/tmp/.errlog
    check_for_error
    DIALOG --infobox "$_DoneMsg" 0 0
    sleep 2
    ;;
    "4")
    if [[ -e /etc/pacman.d/mirrorlist.orig ]]; then
      mv -f /etc/pacman.d/mirrorlist.orig /etc/pacman.d/mirrorlist
      DIALOG --msgbox "$_MirrorRestDone" 0 0
    else
      DIALOG --title "$_MirrorNoneTitle" --msgbox "$_MirrorNoneBody" 0 0
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
  for i in $(ls -R /usr/share/kbd/keymaps | grep "map.gz" | sed 's/\.map.gz//g' | sort); do
    KEYMAPS="${KEYMAPS} ${i} -"
  done
  DIALOG --title "$_KeymapTitle" \
  --menu "$_KeymapBody" 20 40 16 ${KEYMAPS} 2>${ANSWER} || prep_menu
  KEYMAP=$(cat ${ANSWER})
  loadkeys $KEYMAP 2>/tmp/.errlog
  check_for_error
  echo -e "KEYMAP=${KEYMAP}\nFONT=${FONT}" > /tmp/vconsole.conf
}

# Set keymap for X11
set_xkbmap() {
  XKBMAP_LIST=""
  keymaps_xkb=("af_Afghani al_Albanian am_Armenian ara_Arabic at_German-Austria az_Azerbaijani ba_Bosnian bd_Bangla be_Belgian bg_Bulgarian br_Portuguese-Brazil bt_Dzongkha bw_Tswana by_Belarusian ca_French-Canada cd_French-DR-Congo ch_German-Switzerland cm_English-Cameroon cn_Chinese cz_Czech de_German dk_Danishee_Estonian epo_Esperanto es_Spanish et_Amharic fo_Faroese fi_Finnish fr_French gb_English-UK ge_Georgian gh_English-Ghana gn_French-Guinea gr_Greek hr_Croatian hu_Hungarian ie_Irish il_Hebrew iq_Iraqi ir_Persian is_Icelandic it_Italian jp_Japanese ke_Swahili-Kenya kg_Kyrgyz kh_Khmer-Cambodia kr_Korean kz_Kazakh la_Lao latam_Spanish-Lat-American lk_Sinhala-phonetic lt_Lithuanian lv_Latvian ma_Arabic-Morocco mao_Maori md_Moldavian me_Montenegrin mk_Macedonian ml_Bambara mm_Burmese mn_Mongolian mt_Maltese mv_Dhivehi ng_English-Nigeria nl_Dutch no_Norwegian np_Nepali ph_Filipino pk_Urdu-Pakistan pl_Polish pt_Portuguese ro_Romanian rs_Serbian ru_Russian se_Swedish si_Slovenian sk_Slovak sn_Wolof sy_Arabic-Syria th_Thai tj_Tajik tm_Turkmen tr_Turkish tw_Taiwanese tz_Swahili-Tanzania ua_Ukrainian us_English-US uz_Uzbek vn_Vietnamese za_English-S-Africa")
  for i in ${keymaps_xkb}; do
    XKBMAP_LIST="${XKBMAP_LIST} ${i} -"
  done
  DIALOG --title "$_XkbmapTitle" --menu "$_XkbmapBody" 0 0 16 ${XKBMAP_LIST} 2>${ANSWER} || config_base_menu
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
  DIALOG --title "$_TimeZTitle" --menu "$_TimeZBody" 0 0 10 ${ZONE} 2>${ANSWER} || config_base_menu
  ZONE=$(cat ${ANSWER})
  SUBZONE=""
  for i in $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "${ZONE}/" | sed "s/${ZONE}\///g" | sort -ud); do
    SUBZONE="$SUBZONE ${i} -"
  done
  DIALOG --title "$_TimeSubZTitle" --menu "$_TimeSubZBody" 0 0 11 ${SUBZONE} 2>${ANSWER} || config_base_menu
  SUBZONE=$(cat ${ANSWER})
  DIALOG --yesno "$_TimeZQ ${ZONE}/${SUBZONE} ?" 0 0
  if [[ $? -eq 0 ]]; then
    arch_chroot "ln -s /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime" 2>/tmp/.errlog
    check_for_error
  else
    config_base_menu
  fi
}

set_hw_clock() {
  DIALOG --title "$_HwCTitle" \
  --menu "$_HwCBody" 0 0 2 \
  "1" "$_HwCUTC" \
  "2" "$_HwLocal" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    arch_chroot "hwclock --systohc --utc"  2>/tmp/.errlog
    ;;
    "2")
    arch_chroot "hwclock --systohc --localtime" 2>/tmp/.errlog
    ;;
    *)
    config_base_menu
    ;;
  esac
  check_for_error
}

# Adapted from AIS. As with some other functions, decided that keeping the numbering for options
# was worth repeating portions of code.
generate_fstab() {
  DIALOG --title "$_FstabTitle" \
  --menu "$_FstabBody" 0 0 3 \
  "1" "$_FstabDev" \
  "2" "$_FstabLabel" \
  "3" "$_FstabUUID" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    genfstab -p ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab 2>/tmp/.errlog
    ;;
    "2")
    genfstab -L -p ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab 2>/tmp/.errlog
    ;;
    "3")
    if [[ $SYSTEM == "UEFI" ]]; then
      genfstab -t PARTUUID -p ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab 2>/tmp/.errlog
    else
      genfstab -U -p ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab 2>/tmp/.errlog
    fi
    ;;
    *)
    config_base_menu
    ;;
  esac
  check_for_error
  [[ -f ${MOUNTPOINT}/swapfile ]] && sed -i "s/\\${MOUNTPOINT}//" ${MOUNTPOINT}/etc/fstab
}

# Adapted from AIS.
set_hostname() {
  DIALOG --title "$_HostNameTitle" --inputbox "$_HostNameBody" 0 0 "arch" 2>${ANSWER} || config_base_menu
  HOST_NAME=$(cat ${ANSWER})
  echo "$HOST_NAME" > ${MOUNTPOINT}/etc/hostname 2>/tmp/.errlog
  check_for_error
  echo -e "#<ip-address>\t<hostname.domain.org>\t<hostname>\n127.0.0.1\tlocalhost.localdomain\tlocalhost\t${HOST_NAME}\n::1\tlocalhost.localdomain\tlocalhost\t${HOST_NAME}" > ${MOUNTPOINT}/etc/hosts
}

# Adapted and simplified from the Manjaro 0.8 and Antergos 2.0 installers
set_root_password() {
  DIALOG --title "$_PassRtTitle" --clear --insecure --passwordbox "$_PassRtBody" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD=$(cat ${ANSWER})
  DIALOG --title "$_PassRtTitle" --clear --insecure --passwordbox "$_PassRtBody2" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD2=$(cat ${ANSWER})
  if [[ $PASSWD == $PASSWD2 ]]; then
    echo -e "${PASSWD}\n${PASSWD}" > /tmp/.passwd
    arch_chroot "passwd root" < /tmp/.passwd >/dev/null 2>/tmp/.errlog
    rm /tmp/.passwd
    check_for_error
  else
    DIALOG --title "$_PassRtErrTitle" --msgbox "$_PassRtErrBody" 0 0
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
  DIALOG --title "$_PassNUsrTitle" --clear --insecure --passwordbox "$_PassNUsrBody $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD=$(cat ${ANSWER})
  DIALOG --title "$_PassNUsrTitle" --clear --insecure --passwordbox "$_PassNUsrBody2 $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
  PASSWD2=$(cat ${ANSWER})
  # loop while passwords entered do not match.
  while [[ $PASSWD != $PASSWD2 ]]; do
    DIALOG --title "$_PassNUsrErrTitle" --msgbox "$_PassNUsrErrBody" 0 0
    DIALOG --title "$_PassNUsrTitle" --clear --insecure --passwordbox "$_PassNUsrBody $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
    PASSWD=$(cat ${ANSWER})
    DIALOG --title "$_PassNUsrTitle" --clear --insecure --passwordbox "$_PassNUsrBody2 $USER\n\n" 0 0 2> ${ANSWER} || config_user_menu
    PASSWD2=$(cat ${ANSWER})
  done
  # create new user. This step will only be reached where the password loop has been skipped or broken.
  DIALOG --title "$_NUsrSetTitle" --infobox "$_NUsrSetBody" 0 0
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
  # Amend command depending on whether LTS kernel was installed or not
  [[ $LTS -eq 1 ]] && arch_chroot "mkinitcpio -p linux-lts" 2>/tmp/.errlog || arch_chroot "mkinitcpio -p linux" 2>/tmp/.errlog
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

# Adapted from AIS
confirm_mount() {
  if [[ $(mount | grep $1) ]]; then
    DIALOG --title "$_MntStatusTitle" --infobox "$_MntStatusSucc" 0 0
    sleep 2
    PARTITIONS="$(echo $PARTITIONS | sed s/${PARTITION}$' -'//)"
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

# Adapted from AIS. However, this does not assume that the formatted device is the Root
# installation device; more than one device may be formatted. This is now set in the
# mount_partitions function, when the Root is chosen.
select_device() {
  DEVICE=""
  devices_list=$(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme');
  for i in ${devices_list[@]}; do
    DEVICE="${DEVICE} ${i} -"
  done
  DIALOG --title "$_DevSelTitle" --menu "$_DevSelBody" 0 0 4 ${DEVICE} 2>${ANSWER} || prep_menu
  DEVICE=$(cat ${ANSWER})
}

# Same as above, but goes to install_base_menu instead where cancelling, and otherwise installs Grub.
select_grub_device() {
  GRUB_DEVICE=""
  grub_devices_list=$(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd');
  for i in ${grub_devices_list[@]}; do
    GRUB_DEVICE="${GRUB_DEVICE} ${i} -"
  done
  DIALOG --title "$_DevSelGrubTitle" --menu "$_DevSelBody" 0 0 4 ${GRUB_DEVICE} 2>${ANSWER} || install_base_menu
  GRUB_DEVICE=$(cat ${ANSWER})
  clear
  DIALOG --title " Grub-install " --infobox "$_PlsWaitBody" 0 0
  sleep 1
  arch_chroot "grub-install --target=i386-pc --recheck ${GRUB_DEVICE}" 2>/tmp/.errlog
  check_for_error
}

# Originally adapted from AIS.
create_partitions(){

  # This only creates the minimum number of partition(s) necessary. Users wishing for other schemes will
  # have to learn to use a partitioning application.
  auto_partition(){

    # Hooray for tac! Deleting partitions in reverse order deals with logical partitions easily.
    delete_partitions(){
      parted -s ${DEVICE} print | awk '/^ / {print $1}' > /tmp/.del_parts
      for del_part in $(tac /tmp/.del_parts); do
        parted -s ${DEVICE} rm ${del_part} 2>/tmp/.errlog
        check_for_error
      done
    }

    # Identify the partition table
    part_table=$(parted -s ${DEVICE} print | grep -i 'partition table' | awk '{print $3}')
    # Autopartition for BIOS systems
    if [[ $SYSTEM == "BIOS" ]]; then
      DIALOG --title " Auto-Partition (BIOS/MBR) " --yesno "$_AutoPartBody1 $DEVICE $_AutoPartBIOSBody2" 0 0
      if [[ $? -eq 0 ]]; then
        delete_partitions
        if [[ $part_table != "msdos" ]]; then
          parted -s ${DEVICE} mklabel msdos 2>/tmp/.errlog
          check_for_error
        fi
        parted -s ${DEVICE} mkpart primary ext4 1MiB 100% 2>/tmp/.errlog
        parted -s ${DEVICE} set 1 boot on 2>>/tmp/.errlog
        check_for_error
        echo -e "Partition Scheme:\n" > /tmp/.devlist
        lsblk ${DEVICE} -o NAME,TYPE,FSTYPE,SIZE > /tmp/.devlist
        DIALOG --title "" --textbox /tmp/.devlist 0 0
      else
        create_partitions
      fi
      # Autopartition for UEFI systems
    else
      DIALOG --title " Auto-Partition (UEFI/GPT) " --yesno "$_AutoPartBody1 $DEVICE $_AutoPartUEFIBody2" 0 0
      if [[ $? -eq 0 ]]; then
        delete_partitions
        if [[ $part_table != "gpt" ]]; then
          parted -s ${DEVICE} mklabel gpt 2>/tmp/.errlog
          check_for_error
        fi
        parted -s ${DEVICE} mkpart ESP fat32 1MiB 513MiB 2>/tmp/.errlog
        parted -s ${DEVICE} set 1 boot on 2>>/tmp/.errlog
        parted -s ${DEVICE} mkpart primary ext4 513MiB 100% 2>>/tmp/.errlog
        echo -e "Partition Scheme:\n" > /tmp/.devlist
        lsblk ${DEVICE} -o NAME,TYPE,FSTYPE,SIZE >> /tmp/.devlist
        DIALOG --title "" --textbox /tmp/.devlist 0 0
      else
        create_partitions
      fi
    fi
  }

  DIALOG --title "$_PartToolTitle" \
  --menu "$_PartToolBody" 0 0 6 \
  "1" $"Auto Partition (BIOS & UEFI)" \
  "2" $"Parted (BIOS & UEFI)" \
  "3" $"CFDisk (BIOS/MBR)" \
  "4" $"CGDisk (UEFI/GPT)" \
  "5" $"FDisk  (BIOS & UEFI)" \
  "6" $"GDisk  (UEFI/GPT)" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    auto_partition
    ;;
    "2")
    clear
    parted ${DEVICE}
    ;;
    "3")
    cfdisk ${DEVICE}
    ;;
    "4")
    cgdisk ${DEVICE}
    ;;
    "5")
    clear
    fdisk ${DEVICE}
    ;;
    "6")
    clear
    gdisk ${DEVICE}
    ;;
    *)
    prep_menu
    ;;
  esac
}

# find all available partitions and generate a list of them
# This also includes partitions on different devices.
find_partitions() {
  PARTITIONS=""
  NUMBER_PARTITIONS=0
  partition_list=$(lsblk -l | grep 'part\|lvm' | sed 's/[\t ].*//' | sort -u)
  for i in ${partition_list[@]}; do
    PARTITIONS="${PARTITIONS} ${i} -"
    NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS + 1 ))
  done
  # Deal with incorrect partitioning
  if [[ $NUMBER_PARTITIONS -lt 2 ]] && [[ $SYSTEM == "UEFI" ]]; then
    DIALOG --title "$_UefiPartErrTitle" --msgbox "$_UefiPartErrBody" 0 0
    create_partitions
  fi
  if [[ $NUMBER_PARTITIONS -eq 0 ]] && [[ $SYSTEM == "BIOS" ]]; then
    DIALOG --title "$_BiosPartErrTitle" --msgbox "$_BiosPartErrBody" 0 0
    create_partitions
  fi
}

# Set static list of filesystems rather than on-the-fly. Partially as most require additional flags, and
# partially because some don't seem to be viable.
select_filesystem(){
  # Clear special FS type flags
  BTRFS=0
  DIALOG --title "$_FSTitle" \
  --menu "$_FSBody" 0 0 12 \
  "1" "$_FSSkip" \
  "2" $"btrfs" \
  "3" $"ext2" \
  "4" $"ext3" \
  "5" $"ext4" \
  "6" $"f2fs" \
  "7" $"jfs" \
  "8" $"nilfs2" \
  "9" $"ntfs" \
  "10" $"reiserfs" \
  "11" $"vfat" \
  "12" $"xfs" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    FILESYSTEM="skip"
    ;;
    "2")
    FILESYSTEM="mkfs.btrfs -f"
    modprobe btrfs
    DIALOG --title "$_btrfsSVTitle" --yesno "$_btrfsSVBody" 0 0
    if [[ $? -eq 0 ]];then
      BTRFS=2
    else
      BTRFS=1
    fi
    ;;
    "3")
    FILESYSTEM="mkfs.ext2 -F"
    ;;
    "4")
    FILESYSTEM="mkfs.ext3 -F"
    ;;
    "5")
    FILESYSTEM="mkfs.ext4 -F"
    ;;
    "6")
    FILESYSTEM="mkfs.f2fs"
    modprobe f2fs
    ;;
    "7")
    FILESYSTEM="mkfs.jfs -q"
    ;;
    "8")
    FILESYSTEM="mkfs.nilfs2 -f"
    ;;
    "9")
    FILESYSTEM="mkfs.ntfs -q"
    ;;
    "10")
    FILESYSTEM="mkfs.reiserfs -f -f"
    ;;
    "11")
    FILESYSTEM="mkfs.vfat -F32"
    ;;
    "12")
    FILESYSTEM="mkfs.xfs -f"
    ;;
    *)
    prep_menu
    ;;
  esac
}

mount_partitions() {

  # function created to save repetition of code. Checks and determines if standard partition or LVM LV,
  # and sets the prefix accordingly.
  set_mount_type() {
    [[ $(echo ${PARTITION} | grep 'sd\|hd\|vd[a-z][1-99]') != "" ]] && MOUNT_TYPE="/dev/" || MOUNT_TYPE="/dev/mapper/"
  }

  btrfs_subvols() {
    BTRFS_MSUB_VOL=""
    BTRFS_OSUB_VOL=""
    BTRFS_MNT=""
    BTRFS_VOL_LIST="/tmp/.vols"
    echo "" > ${BTRFS_VOL_LIST}
    BTRFS_OSUB_NUM=1
    DIALOG --title "$_btrfsSVTitle" --inputbox "$_btrfsMSubBody1 ${MOUNTPOINT}${MOUNT} $_btrfsMSubBody2" 0 0 "" 2>${ANSWER} || select_filesystem
    BTRFS_MSUB_VOL=$(cat ${ANSWER})
    # if root, then create boot flag for syslinux, systemd-boot and rEFInd bootloaders
    [[ ${MOUNT} == "" ]] && BTRFS_MNT="rootflags=subvol="$BTRFS_MSUB_VOL
    # Loop while subvolume is blank or has spaces.
    while [[ ${#BTRFS_MSUB_VOL} -eq 0 ]] || [[ $BTRFS_MSUB_VOL =~ \ |\' ]]; do
      DIALOG --title "$_btrfsSVErrTitle" --inputbox "$_btrfsSVErrBody" 0 0 "" 2>${ANSWER} || select_filesystem
      BTRFS_MSUB_VOL=$(cat ${ANSWER})
      # if root, then create flag for syslinux, systemd-boot and rEFInd bootloaders
      [[ ${MOUNT} == "" ]] && BTRFS_MNT="rootflags=subvol="$BTRFS_MSUB_VOL
    done
    # change dir depending on whether root partition or not
    [[ ${MOUNT} == "" ]] && cd ${MOUNTPOINT} || cd ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    btrfs subvolume create ${BTRFS_MSUB_VOL} 2>>/tmp/.errlog
    cd
    umount ${MOUNT_TYPE}${PARTITION} 2>>/tmp/.errlog
    check_for_error
    # Get any mount options and mount
    btrfs_mount_opts
    if [[ $(cat ${BTRFS_OPTS}) != "" ]]; then
      [[ ${MOUNT} == "" ]] && mount -o $(cat ${BTRFS_OPTS})",subvol="${BTRFS_MSUB_VOL} ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT} 2>/tmp/.errlog || mount -o $(cat ${BTRFS_OPTS})",subvol="${BTRFS_MSUB_VOL} ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    else
      [[ ${MOUNT} == "" ]] &&	mount -o "subvol="${BTRFS_MSUB_VOL} ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT} 2>/tmp/.errlog || mount -o "subvol="${BTRFS_MSUB_VOL} ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    fi
    # Check for error and confirm successful mount
    check_for_error
    [[ ${MOUNT} == "" ]] && confirm_mount_btrfs ${MOUNTPOINT} || confirm_mount_btrfs ${MOUNTPOINT}${MOUNT}
    # Now create the subvolumes
    [[ ${MOUNT} == "" ]] && cd ${MOUNTPOINT} || cd ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    check_for_error
    # Loop while the termination character has not been entered
    while [[ $BTRFS_OSUB_VOL != "*" ]]; do
      DIALOG --title "$_btrfsSVTitle ($BTRFS_MSUB_VOL) " --inputbox "$_btrfsSVBody1 $BTRFS_OSUB_NUM $_btrfsSVBody2 $BTRFS_MSUB_VOL.$_btrfsSVBody3 $(cat ${BTRFS_VOL_LIST})" 0 0 "" 2>${ANSWER} || select_filesystem
      BTRFS_OSUB_VOL=$(cat ${ANSWER})
      # Loop while subvolume is blank or has spaces.
      while [[ ${#BTRFS_OSUB_VOL} -eq 0 ]] || [[ $BTRFS_SUB_VOL =~ \ |\' ]]; do
        DIALOG --title "$_btrfsSVErrTitle ($BTRFS_MSUB_VOL) " --inputbox "$_btrfsSVErrBody ($BTRFS_OSUB_NUM)." 0 0 "" 2>${ANSWER} || select_filesystem
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
    DIALOG --title "$_btrfsMntTitle" --checklist "$_btrfsMntBody" 0 0 16 \
    "1" "autodefrag" off \
    "2" "compress=zlib" off \
    "3" "compress=lzo" off \
    "4" "compress=no" off \
    "5" "compress-force=zlib" off \
    "6" "compress-force=lzo" off \
    "7" "discard" off \
    "8" "noacl" off \
    "9" "noatime" off \
    "10" "nodatasum" off \
    "11" "nospace_cache" off \
    "12" "recovery" off \
    "13" "skip_balance" off \
    "14" "space_cache" off  \
    "15" "ssd" off \
    "16" "ssd_spread" off 2>${BTRFS_OPTS}
    # Double-digits first
    sed -i 's/10/nodatasum,/' ${BTRFS_OPTS}
    sed -i 's/11/nospace_cache,/' ${BTRFS_OPTS}
    sed -i 's/12/recovery,/' ${BTRFS_OPTS}
    sed -i 's/13/skip_balance,/' ${BTRFS_OPTS}
    sed -i 's/14/space_cache,/' ${BTRFS_OPTS}
    sed -i 's/15/ssd,/' ${BTRFS_OPTS}
    sed -i 's/16/ssd_spread,/' ${BTRFS_OPTS}
    # then single digits
    sed -i 's/1/autodefrag,/' ${BTRFS_OPTS}
    sed -i 's/2/compress=zlib,/' ${BTRFS_OPTS}
    sed -i 's/3/compress=lzo,/' ${BTRFS_OPTS}
    sed -i 's/4/compress=no,/' ${BTRFS_OPTS}
    sed -i 's/5/compress-force=zlib,/' ${BTRFS_OPTS}
    sed -i 's/6/compress-force=lzo,/' ${BTRFS_OPTS}
    sed -i 's/7/noatime,/' ${BTRFS_OPTS}
    sed -i 's/8/noacl,/' ${BTRFS_OPTS}
    sed -i 's/9/noatime,/' ${BTRFS_OPTS}
    # Now clean up the file
    sed -i 's/ //g' ${BTRFS_OPTS}
    sed -i '$s/,$//' ${BTRFS_OPTS}
    if [[ $(cat ${BTRFS_OPTS}) != "" ]]; then
      DIALOG --title "$_btrfsMntTitle" --yesno "$_btrfsMntConfBody $(cat $BTRFS_OPTS)\n" 0 0
      [[ $? -eq 1 ]] && btrfs_mount_opts
    fi
  }

  # LVM Detection. If detected, activate.
  detect_lvm
  if [[ $LVM -eq 1 ]]; then
    DIALOG --title "$_LvmDetTitle" --infobox "$_LvmDetBody2" 0 0
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
  DIALOG --title "$_SelRootTitle" --menu "$_SelRootBody" 0 0 4 ${PARTITIONS} 2>${ANSWER} || prep_menu
  PARTITION=$(cat ${ANSWER})
  ROOT_PART=${PARTITION}
  set_mount_type
  # This is to identify the device for Grub installations.
  if [[ $MOUNT_TYPE == "/dev/" ]]; then
    LVM_ROOT=0
    INST_DEV=${MOUNT_TYPE}$(cat ${ANSWER} | sed 's/[0-9]*//g')
  else
    LVM_ROOT=1
  fi
  select_filesystem
  [[ $FILESYSTEM != "skip" ]] && ${FILESYSTEM} ${MOUNT_TYPE}${PARTITION} >/dev/null 2>/tmp/.errlog
  check_for_error
  # Make the root directory
  mkdir -p ${MOUNTPOINT} 2>/tmp/.errlog
  # If btrfs without subvolumes has been selected, get the mount options
  [[ $BTRFS -eq 1 ]] && btrfs_mount_opts
  # If btrfs has been selected without subvolumes - and at least one btrfs mount option selected - then
  # mount with options. Otherwise, basic mount.
  if [[ $BTRFS -eq 1 ]] && [[ $(cat ${BTRFS_OPTS}) != "" ]]; then
    mount -o $(cat ${BTRFS_OPTS}) ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT} 2>>/tmp/.errlog
  else
    mount ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT} 2>>/tmp/.errlog
  fi
  # Check for error, confirm mount, and deal with BTRFS with subvolumes if applicable
  check_for_error
  confirm_mount ${MOUNTPOINT}
  [[ $BTRFS -eq 2 ]] && btrfs_subvols
  # Identify and create swap, if applicable
  DIALOG --title "$_SelSwpTitle" --menu "$_SelSwpBody" 0 0 4 "$_SelSwpNone" $"-" "$_SelSwpFile" $"-" ${PARTITIONS} 2>${ANSWER} || prep_menu
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
      set_mount_type
      # Only create a swap if not already in place
      [[ $(lsblk -o FSTYPE  ${MOUNT_TYPE}${PARTITION} | grep -i "swap") != "swap" ]] &&  mkswap  ${MOUNT_TYPE}${PARTITION} >/dev/null 2>/tmp/.errlog
      swapon  ${MOUNT_TYPE}${PARTITION} >/dev/null 2>>/tmp/.errlog
      check_for_error
      # Since a partition was used, remove that partition from the list
      PARTITIONS="$(echo $PARTITIONS | sed s/${PARTITION}$' -'//)"
      NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS - 1 ))
    fi
  fi
  # Extra Step for VFAT UEFI Partition. This cannot be in an LVM container.
  if [[ $SYSTEM == "UEFI" ]]; then
    DIALOG --title "$_SelUefiTitle" --menu "$_SelUefiBody" 0 0 4 ${PARTITIONS} 2>${ANSWER} || config_base_menu
    PARTITION=$(cat ${ANSWER})
    UEFI_PART=$"/dev/"${PARTITION}
    # If it is already a fat/vfat partition...
    if [[ $(fsck -N /dev/$PARTITION | grep fat) ]]; then
      DIALOG --title "$_FormUefiTitle" --yesno "$_FormUefiBody $PARTITION $_FormUefiBody2" 0 0 && mkfs.vfat -F32 $"/dev/"${PARTITION} >/dev/null 2>/tmp/.errlog
    else
      mkfs.vfat -F32 $"/dev/"${PARTITION} >/dev/null 2>/tmp/.errlog
    fi
    check_for_error
    # Inform users of the mountpoint options and consequences
    DIALOG --title "$_MntUefiTitle" --menu "$_MntUefiBody"  0 0 2 \
    "1" $"/boot" \
    "2" $"/boot/efi" 2>${ANSWER}
    case $(cat ${ANSWER}) in
      "1")
      UEFI_MOUNT="/boot"
      ;;
      "2")
      UEFI_MOUNT="/boot/efi"
      ;;
      *)
      config_base_menu
      ;;
    esac
    mkdir -p ${MOUNTPOINT}${UEFI_MOUNT} 2>/tmp/.errlog
    mount $"/dev/"${PARTITION} ${MOUNTPOINT}${UEFI_MOUNT} 2>>/tmp/.errlog
    check_for_error
    confirm_mount ${MOUNTPOINT}${UEFI_MOUNT}
  fi
  # All other partitions
  while [[ $NUMBER_PARTITIONS > 0 ]]; do
    DIALOG --title "$_ExtPartTitle" --menu "$_ExtPartBody" 0 0 4 "$_Done" $"-" ${PARTITIONS} 2>${ANSWER} || config_base_menu
    PARTITION=$(cat ${ANSWER})
    set_mount_type
    if [[ $PARTITION == ${_Done} ]]; then
      break;
    else
      MOUNT=""
      select_filesystem
      [[ $FILESYSTEM != "skip" ]] && ${FILESYSTEM} ${MOUNT_TYPE}${PARTITION} >/dev/null 2>/tmp/.errlog
      check_for_error
      # Don't give /boot as an example for UEFI systems!
      if [[ $SYSTEM == "UEFI" ]]; then
        DIALOG --title "$_ExtNameTitle $PARTITON " --inputbox "$_ExtNameBodyUefi" 0 0 "/" 2>${ANSWER} || config_base_menu
      else
        DIALOG --title "$_ExtNameTitle $PARTITON " --inputbox "$_ExtNameBodyBios" 0 0 "/" 2>${ANSWER} || config_base_menu
      fi
      MOUNT=$(cat ${ANSWER})
      # loop if the mountpoint specified is incorrect (is only '/', is blank, or has spaces).
      while [[ ${MOUNT:0:1} != "/" ]] || [[ ${#MOUNT} -le 1 ]] || [[ $MOUNT =~ \ |\' ]]; do
        DIALOG --title "$_ExtErrTitle" --msgbox "$_ExtErrBody" 0 0
        # Don't give /boot as an example for UEFI systems!
        if [[ $SYSTEM == "UEFI" ]]; then
          DIALOG --title "$_ExtNameTitle $PARTITON " --inputbox "$_ExtNameBodyUefi" 0 0 "/" 2>${ANSWER} || config_base_menu
        else
          DIALOG --title "$_ExtNameTitle $PARTITON " --inputbox "$_ExtNameBodyBios" 0 0 "/" 2>${ANSWER} || config_base_menu
        fi
        MOUNT=$(cat ${ANSWER})
      done
      # Create directory and mount. This step will only be reached where the loop has been skipped or broken.
      mkdir -p ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
      # If btrfs without subvolumes has been selected, get the mount options
      [[ $BTRFS -eq 1 ]] && btrfs_mount_opts
      # If btrfs has been selected without subvolumes - and at least one btrfs mount option selected - then
      # mount with options. Otherwise, basic mount.
      if [[ $BTRFS -eq 1 ]] && [[ $(cat ${BTRFS_OPTS}) != "" ]]; then
        mount -o $(cat ${BTRFS_OPTS}) ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT}${MOUNT} 2>>/tmp/.errlog
      else
        mount ${MOUNT_TYPE}${PARTITION} ${MOUNTPOINT}${MOUNT} 2>>/tmp/.errlog
      fi
      # Check for error, confirm mount, and deal with BTRFS with subvolumes if applicable
      check_for_error
      confirm_mount ${MOUNTPOINT}${MOUNT}
      [[ $BTRFS -eq 2 ]] && btrfs_subvols
      # Determine if a seperate /boot is used, and if it is LVM or not
      LVM_SEP_BOOT=0
      if [[ $MOUNT == "/boot" ]]; then
        [[ $MOUNT_TYPE == "/dev/" ]] && LVM_SEP_BOOT=1 || LVM_SEP_BOOT=2
      fi
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
    LVM_PT=$(lvmdiskscan | grep 'LVM physical volume' | grep 'sd[a-z]' | sed 's/\/dev\///' | awk '{print $1}')
    for i in ${LVM_PT}; do
      dd if=/dev/zero bs=512 count=512 of=/dev/${i} >/dev/null 2>&1
    done
  fi
}

# Find and create a list of partitions that can be used for LVM. Partitions already used are excluded.
find_lvm_partitions() {
  LVM_PARTITIONS=""
  NUMBER_LVM_PARTITIONS=0
  lvm_partition_list=$(lvmdiskscan | grep -v 'LVM physical volume' | grep 'sd[a-z][1-99]' | sed 's/\/dev\///' | awk '{print $1}')
  for i in ${lvm_partition_list[@]}; do
    LVM_PARTITIONS="${LVM_PARTITIONS} ${i} -"
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

install_base() {
  DIALOG --title "$_InstBseTitle" \
  --menu "$_InstBseBody" 0 0 4 \
  "1" "$_InstBaseLK" \
  "2" "$_InstBaseLKBD" \
  "3" "$_InstBaseLTS" \
  "4" "$_InstBaseLTSBD" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    # Latest Kernel
    PACSTRAP ${MOUNTPOINT} base btrfs-progs ntp sudo f2fs-tools
    ;;
    "2")
    # Latest Kernel and base-devel
    PACSTRAP ${MOUNTPOINT} base base-devel btrfs-progs ntp sudo f2fs-tools
    ;;
    "3")
    # LTS Kernel
    PACSTRAP ${MOUNTPOINT} $(pacman -Sqg base | sed 's/^linux$/&-lts/')\
     btrfs-progs ntp sudo f2fs-tools
    [[ $? -eq 0 ]] && LTS=1
    ;;
    "4")
    # LTS Kernel and base-devel
    PACSTRAP ${MOUNTPOINT} $(pacman -Sqg base | sed 's/^linux$/&-lts/')\
     base-devel btrfs-progs ntp sudo f2fs-tools
    [[ $? -eq 0 ]] && LTS=1
    ;;
    *)
    install_base_menu
    ;;
  esac
  # If the virtual console has been set, then copy config file to installation
  [[ -e /tmp/vconsole.conf ]] && cp /tmp/vconsole.conf\
   ${MOUNTPOINT}/etc/vconsole.conf 2>>/tmp/.errlog
  check_for_error
  #check for a wireless device
  if [[ $(lspci | grep -i "Network Controller") != "" ]]; then
    DIALOG --title "$_InstWirTitle" --infobox "$_InstWirBody" 0 0
    sleep 2
    PACSTRAP ${MOUNTPOINT} iw wireless_tools wpa_actiond wpa_supplicant\
     dialog
    check_for_error
  fi
}

# Adapted from AIS. Integrated the configuration elements.
install_bootloader() {

  bios_bootloader() {
    DIALOG --title "$_InstBiosBtTitle" \
    --menu "$_InstBiosBtBody" 0 0 3 \
    "1" $"Grub2" \
    "2" $"Syslinux [MBR]" \
    "3" $"Syslinux [/]" 2>${ANSWER}
    case $(cat ${ANSWER}) in
      "1")
      # Grub
      PACSTRAP ${MOUNTPOINT} grub os-prober
      check_for_error
      # An LVM VG/LV can consist of multiple devices. Where LVM used, user must select the device manually.
      if [[ $LVM_ROOT -eq 1 ]]; then
        select_grub_device
      else
        DIALOG --title "$_InstGrubDevTitle" --yesno "$_InstGrubDevBody ($INST_DEV)?$_InstGrubDevBody2" 0 0
        if [[ $? -eq 0 ]]; then
          clear
          DIALOG --title " Grub-install " --infobox "$_PlsWaitBody" 0 0
          sleep 1
          arch_chroot "grub-install --target=i386-pc --recheck ${INST_DEV}" 2>/tmp/.errlog
          check_for_error
        else
          select_grub_device
        fi
      fi
      arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>/tmp/.errlog
      check_for_error
      # if /boot is LVM then amend /boot/grub/grub.cfg accordingly
      if ( [[ $LVM_ROOT -eq 1 ]] && [[ $LVM_SEP_BOOT -eq 0 ]] ) || [[ $LVM_SEP_BOOT -eq 2 ]]; then
        sed -i '/### BEGIN \/etc\/grub.d\/00_header ###/a insmod lvm' ${MOUNTPOINT}/boot/grub/grub.cfg
      fi
      BOOTLOADER="Grub"
      ;;
      "2"|"3")
      # Syslinux
      PACSTRAP ${MOUNTPOINT} syslinux
      # Install to MBR or root partition, accordingly
      [[ $(cat ${ANSWER}) == "2" ]] && arch_chroot "syslinux-install_update -iam" 2>>/tmp/.errlog
      [[ $(cat ${ANSWER}) == "3" ]] && arch_chroot "syslinux-install_update -i" 2>>/tmp/.errlog
      check_for_error
      # Amend configuration file depending on whether lvm used or not for root.
      if [[ $LVM_ROOT -eq 0 ]]; then
        sed -i "s/sda[0-9]/${ROOT_PART}/g" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
      else
        sed -i "s/APPEND.*/APPEND root=\/dev\/mapper\/${ROOT_PART} rw/g" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
      fi
      # Amend configuration file for LTS kernel and/or btrfs subvolume as root
      [[ $LTS -eq 1 ]] && sed -i 's/linux/linux-lts/g' ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
      [[ $BTRFS_MNT != "" ]] && sed -i "s/rw/rw $BTRFS_MNT/g" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
      BOOTLOADER="Syslinux"
      ;;
      *)
      install_base_menu
      ;;
    esac
  }

  uefi_bootloader() {
    #Ensure again that efivarfs is mounted
    [[ -z $(mount | grep /sys/firmware/efi/efivars) ]] && mount -t efivarfs efivarfs /sys/firmware/efi/efivars
    DIALOG --title "$_InstUefiBtTitle" \
    --menu "$_InstUefiBtBody" 0 0 3 \
    "1" $"Grub2" \
    "2" $"rEFInd" \
    "3" $"systemd-boot" 2>${ANSWER}
    case $(cat ${ANSWER}) in
      "1")
      # Grub2
      PACSTRAP ${MOUNTPOINT} grub os-prober efibootmgr dosfstools
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
        PACSTRAP ${MOUNTPOINT} refind-efi efibootmgr dosfstools
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
      PACSTRAP ${MOUNTPOINT} efibootmgr dosfstools
      arch_chroot "bootctl --path=${UEFI_MOUNT} install" 2>>/tmp/.errlog
      check_for_error
      # Deal with LVM Root
      if [[ $LVM_ROOT -eq 0 ]]; then
        sysdb_root=$(blkid -s PARTUUID $"/dev/"${ROOT_PART} | sed 's/.*=//g' | sed 's/"//g')
      else
        sysdb_root="/dev/mapper/${ROOT_PART}"
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

# Needed for broadcom and other network controllers
install_wireless_firmware() {
  check_mount
  DIALOG --title "$_WirelssFirmTitle" --menu "$_WirelssFirmBody" 0 0 8 \
  "1" "$_SeeWirelessDev" \
  "2" $"Broadcom 802.11b/g/n" \
  "3" $"Broadcom BCM203x / STLC2300 Bluetooth" \
  "4" $"Intel PRO/Wireless 2100" \
  "5" $"Intel PRO/Wireless 2200" \
  "6" $"ZyDAS ZD1211(b) 802.11a/b/g USB WLAN" \
  "7" "$_All" \
  "8" "$_Back" 2>${ANSWER}
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
    # Broadcom
    PACSTRAP ${MOUNTPOINT} b43-fwcutter
    ;;
    "3")
    # Bluetooth
    PACSTRAP ${MOUNTPOINT} bluez-firmware
    ;;
    "4")
    # Intel 2100
    PACSTRAP ${MOUNTPOINT} ipw2100-fw
    ;;
    "5")
    # Intel 2200
    PACSTRAP ${MOUNTPOINT} ipw2200-fw
    ;;
    "6")
    # ZyDAS
    PACSTRAP ${MOUNTPOINT} zd1211-firmware
    ;;
    "7")
    # All
    PACSTRAP ${MOUNTPOINT} b43-fwcutter bluez-firmware ipw2100-fw ipw2200-fw\
     zd1211-firmware
    ;;
    *)
    install_base_menu
    ;;
  esac
  check_for_error
  install_wireless_firmware
}

# Install alsa, xorg and input drivers. Also copy the xkbmap configuration file created earlier to the installed system
# This will run only once.
install_alsa_xorg_input() {
  DIALOG --title "$_AXITitle" --msgbox "$_AXIBody" 0 0
  PACSTRAP ${MOUNTPOINT} alsa-utils xorg-server xorg-server-utils xorg-xinit\
   xf86-input-synaptics xf86-input-keyboard xf86-input-mouse
  check_for_error
  # copy the keyboard configuration file, if generated
  [[ -e /tmp/00-keyboard.conf ]] && cp /tmp/00-keyboard.conf ${MOUNTPOINT}/etc/X11/xorg.conf.d/00-keyboard.conf
  # now copy across .xinitrc for all user accounts
  user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
  for i in ${user_list[@]}; do
    cp -f ${MOUNTPOINT}/etc/X11/xinit/xinitrc ${MOUNTPOINT}/home/$i
    arch_chroot "chown -R ${i}:users /home/${i}"
  done
  AXI_INSTALLED=1
}

setup_graphics_card() {

  # Save repetition
  install_intel(){
    PACSTRAP ${MOUNTPOINT} xf86-video-intel libva-intel-driver intel-ucode
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
    PACSTRAP ${MOUNTPOINT} xf86-video-ati
    sed -i 's/MODULES=""/MODULES="radeon"/' ${MOUNTPOINT}/etc/mkinitcpio.conf
  }

  # Main menu. Correct option for graphics card should be automatically highlighted.
  GRAPHIC_CARD=""
  INTEGRATED_GC="N/A"
  GRAPHIC_CARD=$(lspci | grep -i "vga" | sed 's/.*://' | sed 's/(.*//' | sed 's/^[ \t]*//')
  # Highlight menu entry depending on GC detected. Extra work is needed for NVIDIA
  if 	[[ $(echo $GRAPHIC_CARD | grep -i "nvidia") != "" ]]; then
    # If NVIDIA, first need to know the integrated GC
    [[ $(lscpu | grep -i "intel\|lenovo") != "" ]] && INTEGRATED_GC="Intel" || INTEGRATED_GC="ATI"
    # Second, identity the NVIDIA card and driver / menu entry
    if [[ $(dmesg | grep -i 'chipset' | grep -i 'nvc\|nvd\|nve') != "" ]]; then HIGHLIGHT_SUB_GC=4
    elif [[ $(dmesg | grep -i 'chipset' | grep -i 'nva\|nv5\|nv8\|nv9'﻿) != "" ]]; then HIGHLIGHT_SUB_GC=5
    elif [[ $(dmesg | grep -i 'chipset' | grep -i 'nv4\|nv6') != "" ]]; then HIGHLIGHT_SUB_GC=6
    else HIGHLIGHT_SUB_GC=3
    fi
    # All non-NVIDIA cards / virtualisation
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'ati') != "" ]]; then HIGHLIGHT_SUB_GC=1
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'intel\|lenovo') != "" ]]; then HIGHLIGHT_SUB_GC=2
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'via') != "" ]]; then HIGHLIGHT_SUB_GC=7
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'virtualbox') != "" ]]; then HIGHLIGHT_SUB_GC=8
  elif [[ $(echo $GRAPHIC_CARD | grep -i 'vmware') != "" ]]; then HIGHLIGHT_SUB_GC=9
  else HIGHLIGHT_SUB_GC=10
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
    PACSTRAP ${MOUNTPOINT} xf86-video-nouveau
    sed -i 's/MODULES=""/MODULES="nouveau"/' ${MOUNTPOINT}/etc/mkinitcpio.conf
    ;;
    "4")
    # NVIDIA-GF
    [[ $INTEGRATED_GC == "ATI" ]] &&  install_ati || install_intel
    arch_chroot "pacman -Rdds --noconfirm mesa-libgl mesa"
    # Now deal with kernel installed
    [[ $LTS == 0 ]] && PACSTRAP ${MOUNTPOINT} nvidia nvidia-libgl nvidia-utils pangox-compat \
    || PACSTRAP ${MOUNTPOINT} nvidia-lts nvidia-libgl nvidia-utils pangox-compat
    NVIDIA_INST=1
    ;;
    "5")
    # NVIDIA-340
    [[ $INTEGRATED_GC == "ATI" ]] &&  install_ati || install_intel
    arch_chroot "pacman -Rdds --noconfirm mesa-libgl mesa"
    # Now deal with kernel installed
    [[ $LTS == 0 ]] && PACSTRAP ${MOUNTPOINT} nvidia-340xx nvidia-340xx-libgl nvidia-340xx-utils  \
    || PACSTRAP ${MOUNTPOINT} nvidia-340xx-lts nvidia-340xx-libgl nvidia-340xx-utils
    NVIDIA_INST=1
    ;;
    "6")
    # NVIDIA-304
    [[ $INTEGRATED_GC == "ATI" ]] &&  install_ati || install_intel
    arch_chroot "pacman -Rdds --noconfirm mesa-libgl mesa"
    # Now deal with kernel installed
    [[ $LTS == 0 ]] && PACSTRAP ${MOUNTPOINT} nvidia-304xx nvidia-304xx-libgl nvidia-304xx-utils  \
    || PACSTRAP ${MOUNTPOINT}  nvidia-304xx-lts nvidia-304xx-libgl nvidia-304xx-utils
    NVIDIA_INST=1
    ;;
    "7")
    # Via
    PACSTRAP ${MOUNTPOINT} xf86-video-openchrome
    ;;
    "8")
    # VirtualBox
    DIALOG --title "$_VBoxInstTitle" --msgbox "$_VBoxInstBody" 0 0
    [[ $LTS == 0 ]] && PACSTRAP ${MOUNTPOINT} virtualbox-guest-utils virtualbox-guest-modules  \
    || PACSTRAP ${MOUNTPOINT} virtualbox-guest-utils virtualbox-guest-modules-lts
    # Load modules and enable vboxservice whatever the kernel
    arch_chroot "modprobe -a vboxguest vboxsf vboxvideo"
    arch_chroot "systemctl enable vboxservice"
    echo -e "vboxguest\nvboxsf\nvboxvideo" > ${MOUNTPOINT}/etc/modules-load.d/virtualbox.conf
    ;;
    "9")
    # VMWare
    PACSTRAP ${MOUNTPOINT} xf86-video-vmware xf86-input-vmmouse
    ;;
    "10")
    # Generic / Unknown
    PACSTRAP ${MOUNTPOINT} xf86-video-fbdev
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
    DIALOG --title "$_DEInfoTitle" --msgbox "$_DEInfoBody" 0 0
    SHOW_ONCE=1
  fi
  DIALOG --title "$_InstDETitle" \
  --menu "$_InstDEBody" 0 0 11 \
  "1" $"Cinnamon" \
  "2" $"Enlightenment" \
  "3" $"Gnome-Shell (minimal)" \
  "4" $"Gnome" \
  "5" $"Gnome + Extras" \
  "6" $"KDE 5 Base (minimal)" \
  "7" $"KDE 5" \
  "8" $"LXDE" \
  "9" $"LXQT" \
  "10" $"MATE" \
  "11" $"MATE + Extras" \
  "12" $"Xfce" \
  "13" $"Xfce + Extras" \
  "14" $"Awesome WM" \
  "15" $"Fluxbox WM" \
  "16" $"i3 WM" \
  "17" $"Ice WM" \
  "18" $"Openbox WM" \
  "19" $"Pek WM" \
  "20" $"WindowMaker WM" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    # Cinnamon
    PACSTRAP ${MOUNTPOINT} cinnamon xterm
    ;;
    "2")
    # Enlightement
    PACSTRAP ${MOUNTPOINT} enlightenment terminology polkit-gnome xterm
    ;;
    "3")
    # Gnome-Shell
    PACSTRAP ${MOUNTPOINT} gnome-shell gdm xterm
    GNOME_INSTALLED=1
    ;;
    "4")
    # Gnome
    PACSTRAP ${MOUNTPOINT} gnome rp-pppoe xterm
    GNOME_INSTALLED=1
    ;;
    "5")
    # Gnome + Extras
    PACSTRAP ${MOUNTPOINT} gnome gnome-extra rp-pppoe xterm
    GNOME_INSTALLED=1
    ;;
    "6")
    # KDE5 BASE
    PACSTRAP ${MOUNTPOINT} plasma-desktop xdg-utils rp-pppoe xterm
    ;;
    "7")
    # KDE5
    PACSTRAP ${MOUNTPOINT} plasma xdg-user-dirs xdg-utils rp-pppoe xterm
    if [[ $NM_INSTALLED -eq 0 ]]; then
      arch_chroot "systemctl enable NetworkManager.service && systemctl enable NetworkManager-dispatcher.service" 2>>/tmp/.errlog
      NM_INSTALLED=1
    fi
    KDE_INSTALLED=1
    ;;
    "8")
    # LXDE
    PACSTRAP ${MOUNTPOINT} lxde xterm
    LXDE_INSTALLED=1
    ;;
    "9")
    # LXQT
    PACSTRAP ${MOUNTPOINT} lxqt oxygen-icons xterm
    LXQT_INSTALLED=1
    ;;
    "10")
    # MATE
    PACSTRAP ${MOUNTPOINT} mate xterm
    ;;
    "11")
    # MATE + Extras
    PACSTRAP ${MOUNTPOINT} mate mate-extra xterm
    ;;
    "12")
    # Xfce
    PACSTRAP ${MOUNTPOINT} xfce4 polkit-gnome xterm
    ;;
    "13")
    # Xfce + Extras
    PACSTRAP ${MOUNTPOINT} xfce4 xfce4-goodies polkit-gnome xterm
    ;;
    "14")
    # Awesome
    PACSTRAP ${MOUNTPOINT} awesome vicious polkit-gnome xterm
    ;;
    "15")
    #Fluxbox
    PACSTRAP ${MOUNTPOINT} fluxbox fbnews polkit-gnome xterm
    ;;
    "16")
    #i3
    PACSTRAP ${MOUNTPOINT} i3-wm i3lock i3status dmenu polkit-gnome xterm
    ;;
    "17")
    #IceWM
    PACSTRAP ${MOUNTPOINT} icewm icewm-themes polkit-gnome xterm
    ;;
    "18")
    #Openbox
    PACSTRAP ${MOUNTPOINT} openbox openbox-themes polkit-gnome xterm
    ;;
    "19")
    #PekWM
    PACSTRAP ${MOUNTPOINT} pekwm pekwm-themes polkit-gnome xterm
    ;;
    "20")
    #WindowMaker
    PACSTRAP ${MOUNTPOINT} windowmaker polkit-gnome xterm
    ;;
    *)
    install_desktop_menu
    ;;
  esac
  check_for_error
  # Offer to install common packages
  if [[ $COMMON_INSTALLED -eq 0 ]]; then
    DIALOG --title "$_InstComTitle" --yesno "$_InstComBody" 0 0
    if [[ $? -eq 0 ]]; then
      PACSTRAP ${MOUNTPOINT} gksu gnome-keyring polkit xdg-user-dirs xdg-utils gamin gvfs gvfs-afc gvfs-smb ttf-dejavu gnome-icon-theme python2-xdg bash-completion ntfs-3g
      check_for_error
    fi
  fi
  # Either way, the option will no longer be presented.
  COMMON_INSTALLED=1
}

# Determine if LXDE, LXQT, Gnome, and/or KDE has been installed, and act accordingly.
install_dm() {

  # Function to save repetition
  dm_menu(){
    DIALOG --title "$_DmChTitle" \
    --menu "$_DmChBody" 0 0 4 \
    "1" $"LXDM" \
    "2" $"LightDM" \
    "3" $"SDDM" \
    "4" $"SLiM" 2>${ANSWER}
    case $(cat ${ANSWER}) in
      "1")
      # LXDM
      PACSTRAP ${MOUNTPOINT} lxdm
      arch_chroot "systemctl enable lxdm.service" >/dev/null 2>>/tmp/.errlog
      DM="LXDM"
      ;;
      "2")
      # LIGHTDM
      PACSTRAP ${MOUNTPOINT} lightdm lightdm-gtk-greeter
      arch_chroot "systemctl enable lightdm.service" >/dev/null 2>>/tmp/.errlog
      DM="LightDM"
      ;;
      "3")
      # SDDM
      PACSTRAP ${MOUNTPOINT} sddm
      arch_chroot "sddm --example-config > /etc/sddm.conf"
      arch_chroot "systemctl enable sddm.service" >/dev/null 2>>/tmp/.errlog
      DM="SDDM"
      ;;
      "4")
      # SLiM
      PACSTRAP ${MOUNTPOINT} slim
      arch_chroot "systemctl enable slim.service" >/dev/null 2>>/tmp/.errlog
      DM="SLiM"
      # Amend the xinitrc file accordingly for all user accounts
      user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
      for i in ${user_list[@]}; do
        if [[ -n ${MOUNTPOINT}/home/$i/.xinitrc ]]; then
          cp -f ${MOUNTPOINT}/etc/X11/xinit/xinitrc ${MOUNTPOINT}/home/$i/.xinitrc
          arch_chroot "chown -R ${i}:users /home/${i}"
        fi
        echo 'exec $1' >> ${MOUNTPOINT}/home/$i/.xinitrc
      done
      ;;
      *)
      install_desktop_menu
      ;;
    esac
  }

  if [[ $DM_INSTALLED -eq 0 ]]; then
    # Gnome without KDE
    if [[ $GNOME_INSTALLED -eq 1 ]] && [[ $KDE_INSTALLED -eq 0 ]]; then
      arch_chroot "systemctl enable gdm.service" >/dev/null 2>/tmp/.errlog
      DM="GDM"
      # Gnome with KDE
      DIALOG --title "$_DmChTitle" \
    elif [[ $GNOME_INSTALLED -eq 1 ]] && [[ $KDE_INSTALLED -eq 1 ]]; then
      --menu "$_DmChBody" 12 45 2 \
      "1" $"GDM  (Gnome)" \
      "2" $"SDDM (KDE)" 2>${ANSWER}
      case $(cat ${ANSWER}) in
        "1")
        arch_chroot "systemctl enable gdm.service" >/dev/null 2>/tmp/.errlog
        DM="GDM"
        ;;
        "2")
        arch_chroot "sddm --example-config > /etc/sddm.conf"
        arch_chroot "systemctl enable sddm.service" >/dev/null 2>>/tmp/.errlog
        DM="SDDM"
        ;;
        *)
        install_desktop_menu
        ;;
      esac
      # KDE without Gnome
    elif [[ $KDE_INSTALLED -eq 1 ]] && [[ $GNOME_INSTALLED -eq 0 ]]; then
      arch_chroot "sddm --example-config > /etc/sddm.conf"
      arch_chroot "systemctl enable sddm.service" >/dev/null 2>>/tmp/.errlog
      DM="SDDM"
      # LXDM, without KDE or Gnome
    elif [[ $LXDE_INSTALLED -eq 1 ]] && [[ $KDE_INSTALLED -eq 0 ]] && [[ $GNOME_INSTALLED -eq 0 ]]; then
      arch_chroot "systemctl enable lxdm.service" >/dev/null 2>/tmp/.errlog
      DM="LXDM"
      # Otherwise, select a DM
    else
      dm_menu
    fi
    # Check installation success, inform user, and flag DM_INSTALLED so it cannot be run again
    check_for_error
    DIALOG --title " $DM $_DmDoneTitle" --msgbox "\n$DM $_DMDoneBody" 0 0
    DM_INSTALLED=1
    # if A display manager has already been installed and enabled (DM_INSTALLED=1), show a message instead.
  else
    DIALOG --title "$_DmInstTitle" --msgbox "$_DmInstBody" 0 0
  fi
}

install_nm() {
  # Check to see if a NM has already been installed and enabled
  if [[ $NM_INSTALLED -eq 0 ]]; then
    DIALOG --title "$_InstNMTitle" \
    --menu "$_InstNMBody" 0 0 4 \
    "1" $"Connman (CLI)" \
    "2" $"dhcpcd  (CLI)" \
    "3" $"Network Manager (GUI)" \
    "4" $"WICD (GUI)" 2>${ANSWER}
    case $(cat ${ANSWER}) in
      "1")
      # connman
      PACSTRAP ${MOUNTPOINT} connman
      arch_chroot "systemctl enable connman.service" 2>>/tmp/.errlog
      ;;
      "2")
      # dhcpcd
      arch_chroot "systemctl enable dhcpcd.service" 2>/tmp/.errlog
      ;;
      "3")
      # Network Manager
      PACSTRAP ${MOUNTPOINT} networkmanager network-manager-applet rp-pppoe
      arch_chroot "systemctl enable NetworkManager.service && systemctl enable NetworkManager-dispatcher.service" 2>>/tmp/.errlog
      ;;
      "4")
      # WICD
      PACSTRAP ${MOUNTPOINT} wicd-gtk
      arch_chroot "systemctl enable wicd.service" 2>>/tmp/.errlog
      ;;
      *)
      install_desktop_menu
      ;;
    esac
    check_for_error
    DIALOG --title "$_InstNMDoneTitle" --msgbox "$_InstNMDoneBody" 0 0
    NM_INSTALLED=1
  else
    DIALOG --title "$_InstNMDoneTitle" --msgbox "$_InstNMErrBody" 0 0
  fi
}

# Install shell
install_shell() {
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
    PACSTRAP ${MOUNTPOINT} bash
    SH="bash"
    ;;
    "2")
    PACSTRAP ${MOUNTPOINT} dash
    SH="dash"
    ;;
    "3")
    PACSTRAP ${MOUNTPOINT} fish
    SH="fish"
    ;;
    "4")
    PACSTRAP ${MOUNTPOINT} mksh
    SH="mksh"
    ;;
    "5")
    PACSTRAP ${MOUNTPOINT} tcsh
    SH="tcsh"
    ;;
    "6")
    PACSTRAP ${MOUNTPOINT} zsh
    SH="zsh"
    ;;
    *)
    install_add_menu
    ;;
  esac
  if DIALOG --yesno "$_InstShellChsh" 0 0 ; then
    arch _chroot "chsh ${USER} /bin/${SH}"
  fi
  check_for_error
}

install_editor() {
  DIALOG --title "$_InstEditorTitle" \
  --menu "$_InstEditorBody" 0 0 10 \
  "1" "emacs" \
  "2" "emacs without X" \
  "3" "vim" \
  "99" "$_Back" 2>${ANSWER}
  case $(cat ${ANSWER}) in
    "1")
    PACSTRAP ${MOUNTPOINT} emacs
    ;;
    "2")
    PACSTRAP ${MOUNTPOINT} emacs-nox
    ;;
    "3")
    PACSTRAP ${MOUNTPOINT} vim
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
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_PrepTitle" \
  --menu "$_PrepBody" 0 0 7 \
  "1" "$_ConfBseVirtCon" \
  "2" "$_PrepMirror" \
  "3" "$_DevShowOpt" \
  "4" "$_PrepPartDisk" \
  "5" "$_PrepLVM" \
  "6" "$_PrepMntPart" \
  "7" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    set_keymap
    ;;
    "2")
    configure_mirrorlist
    ;;
    "3")
    show_devices
    ;;
    "4")
    umount_partitions
    select_device
    create_partitions
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
    if [[ $HIGHLIGHT_SUB != 5 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  if [ $AUTO == -1 ] && DIALOG --yesno "$_InstAskPac" 0 0 ; then
    AUTO=0
  elif [ $AUTO == -1 ]; then
    AUTO=1
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_InstBsMenuTitle" --menu "$_InstBseMenuBody" 0 0 5 \
  "1" "$_PrepPacKey" \
  "2" "$_InstBse" \
  "3" "$_InstBootldr" \
  "4" "$_InstWirelessFirm" \
  "5" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    clear
    pacman-key --init
    pacman-key --populate archlinux
    pacman-key --refresh-keys
    ;;
    "2")
    install_base
    ;;
    "3")
    install_bootloader
    ;;
    "4")
    install_wireless_firmware
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
    if [[ $HIGHLIGHT_SUB != 7 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_ConfBseTitle" --menu "$_ConfBseBody" 0 0 7 \
  "1" "$_ConfBseFstab" \
  "2" "$_ConfBseHost" \
  "3" "$_ConfBseTime" \
  "4" "$_ConfBseHWC" \
  "5" "$_ConfBseSysLoc" \
  "6" "$_PrepKBLayout" \
  "7" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    generate_fstab
    ;;
    "2")
    set_hostname
    ;;
    "3")
    set_timezone
    ;;
    "4")
    set_hw_clock
    ;;
    "5")
    set_locale
    ;;
    "6")
    set_xkbmap
    ;;
    *)
    main_menu_online
    ;;
  esac
  config_base_menu
}

# Root and User Configuration
config_user_menu() {
  if [[ $SUB_MENU != "config_user_menu" ]]; then
    SUB_MENU="config_user_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 3 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_ConfUsrTitle" --menu "$_ConfUsrBody" 0 0 3 \
  "1" "$_ConfUsrRoot" \
  "2" "$_ConfUsrNew" \
  "3" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    set_root_password
    ;;
    "2")
    create_new_user
    ;;
    *)
    main_menu_online
    ;;
  esac
  config_user_menu
}

install_desktop_menu() {
  if [[ $SUB_MENU != "install_deskop_menu" ]]; then
    SUB_MENU="install_deskop_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 5 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_InstDEMenuTitle" \
  --menu "$_InstDEMenuBody" 0 0 5 \
  "1" "$_InstDEMenuGISD" \
  "2" "$_InstDEMenuDE" \
  "3" "$_InstDEMenuNM" \
  "4" "$_InstDEMenuDM" \
  "5" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    [[ AXI_INSTALLED -eq 0 ]] && install_alsa_xorg_input
    setup_graphics_card
    ;;
    "2")
    install_de_wm
    ;;
    "3")
    install_nm
    ;;
    "4")
    install_dm
    ;;
    *)
    main_menu_online
    ;;
  esac
  install_desktop_menu
}

# Install Accessibility Applications
install_acc_menu() {
  if [[ $SUB_MENU != "install_acc_menu" ]]; then
    SUB_MENU="install_acc_menu"
    HIGHLIGHT_SUB=1
  else
    if [[ $HIGHLIGHT_SUB != 17 ]]; then
      HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
    fi
  fi
  DIALOG --default-item ${HIGHLIGHT_SUB} --title "$_InstAccTitle" --menu "$_InstAccBody" 0 0 17 \
  "1" $"accerciser" \
  "2" $"at-spi2-atk" \
  "3" $"at-spi2-core" \
  "4" $"brltty" \
  "5" $"caribou" \
  "6" $"dasher" \
  "7" $"espeak" \
  "8" $"espeakup" \
  "9" $"festival" \
  "10" $"java-access-bridge" \
  "11" $"java-atk-wrapper" \
  "12" $"julius" \
  "13" $"orca" \
  "14" $"qt-at-spi" \
  "15" $"speech-dispatcher" \
  "16" "$_All" \
  "17" "$_Back" 2>${ANSWER}
  HIGHLIGHT_SUB=$(cat ${ANSWER})
  case $(cat ${ANSWER}) in
    "1")
    # accerciser
    PACSTRAP ${MOUNTPOINT} accerciser
    ;;
    "2")
    # at-spi2-atk
    PACSTRAP ${MOUNTPOINT} at-spi2-atk
    ;;
    "3")
    # at-spi2-core
    PACSTRAP ${MOUNTPOINT} at-spi2-core
    ;;
    "4")
    # brltty
    PACSTRAP ${MOUNTPOINT} brltty
    ;;
    "5")
    # caribou
    PACSTRAP ${MOUNTPOINT} caribou
    ;;
    "6")
    # dasher
    PACSTRAP ${MOUNTPOINT} dasher
    ;;
    "7")
    # espeak
    PACSTRAP ${MOUNTPOINT} espeak
    ;;
    "8")
    # espeakup
    PACSTRAP ${MOUNTPOINT} espeakup
    ;;
    "9")
    # festival
    PACSTRAP ${MOUNTPOINT} festival
    ;;
    "10")
    # java-access-bridge
    PACSTRAP ${MOUNTPOINT} java-access-bridge
    ;;
    "11")
    # java-atk-wrapper
    PACSTRAP ${MOUNTPOINT} java-atk-wrapper
    ;;
    "12")
    # julius
    PACSTRAP ${MOUNTPOINT} julius
    ;;
    "13")
    # orca
    PACSTRAP ${MOUNTPOINT} orca
    ;;
    "14")
    # qt-at-spi
    PACSTRAP ${MOUNTPOINT} qt-at-spi
    ;;
    "15")
    # speech-dispatcher
    PACSTRAP ${MOUNTPOINT} speech-dispatcher
    ;;
    "16")
    # install all
    PACSTRAP ${MOUNTPOINT} accerciser at-spi2-atk at-spi2-core brltty dasher espeak espeakup festival java-access-bridge caribou julius orca qt-at-spi speech-dispatcher
    ;;
    *)
    main_menu_online
    ;;
  esac
  check_for_error
  install_acc_menu
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
    #install_editor TODO
    ;;
    "3")
    #install_browser TODO
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
  "8" "$BOOTLOADER" \
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
    case $BOOTLOADER in
      "Grub")
      FILE="${MOUNTPOINT}/etc/default/grub"
      ;;
      "Syslinux")
      FILE="${MOUNTPOINT}/boot/syslinux/syslinux.cfg"
      ;;
      "systemd-boot")
      FILE="${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/arch.conf"
      FILE2="${MOUNTPOINT}${UEFI_MOUNT}/loader/loader.conf"
      ;;
      "rEFInd")
      [[ -e ${MOUNTPOINT}${UEFI_MOUNT}/EFI/refind/refind.conf ]] \
      && FILE="${MOUNTPOINT}${UEFI_MOUNT}/EFI/refind/refind.conf" || FILE="${MOUNTPOINT}${UEFI_MOUNT}/EFI/BOOT/refind.conf"
      FILE2="${MOUNTPOINT}/boot/refind_linux.conf"
      ;;
    esac
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
    DIALOG --title "$_SeeConfErrTitle" --msgbox "$_SeeConfErrBody1" 0 0
  fi
  edit_configs
}

main_menu_online() {
  if [[ $HIGHLIGHT != 8 ]]; then
    HIGHLIGHT=$(( HIGHLIGHT + 1 ))
  fi
  DIALOG --default-item ${HIGHLIGHT} --title "$_MMTitle" \
  --menu "$_MMBody" 0 0 9 \
  "1" "$_MMPrep" \
  "2" "$_MMInstBse" \
  "3" "$_MMConfBse" \
  "4" "$_MMConfUsr" \
  "5" "$_MMInstDE" \
  "6" "$_InstAccOpt" \
  "7" "$_MMAddSoft" \
  "8" "$_MMRunMkinit" \
  "9" "$_SeeConfOpt" \
  "10" "$_Done" 2>${ANSWER}
  HIGHLIGHT=$(cat ${ANSWER})
  # Depending on the answer, first check whether partition(s) are mounted and whether base has been installed
  if [[ $(cat ${ANSWER}) -eq 2 ]]; then
    check_mount
  fi
  if [[ $(cat ${ANSWER}) -ge 3 ]] && [[ $(cat ${ANSWER}) -le 8 ]]; then
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
    config_user_menu
    ;;
    "5")
    install_desktop_menu
    ;;
    "6")
    install_acc_menu
    ;;
    "7")
    install_add_menu
    ;;
    "8")
    run_mkinitcpio
    ;;
    "9")
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
