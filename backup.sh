#!/bin/bash
if (ls -a ~/Library/dsscripts/backup.sh) && (ls -a ~/Library/dsscripts/backup.sh/TMP); then
  echo "necessary directories exist"
else
  mkdir ~/Library/dsscripts/
  mkdir ~/Library/dsscripts/backup.sh/
  mkdir ~/Library/dsscripts/backup.sh/TMP
  echo "Necessary directories created"
fi


function initialize {
  echo "Type in necessary paths. Paths should be from the root"
  read -p "Enter the path to the mount point of the backup disk: " MTPT
  read -p "Enter the path to the HOME directory on the phone: " PHONESRC
  read -p "Enter the path to your copy of adb: " ADBPATH
  echo $MTPT > ~/Library/dsscripts/backup.sh/MTPT
  echo $PHONESRC > ~/Library/dsscripts/backup.sh/PHONESRC
  echo $ADBPATH > ~/Library/dsscripts/backup.sh/ADBPATH
  return;
}

if [ "$1" == "-h" ]; then
  echo "Usage: ./backup.sh [- h,i]"
  echo "This program takes no inputs"
  echo " -h: displays this text"
  echo " -i: sets variables even if the already exist"
  exit;
fi

if [ "$1" == "-i" ]; then
  initialize
fi

function checkfiles {
if [ -f ~/Library/dsscripts/backup.sh/$1 ]; then
   return;
else
   initialize;
fi
}

checkfiles "MTPT"
checkfiles "PHONESRC"
checkfiles "MTPT"
MTPT=$(cat ~/Library/dsscripts/backup.sh/MTPT)
PHONESRC=$(cat ~/Library/dsscripts/backup.sh/PHONESRC)
ADBPATH=$(cat ~/Library/dsscripts/backup.sh/ADBPATH)


TMPPATH="~/Library/dsscripts/backup.sh/TMP"
if ls -al ~ | grep "$TMPPATH" > /dev/null; then
    echo "temp directory exists at $TMPPATH"
else
    mkdir $TMPPATH
    echo "temp directory created at $TMPPATH"
fi
if mount | grep "on $MTPT" > /dev/null; then
  echo "Backup drive is mounted"
  if($ADBPATH devices); then
    echo "Phone is connected"
  else
    echo "Please plug in phone and ensure adb is enabled"
    exit;
  fi

  echo "Beginning to copy files, this will take a while"
  sudo /Users/dariussuplica/android/adb pull /storage/emulated/0 ~/Library/dsscripts/backup.sh/TMP
  sudo $ADBPATH pull $PHONESRC $TMPPATH
  echo "Files copied, now creating and transfering to disk image. The adb error is normal."
  echo "It is now safe to unplug the phone"
  TODAY=`date '+%Y-%m-%d'`;

  for D in `find $TMPPATH -type d`
  do
    hdiutil create -encryption -stdinpass -srcfolder $TMPPATH/$D $TMPPATH/$TODAY.dmg
    echo "Disk image created"
    echo "Deleting temporary folder"
    rm -rf $TMPPATH/$D
  done

  sudo mv $TMPPATH/$TODAY.dmg $MTPT
  echo "Backup finished. It is now safe to eject the backup drive"
else
  echo "Please insert the backup drive"
fi
exit;
