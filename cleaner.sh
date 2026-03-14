#!/bin/bash

# SPDX-FileCopyrightText: 2026 Tirth Kavathiya <tirthkavathiya@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

sudo -v

# This function gets the list of applications that are installed and removes the config folders of the applications that are not listed as installed.
flatpak_config_remove() {
    echo "Removing useless Flatpak config directories..."
    list=( $(flatpak list --app --columns=application) )
    var_list=( $(ls ~/.var/app/) )

    for package in "${var_list[@]}"; do
        present=0
        for i_package in "${list[@]}"; do
            if [ "$package" = "$i_package" ]; then
                present=1
                break
            fi
        done
        if [ "$present" -ne 1 ]; then
            echo "Removing unused Flatpak config: $package"
            rm -rf "$HOME/.var/app/$package"
        fi
    done
    echo "Flatpak config cleanup completed."
}

echo "Clearing Bash history..."
history -c && rm ~/.bash_history
echo "Bash history cleared."

echo "Removing Recent File History..."
rm ~/.local/share/recently-used.xbel
echo "Recent File History removed."

echo "Emptying Trash..."
gio trash --empty
echo "Trash emptied."

echo "Removing temporary files..."
sudo rm -rf /tmp/*
rm -rf ~/.cache/*
echo "Temporary files removed."

echo "Cleaning no-use packages with DNF..."
sudo dnf clean packages
sudo dnf clean all
echo "Performing autoremove of unnecessary packages..."
sudo dnf autoremove -y
echo "Cleaning DNF metadata..."
sudo dnf clean metadata
echo "Uninstalling unused Flatpak runtimes and apps..."
flatpak uninstall --unused -y

flatpak_config_remove

echo "System cleanup completed."
