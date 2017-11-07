#!/usr/bin/pwsh

$userId = id --user
if ($userId -ne "0"){
    throw "This script should be executed from the root"
}

$daemon_json_path = '/etc/docker/daemon.json'
if (Test-Path $daemon_json_path)
{
    $daemon_json = Get-Content $daemon_json_path -raw | ConvertFrom-Json
}
else
{
    $daemon_json = New-Object PSObject 
}

$requires
if (! [bool]($daemon_json.PSobject.Properties.name -match "hosts"))
{
    $daemon_json | Add-Member "hosts" ("fd://", "tcp://0.0.0.0")
    $requires_daemon_json_change = $true
}
else
{
    $requires_daemon_json_change = $true
    foreach ($hst in $daemon_json.hosts)
    {
        if ($hst -eq "tcp://0.0.0.0")
        {
            $requires_daemon_json_change = $false
            break
        }
    }

    $daemon_json.hosts = $daemon_json.hosts + "tcp://0.0.0.0"
}

if ($requires_daemon_json_change)
{
    $daemon_json | ConvertTo-Json -Depth 100  | set-content $daemon_json_path
}


$rootPath = [System.IO.Path]::GetFullPath((split-path $SCRIPT:MyInvocation.MyCommand.Path -parent))

# Making temporary copy for samba-member dist files
cp -rf $rootPath/open-docker-remote-access-dist /tmp/open-docker-remote-access-dist

# Changing root for dist files
chown root:root -R /tmp/open-docker-remote-access-dist

# Moving dist files to the target place
cp -rf /tmp/open-docker-remote-access-dist/* /
rm -r /tmp/open-docker-remote-access-dist


systemctl daemon-reload

service docker restart
