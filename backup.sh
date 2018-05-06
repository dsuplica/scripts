#!/bin/bash
if (ls -a ~/Library/dsscripts/backup.sh) && (ls -a ~/Library/dsscripts/backup.sh/TMP); then
  echo "necessary directories exist"
else
  mkdir ~/Library/dsscripts/
  mkdir ~/Library/dsscripts/backup.sh/
  mkdir ~/Library/dsscripts/backup.sh/TMP
  echo "Necessary directories created"
fi

DIR="~/Library/dsscripts/backup.sh"

function initialize {
  echo "Type in necessary paths. Paths should be from the root"
  read -p "Enter the path to the mount point of the backup disk: " MTPT
  read -p "Enter the path to the HOME directory on the phone: " PHONESRC
  read -p "Enter the path to your copy of adb: " ADBPATH
  echo $MTPT > $DIR/MTPT.var
  echo $PHONESRC > $DIR/PHONESRC.var
  echo $ADBPATH > $DIR/ADBPATH.var
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

if ls -a $DIR| grep "MTPT.var" && grep "PHONESRC.var" && grep "ADBPATH.var" > /dev/null; then
  declare -p MTPT > $DIR/MTPT.var
  declare -p PHONESRC > $DIR/PHONESRC.var
  declare -p ADBPATH > $DIR/ADBPATH.var
else
  initialize
fi

TMPPATH="$DIR/TMP"

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
  echo "Please enter your password"
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
