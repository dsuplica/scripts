#!/bin/bash
#TODO: no longer require a mounted drive, work with folder instead
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script with sudo" 1>&2
   exit;
fi
if (! ls -a ~/.dsscripts/backup.sh > /dev/null) && (! ls -a ~/.dsscripts/backup.sh/TMP > /dev/null); then
  mkdir ~/.dsscripts/
  mkdir ~/.dsscripts/backup.sh/
  mkdir ~/.dsscripts/backup.sh/TMP
fi


function initialize {
  if [ "$1" == "bkpt" ]; then
    read -p "Enter the path to disk or directory to back up to: " bkpt
    echo $bkpt > ~/.dsscripts/backup.sh/bkpt
  elif [ "$1" == "phonesrc" ]; then
    read -p "Enter the path to the HOME directory on the phone: " phonesrc
    echo $phonesrc > ~/.dsscripts/backup.sh/phonesrc
  elif [ "$1" == "adbpath" ]; then
    read -p "Enter the path to your copy of adb: " adbpath
    echo $adbpath > ~/.dsscripts/backup.sh/adbpath
  else
    echo "option not recognized. Run with the option -h or --help to see "
  fi
  if [ $CONT ]; then
    return;
  else
    exit;
  fi
}

function help {
  echo "This script should be run using sudo"
  echo "Usage: backup.sh [- h,s] [options]"
  echo " -h, --help: displays this text"
  echo " -s: sets variables even if the already exist"
  echo "with -s, type bkpt to set the directory to back up to, phonesrc to set the directory on the phone to back up from, and adbpath to set the path to your copy of adb"
  echo "or with no arguments to set all 3"
  exit;
}
if [ "$1" == "-h" ]; then
  help;
elif [ "$1" == "--help" ]; then
  help;
fi

if [ "$1" == "-s" ]; then
  if ["$2" > /dev/null ]; then
    initialize "$2"
  else
    CONT="1"
    initialize bkpt
    initialize phonesrc
    unset CONT
    initialize adbpath
  fi
fi

function checkfiles {
if [ -f ~/.dsscripts/backup.sh/$1 ]; then
   return;
else
   initialize $1;
fi
}
CONT="1"
checkfiles "bkpt"
checkfiles "phonesrc"
unset CONT
checkfiles "adbpath"
bkpt=$(cat ~/.dsscripts/backup.sh/bkpt)
phonesrc=$(cat ~/.dsscripts/backup.sh/phonesrc)
adbpath=$(cat ~/.dsscripts/backup.sh/adbpath)


if (! ls -a ~/.dsscripts/backup.sh/TMP > /dev/null); then
    mkdir ~/.dsscripts/backup.sh/TMP
fi
if (ls $bkpt > /dev/null); then
  if (! $adbpath devices > /dev/null); then
    echo "Please plug in ONE phone and ensure adb is enabled"
    exit;
  fi
  sudo rm -rf ~/.dsscripts/backup.sh/TMP/*
  echo "Beginning to copy files, this will take a while"
  sudo $adbpath pull $phonesrc ~/.dsscripts/backup.sh/TMP
  echo "Files copied, it is now safe to unplug the phone."
  TODAY=`date '+%Y-%m-%d'`;
  sudo hdiutil create -encryption -stdinpass -srcfolder ~/.dsscripts/backup.sh/TMP/* ~/.dsscripts/backup.sh/TMP/$TODAY.dmg
  SRC="~/.dsscripts/backup.sh/TMP/$TODAY.dmg"
  DESTINATION="$bkpt/$TODAY.dmg"
  sudo touch $DESTINATION
  sudo mv ~/.dsscripts/backup.sh/TMP/$TODAY.dmg $bkpt/$TODAY.dmg
  echo "Backup finished."
else
  echo "Please ensure the backup folder exists. If you are backing up to a drive, ensure it is mounted."
fi
exit;
