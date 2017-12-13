#!/usr/bin/pwsh

sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt update -y

# This is undocumented dependency that is required to all nvidia dependent packages correctly installed
sudo apt install nvidia-modprobe -y


$available_driver_versions = apt-cache search nvidia- | where { $_ -match 'nvidia-\d+ .*'} | %{ [int]$_.Substring("nvidia-".Length,3)}
$latest_driver_version = $available_driver_versions | sort | Select-Object -Last 1

# Also this installation was performed with plugged nvidia GPU. Probably this is not reuired, experiments needed.
sudo apt install nvidia-$latest_driver_version libcuda1-$latest_driver_version --no-install-recommends -y