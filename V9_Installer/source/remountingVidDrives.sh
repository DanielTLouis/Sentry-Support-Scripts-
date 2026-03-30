#!/bin/bash
## By Daniel ##
## remountingVidDrives ##

remountingVidDrives() {
  # Extract unique videoXX entries from the settings XML
  unique_videos=($(grep -oP 'video\d+' /usr/vcs/cfg/settings.xml | sort -u))

  echo "Unique video entries: ${unique_videos[@]}"

  # Ensure /mnt exists
  if ! [ -d "/mnt" ]; then
    echo "Creating /mnt directory..."
    sudo mkdir /mnt
  fi

  for video in "${unique_videos[@]}"; do
    echo "Processing /$video..."

    # Try to find the device currently mounted at /$video
    DEVICE=$(findmnt -n -o SOURCE --target /$video 2>/dev/null)

    if [ -z "$DEVICE" ]; then
      echo "⚠️  No device found mounted at /$video. Skipping."
      continue
    fi

    # Attempt to unmount /$video
    if mountpoint -q /$video; then
      echo "Unmounting /$video..."
      sudo umount /$video || {
        echo "❌ Failed to unmount /$video. Skipping remount."
        continue
      }
    else
      echo "/$video is not mounted."
    fi

    # Create target mount point
    sudo mkdir -p /mnt/$video

    # Remount
    echo "Mounting $DEVICE to /mnt/$video..."
    sudo mount "$DEVICE" /mnt/$video || echo "❌ Failed to mount $DEVICE to /mnt/$video"
  done

  echo "✅ All applicable video drives remounted under /mnt."
}
