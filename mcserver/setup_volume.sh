#!/bin/bash
format_mount_disk()
{
    local disk=$1
    local path=$2

    mkdir -p $path
    mkfs.ext4 $disk

    echo "$disk    $path  ext4     defaults 0 0" >> /etc/fstab

    mount -a
}

create_mc_directories()
{
    local path=$1

    mkdir -p $path/modpacks
    chown mc:admin $path/modpacks
    mkdir -p $path/server
    chown mc:admin $path/server
    mkdir -p $path/backups
    chown mc:admin $path/backups
}

format_mount_disk $1 $2
create_mc_directories $2