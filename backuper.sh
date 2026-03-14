#!/bin/bash

# SPDX-FileCopyrightText: 2026 Tirth Kavathiya <tirthkavathiya@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

sudo -v

s_dirs=7
mount_dir=/run/media/foxtrot/Ventoy/Data
b_dirs=( "$HOME/Documents" "$HOME/Pictures" "$HOME/Files/College" "$HOME/Files/3D" "$HOME/Files/Org-Nest" "$HOME/Books" "$HOME/Files/Godot/ProjectFiles" )

run_syncthing() {
    echo "Starting Syncthing in background..."
    apikey=$(xmllint --xpath 'string(//apikey)' "$HOME/.local/state/syncthing/config.xml")

    # This function checks that if syncthing is connected to any of the devices (currently i have only one device)
    s_connection() {
        curl -s -H "X-API-Key: $apikey" http://127.0.0.1:8384/rest/system/connections | jq '.connections.[].connected'
    }
    # This function checks the sync completion latest data for each folder and returns the number of folders who are completed
    s_completion() {
	curl -s -H "X-API-Key: $apikey" http://127.0.0.1:8384/rest/events | jq 'map(select(.type == "FolderCompletion")) | sort_by(.time) | reverse | unique_by(.data.folder) | map(select(.data.completion == 100)) | length'
    }
    
    s_shutdown() {
        curl -X POST -H "X-API-Key: $apikey" http://127.0.0.1:8384/rest/system/shutdown
    }

    syncthing --no-browser > /dev/null 2>&1 &

    sleep 5
    echo "Waiting for Syncthing to establish connection..."
    while [ "$(s_connection)" != "true" ]; do
        sleep 5
    done

    echo "Syncthing connected successfully."
    sleep 10

    echo "Waiting for Syncthing sync to complete..."
    while [ "$(s_completion)" != "$s_dirs" ]; do
        sleep 5
    done

    echo "Sync completed."
    sleep 5

    echo "Shutting down Syncthing..."
    s_shutdown
    echo "Syncthing shut down."
}

usb() {
    echo "Waiting for USB device to be mounted at $mount_dir..."
    until [ -d $mount_dir ]; do
        sleep 5
    done

    echo "USB device connected."

    echo "Creating Backups Archive from Directories..."
    tar -cJf /tmp/Backups.tar.xz "${b_dirs[@]}"
    echo "Archive created."

    echo "Moving Archive to USB device..."
    mv /tmp/Backups.tar.xz "$mount_dir/"
    echo "Backup moved to USB device."

    echo "Unmounting USB device /dev/sdc1..."
    sudo umount /dev/sdc1
    echo "USB device unmounted."
}

echo "Starting Syncthing sync and USB backup process..."

run_syncthing
usb

echo "Backup process completed successfully."
