#!/usr/bin/pwsh

<#
.SYNOPSIS
Helper script for join machine to AD domain.
.PARAMETER MinUid
Minimal UID that can be assigned to AD user or group.
.PARAMETER MaxUid
Maximal UID that can be assignet to AD user or group.
.PARAMETER User
User that will perform join 
.EXAMPLE
samba-member-join -MinUid=20000 -MaxUid=30000 -User Administrator
#>

param(
    [Int32]$MinUid,
    [Int32]$MaxUid,
    [String]$User)

try{
    $rootPath = [System.IO.Path]::GetFullPath((split-path $SCRIPT:MyInvocation.MyCommand.Path -parent))
    if (!$MinUid -or !$MaxUid -or !$User)
    {
        $helpStr = Get-Help $SCRIPT:MyInvocation.MyCommand.Path -Detailed | Out-String | % {$_.replace($SCRIPT:MyInvocation.MyCommand.Path,"samba-member-join")}
        $helpStr.Substring(0, $helpStr.IndexOf("REMARKS`n")).Trim()
        exit 1
    }

    Write-Host "Starting samba-member join procedure" -ForegroundColor DarkGreen

    $userId = id --user
    if ($userId -ne "0"){
        throw "This script should be executed from the root"
    }

    $domainSuffix = dns-domain-suffix
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    
    $workgroup = $domainSuffix.Split(".")[0].ToUpper()
    $netbiosName = (hostname).ToUpper()
    Write-Host "--------------------------------------"
    Write-Host "DNS DOMAIN SUFFIX: $domainSuffix"
    Write-Host "        WORKGROUP: $workgroup"
    Write-Host "    NET-BIOS NAME: $netbiosName"
    Write-Host "        UID RANGE: $MinUid-$MaxUid"
    Write-Host "--------------------------------------"
    
    $confirmation = Read-Host "Continue Join ? [y/n]"
    if ($confirmation -ne 'y') {
      exit 0
    }

    Write-Host "Upgrading pam kerberos minimum_uid ..."

    foreach ($file in Get-ChildItem /etc/pam.d) 
    {
        $content = (Get-Content $file.FullName -Raw)
        $searchMask = "pam_krb5\.so minimum_uid=\d+"
        # touching only files that contains string to replace
        if ($content -match $searchMask) 
        {
            $content -replace $searchMask, "pam_krb5.so minimum_uid=$MinUid" | Set-Content $file.FullName
        }
    }

    Write-Host "Replacing /etc/samba/smb.conf ..."

    (Get-Content $rootPath/smb.conf.tpl -Raw) `
        -replace "{{DNS-DOMAIN-SUFFIX}}", $domainSuffix.ToUpper() `
        -replace "{{WORKGROUP}}", $workgroup `
        -replace "{{NET-BIOS-NAME}}", $netbiosName `
        -replace "{{MIN-UID}}", $MinUid `
        -replace "{{MAX-UID}}", $MaxUid | Set-Content "/tmp/smb.conf.tmp"
    
    mv /etc/samba/smb.conf "/etc/samba/smb.conf-$(date +"%FT%H%M%S").bak"
    if ($LastExitCode){exit $LastExitCode} #Execution mantra

    mv /tmp/smb.conf.tmp /etc/samba/smb.conf
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    
    Write-Host "Performing Join:"
    net ads join -T -U $User
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    
}
catch
{
    Write-Host "$($_.Exception.Message)"
    exit 1
}
