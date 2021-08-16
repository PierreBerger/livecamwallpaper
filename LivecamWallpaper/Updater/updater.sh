#!/bin/bash

#see https://github.com/exelban/stats/blob/4351d25a222d00bfe8d74b5a169998c9aa6d4dfc/Kit/scripts/updater.sh

DMG_PATH="$HOME/Library/Containers/fr.pierreberger.LivecamWallpaper/Data/Documents/LivecamWallpaper.dmg"
MOUNT_PATH="/tmp/LivecamWallpaper"
APPLICATION_PATH="/Applications/"

echo "script started"

while [[ "$#" > 0 ]]; do case $1 in
  -d|--dmg) DMG_PATH="$2"; shift;;
  -a|--app) APPLICATION_PATH="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

rm -rf $APPLICATION_PATH/LivecamWallpaper.app
cp -rf $MOUNT_PATH/LivecamWallpaper.app $APPLICATION_PATH/LivecamWallpaper.app

$APPLICATION_PATH/LivecamWallpaper.app/Contents/MacOS/LivecamWallpaper --dmg-path "$DMG_PATH" --mount-path "$MOUNT_PATH"

echo "New version started"

