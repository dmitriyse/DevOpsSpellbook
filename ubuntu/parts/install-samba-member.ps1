#!/usr/bin/pwsh

$rootPath = [System.IO.Path]::GetFullPath((split-path $SCRIPT:MyInvocation.MyCommand.Path -parent))

try{
    Write-Host "Installing Samba-Member helper and settings" -ForegroundColor DarkGreen
    $userId = id --user
    if ($userId -ne "0"){
        throw "This script should be executed from the root"
    }

    $domainSuffix = &sudo -u $env:USER dns-domain-suffix
    if ($LastExitCode){exit $LastExitCode} #Execution mantra

    which klist | Out-Null
    if ($LastExitCode)
    {
        Write-Host "krb5-user package should be installed"
        exit $LastExitCode
    }

    # Installing required package
    apt install samba attr acl winbind libpam-winbind libnss-winbind -y
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    
    # Allowing home directory creation on successfull user login
    Get-Content /var/lib/pam/seen | Where-Object {$_ -notmatch 'mkhomedir'} | Set-Content /var/lib/pam/seen
    (Get-Content /usr/share/pam-configs/mkhomedir) -replace "Default: no", "Default: yes" `
    | Set-Content /usr/share/pam-configs/mkhomedir
    pam-auth-update --package
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    
    # TODO: target ntp to domain time service (this step is not so necessary under linux)
    # patch /etc/ntp.conf $rootPath/samba-member/ntp.conf.patch

    # Allowing samba users and groups
    patch /etc/nsswitch.conf $rootPath/samba-member/nsswitch.conf.patch
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    
    # Allowing Windows Putty Single Sign On with credentials delegation
    patch /etc/ssh/sshd_config $rootPath/samba-member/sshd_config.patch
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    
    # Adding domain admins to sudoers list
    cp $rootPath/samba-member/domain-admins /etc/sudoers.d
    chmod 0440 /etc/sudoers.d/domain-admins
    
    # Making temporary copy for samba-member dist files
    cp -rf $rootPath/samba-member/dist /tmp/samba-member-dist
    
    # Changing root for dist files
    chown root:root -R /tmp/samba-member-dist
    
    # Moving dist files to the target place
    cp -rf /tmp/samba-member-dist/* /
    rm -r /tmp/samba-member-dist
}
catch
{
    Write-Host "$($_.Exception.Message)"
    exit 1
}

