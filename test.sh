#!/bin/bash

if mount | grep "/Volumes/Darius" > /dev/null; then
  echo "1"
else
  echo "0"
fi
