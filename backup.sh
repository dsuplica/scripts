#!/bin/bash

LOCALMOUNTPOINT="/Volumes/Darius"

if mount | grep "on $LOCALMOUNTPOINT" > /dev/null; then
    echo "Backup drive is mounted"
    echo "Beginning to copy files, this will take a while"
    /Users/dariussuplica/android/adb pull /storage/emulated/0 ~/TMP
    echo "Files copied, now creating and transfering to disk image. The adb error is normal."
    echo "It is now safe to unplug the phone"
    today=`date '+%Y-%m-%d'`;
    hdiutil create -encryption -stdinpass -srcfolder ~/TMP/0 ~/TMP/$today.dmg
    echo "Disk image created, This operation will use sudo"
    sudo mv ~/TMP/$today.dmg /Volumes/Darius
    echo "Deleting temporary folder"
    rm -rf ~/TMP/0
    echo "Backup finished. It is now safe to eject the backup drive"
else
    echo "Please insert the backup drive"
fi
exit;
