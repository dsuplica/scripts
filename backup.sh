#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script with as root" 1>&2
   exit;
fi
if (! ls -a ~/.dsscripts/backup.sh > /dev/null) && (! ls -a ~/.dsscripts/backup.sh/TMP > /dev/null); then
  mkdir ~/.dsscripts/
  mkdir ~/.dsscripts/backup.sh/
  mkdir ~/.dsscripts/backup.sh/TMP
fi


function initializevars {
  if [ "$1" == "BKPT" ]; then
    read -p "Enter the path to disk or directory to back up to: " BKPT
    echo $BKPT > ~/.dsscripts/backup.sh/BKPT
  elif [ "$1" == "PHONESRC" ]; then
    read -p "Enter the path to the HOME directory on the phone: " PHONESRC
    echo $PHONESRC > ~/.dsscripts/backup.sh/PHONESRC
  elif [ "$1" == "SDKPATH" ]; then
    read -p "Enter the path to your copy of the sdk. It should include both adb and fastboot: " SDKPATH
    echo $SDKPATH > ~/.dsscripts/backup.sh/SDKPATH
  elif [ "$1" == "TWRPPATH" ]; then
    read -p "Enter the path to your copy of TWRP: " TWRPPATH
    echo $TWRPPATH > ~/.dsscripts/backup.sh/TWRPPATH
  else
    echo "option not recognized. Run with the option -h or --help to see "
  fi
  if [ $CONT ]; then
    return;
  else
    exit;
  fi
}


if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "This script should be run using sudo"
  echo "Usage: backup.sh [- h,s] [options]"
  echo " -h, --help: displays help text"
  echo " -s, --set: sets variables even if the already exist"
  echo "with -s or --set, type BKPT to set the directory to back up to, PHONESRC to set the directory on the phone to back up from, SDKPATH to set the path to your copy of the sdk, and TWRPPATH to set the path to your local copy of TWRP"
  echo "or with no arguments to set all 4"
  echo " -d, --delaydmg: sets a delay period before creating the disk image in minutes. Use this to prevent high CPU usage when the computer is in use."
  echo "follow up with either 'm' or 'h' to select a duration in minutes or hours, respectively. Unless one of these is specified the time will default to seconds "
  exit;
fi


if [ "$1" == "-s" ] || [ "$1" == "--set" ]; then
  if [ "$2" > /dev/null ]; then
    unset CONT
    initializevars "$2"
  else
    CONT="1"
    initializevars BKPT
    initializevars PHONESRC
    initializevars TWRPPATH
    unset CONT
    initializevars SDKPATH
  fi
  exit;
fi

if [ "$1" == "-d" ] || [ "$1" == "--delaydmg" ]; then
  if ["$2" == "m"]; then
    DELAY=$((60*$3))
  elif ["$2" == "h"]; then
    DELAY=$((3600*$3))
  elif [$2 -gt 0]; then
    DELAY=$2
  else
    echo "Invalid input to delay time"
    exit;
  fi
fi

function checkfiles {
if [ -f ~/.dsscripts/backup.sh/$1 ]; then
   return;
else
   initializevars $1;
    if [ $CONT ]; then
      return
    else
      exit
    fi
  fi
}
CONT="1"
checkfiles "BKPT"
checkfiles "PHONESRC"
checkfiles "TWRPPATH"
unset CONT
checkfiles "SDKPATH"
BKPT=$(cat ~/.dsscripts/backup.sh/BKPT)
PHONESRC=$(cat ~/.dsscripts/backup.sh/PHONESRC)
TWRPPATH=$(cat ~/.dsscripts/backup.sh/TWRPPATH)
SDKPATH=$(cat ~/.dsscripts/backup.sh/SDKPATH)

function pause {
  read -p "Press enter to continue"
}

function checkplugged {
  if (! $SDKPATH/adb devices > /dev/null); then
    echo "Please ensure the phone is plugged in and usb debugging is enabled"
    pause
    checkplugged
  else
    return
  fi
}
unset CONT
function getpasswd {
  while [[ ! $CONT ]]; do
    read -sp "Enter disk image passphrase: " DMGPASSPHRASE1
    echo " "
    read -sp "Enter again: " DMGPASSPHRASE2
    if [ $DMGPASSPHRASE1 == $DMGPASSPHRASE2 ]; then
      DMGPASSPHRASE=$DMGPASSPHRASE1
      CONT="1"
    fi
  done
}

#DEBUG
NOTWRP="0"
DELAY="0"
#/DEBUG
if (! ls -a ~/.dsscripts/backup.sh/TMP > /dev/null); then
    mkdir ~/.dsscripts/backup.sh/TMP
fi
if (ls $BKPT > /dev/null); then
  if [ ! $NOTWRP ]; then
    if (! $SDKPATH/fastboot devices > /dev/null); then
      echo "Please plug in ONE phone booted to the bootloader (The bootloader should be unlocked)"
      exit;
    fi
    $SDKPATH/fastboot boot $TWRPPATH
    echo "You may now unplug the phone. Once you have completed performing a local backup, plug it back in. Once you are done,"
    pause
  fi
  checkplugged
  #!!!:  THIS MIGHT BE A HUGE VULNERABILITY
  getpasswd
  sudo rm -rf ~/.dsscripts/backup.sh/TMP/*
  echo " "
  echo "Beginning to copy files, this will take a while"
  sudo $SDKPATH/adb pull $PHONESRC ~/.dsscripts/backup.sh/TMP
  echo "Files copied, it is now safe to unplug the phone."
  TODAY=`date '+%Y-%m-%d'`;
  sleep $DELAY
  printf '%s' $DMGPASSPHRASE | hdiutil create -encryption -stdinpass -volname $TODAY -srcfolder ~/.dsscripts/backup.sh/TMP/* ~/.dsscripts/backup.sh/TMP/$TODAY.dmg
  sudo touch $BKPT/$TODAY.dmg
  sudo mv ~/.dsscripts/backup.sh/TMP/$TODAY.dmg $BKPT/$TODAY.dmg
  echo "Backup finished."
else
  echo "Please ensure the backup folder exists. If you are backing up to a drive, ensure it is mounted."
fi
exit;
