#!/usr/bin/env bash

set -e

if [[ $EUID > 0 ]]
then
        echo "Script should be run as root"
        exit
fi

# Create swapfile of size 1GB
dd if=/dev/zero of=/swapfile count=1024 bs=1M

if ! ls / | grep swapfile
then
        echo "Swap file not created"
        exit 1
fi

# Turn on swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

if ! cat /etc/fstab | grep "/swapfile"
then
        echo "Updating '/etc/fstab'"
        cp /etc/fstab /etc/fstab.bckp
        echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
fi

echo "Swap file enabled"
