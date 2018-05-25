#!/bin/bash
bkpt="/Volumes/Darius"
if (~/android/adb devices &> /dev/null); then
  echo "1"
else
  echo "0"
fi
