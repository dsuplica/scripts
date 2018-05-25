#!/bin/bash
#TODO: no longer require a mounted drive, work with folder instead
if (ls -a ~/.dsscripts/backup.sh) && (ls -a ~/.dsscripts/backup.sh/TMP); then
  echo "necessary directories exist"
else
  mkdir ~/.dsscripts/
  mkdir ~/.dsscripts/backup.sh/
  mkdir ~/.dsscripts/backup.sh/TMP
  echo "Necessary directories created"
fi


function initialize {
  if [ "$1" == "mtpt" ]; then
    read -p "Enter the path to the mount point of the backup disk: " MTPT
    echo $MTPT > ~/.dsscripts/backup.sh/MTPT
  elif [ "$1" == "phonesrc" ]; then
    read -p "Enter the path to the HOME directory on the phone: " PHONESRC
    echo $PHONESRC > ~/.dsscripts/backup.sh/PHONESRC
  elif [ "$1" == "adbpath" ]; then
    read -p "Enter the path to your copy of adb: " ADBPATH
    echo $ADBPATH > ~/.dsscripts/backup.sh/ADBPATH
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
  echo "Usage: backup.sh [- h,s] [options]"
  echo " -h, --help: displays this text"
  echo " -s: sets variables even if the already exist"
  echo "with -s, type mtpt to set the drive mount point, phonesrc to set the directory on the phone to back up from, and adbpath to set the path to your copy of adb"
  echo "or with no arguments to set all 3"
  exit;
}
if [ "$1" == "-h" ]; then
  help;
elif [ "$1" == "--help" ]; then
  help;
fi

if [ "$1" == "-s" ]; then
  if [$2 > /dev/null ]; then
    initialize "$2"
  else
    CONT="1"
    initialize mtpt
    initialize phonesrc
    unset CONT
    initialize adbpath
  fi
fi

function checkfiles {
if [ -f ~/.dsscripts/backup.sh/$1 ]; then
   return;
else
   initialize;
fi
}

checkfiles "MTPT"
checkfiles "PHONESRC"
checkfiles "ADBPATH"
MTPT=$(cat ~/.dsscripts/backup.sh/MTPT)
PHONESRC=$(cat ~/.dsscripts/backup.sh/PHONESRC)
ADBPATH=$(cat ~/.dsscripts/backup.sh/ADBPATH)


if (ls -a ~/.dsscripts/backup.sh/TMP); then
    echo "temp directory exists at ~/.dsscripts/backup.sh/TMP"
else
    mkdir ~/.dsscripts/backup.sh/TMP
    echo "temp directory created at ~/.dsscripts/backup.sh/TMP"
fi
if mount | grep "on $MTPT" > /dev/null; then
  echo "Backup drive is mounted"
  if ($ADBPATH devices); then
    echo "Phone is connected" > /dev/null
  else
    echo "Please plug in phone and ensure adb is enabled"
    exit;
  fi

  echo "clearing tmp"
  sudo rm -rf ~/.dsscripts/backup.sh/TMP/*
  echo "Beginning to copy files, this will take a while"
#  sudo /Users/dariussuplica/android/adb pull /storage/emulated/0 ~/.dsscripts/backup.sh/TMP
   sudo $ADBPATH pull $PHONESRC ~/.dsscripts/backup.sh/TMP
  echo "Files copied, now creating and transfering to disk image."
  echo "It is now safe to unplug the phone"
  TODAY=`date '+%Y-%m-%d'`;
  #TODO - work with folders not named "0"
  SRC="~/.dsscripts/backup.sh/TMP/0"
  DESTINATION="~/.dsscripts/backup.sh/TMP/$TODAY.dmg"
  echo "Source is $SRC"
  echo "Destination is $DESTINATION"
#  hdiutil create -encryption -stdinpass -srcfolder ~/.dsscripts/backup.sh/TMP/0 ~/.dsscripts/backup.sh/TMP/2018-05-06.dmg
  sudo touch $DESTINATION
  echo "hdiutil create -encryption -stdinpass -srcfolder $SRC $DESTINATION"
#  CMD="hdiutil create -encryption -stdinpass -srcfolder $SRC $DESTINATION"
#  sudo $CMD
  sudo hdiutil create -encryption -stdinpass -srcfolder ~/.dsscripts/backup.sh/TMP/0 ~/.dsscripts/backup.sh/TMP/$TODAY.dmg
  SRC="~/.dsscripts/backup.sh/TMP/$TODAY.dmg"
  DESTINATION="$MTPT/$TODAY.dmg"
  sudo touch $DESTINATION
#DEB  echo "mv $SRC $DESTINATION"
#DEB  CMD="mv $SRC $DESTINATION"
#DEB  sudo $CMD
  sudo mv ~/.dsscripts/backup.sh/TMP/$TODAY.dmg $MTPT/$TODAY.dmg
  echo "Backup finished. It is now safe to eject the backup drive"
else
  echo "Please insert the backup drive"
fi
exit;
