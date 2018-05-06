#!/bin/bash
function initialize {
  read -p "Enter the path to the mount point of the backup disk: " LOCALMOUNTPOINT
  read -p "Enter the path to a temp directory to be used. It should not be shared with anything else: " TMPDIRPATH
  read -p "Enter the path to the HOME directory on the phone: " PHONESRC
  read -p "Enter the path to your copy of adb: " ADBPATH
  echo $LOCALMOUNTPOINT > ./.backup.sh.vars.LOCALMOUNTPOINT
  echo $TMPDIRPATH > ./.backup.sh.vars.TMPDIRPATH
  echo $PHONESRC > ./.backup.sh.vars.PHONESRC
  echo $ADBPATH > ./.backup.sh.vars.ADBPATH
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
  echo "Type in necessary paths. Paths should be from the root"
  initialize
fi

if ls -a | grep "backup.sh.vars" > /dev/null; then
    declare -p LOCALMOUNTPOINT TMPDIRPATH PHONESRC > ./backup.sh.vars
else
  initialize
fi


if ls -al ~ | grep "$TMPDIRPATH" > /dev/null; then
    echo "temp directory exists at $TMPDIRPATH"
else
    mkdir $TMPDIRPATH
    echo "temp directory created at $TMPDIRPATH"
fi

if mount | grep "on $LOCALMOUNTPOINT" > /dev/null; then
  echo "Backup drive is mounted"
  if($ADBPATH devices); then
    echo "Phone is connected"
  else
    echo "Please plug in phone and ensure adb is enabled"
    exit;
  fi
  echo "Beginning to copy files, this will take a while"
  $ADBPATH pull $PHONESRC $TMPDIRPATH
  echo "Files copied, now creating and transfering to disk image. The adb error is normal."
  echo "It is now safe to unplug the phone"
  TODAY=`date '+%Y-%m-%d'`;
  for D in `find $TMPDIRPATH -type d`
  do
    hdiutil create -encryption -stdinpass -srcfolder $TMPDIRPATH/$D $TMPDIRPATH/$TODAY.dmg
    echo "Disk image created"
    echo "Deleting temporary folder"
    rm -rf $TMPDIRPATH/$D
  done
  sudo mv $TMPDIRPATH/$TODAY.dmg $LOCALMOUNTPOINT
  echo "Backup finished. It is now safe to eject the backup drive"
else
  echo "Please insert the backup drive"
fi
exit;
