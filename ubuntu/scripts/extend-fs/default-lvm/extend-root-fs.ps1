#!/usr/bin/pwsh

# Extending partitions in the classic partition table
sudo parted /dev/sda --script -- resizepart 2 -0
sudo parted /dev/sda --script -- resizepart 5 -0

# Updating physical layput for volume group
sudo pvresize /dev/sda5

# Extending logical volume
$vgname = [string](df --output=source / | select-string "/dev/mapper/(.*)-root")
sudo lvextend -l +100%FREE $vgname

# Extending ext4 fs
sudo resize2fs $vgname
