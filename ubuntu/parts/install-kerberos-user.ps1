#!/usr/bin/pwsh

try{
    Write-Host "Installing kerberos client (krb5-user)" -ForegroundColor DarkGreen
    $userId = id --user
    if ($userId -ne "0"){
        throw "This script should be executed from the root"
    }
    $domainSuffix = &sudo -u $env:USER dns-domain-suffix
    if ($LastExitCode){exit $LastExitCode} #Execution mantra
    $hostName = hostname

    #$fullHostName = "$hostName.$domainSuffix"
    #$fullHostNameAddressString = get-content /etc/hosts | where {$_.Contains($fullHostName)} | Select-Object -First 1
    #if (!$fullHostNameAddressString){
    #    throw """/etc/hosts"" should contain address for the ""$fullHostName"" (full host name)"
    #}

    fix-hostname-in-hosts

    #$ip = ($fullHostNameAddressString.Trim() -split "\s")[0]
    #Write-Host "IP v4 for from the /etc/hosts: $ip"
    #if ($ip.StartsWith("127.")){
    #    throw "/etc/hosts should setup external IP address for the ""$fullHostName"" (full host name)"
    #}

    fix-ip-in-hosts

    # Installing kerberos and NTP for time synchronization.
    # We do not setup NTP special server. It's very rare case when KDC subsystem requires custom time.
    # Also it's a rare case when KDC infrastructure have no internet access
    apt install ntp krb5-user libpam-krb5 -y
    $spnegoKeyConfigPath = "/etc/request-key.d/cifs.spnego.conf"
    (Get-Content $spnegoKeyConfigPath) -replace "/usr/sbin/cifs.upcall %k", "/usr/sbin/cifs.upcall --trust-dns %k" `
        | out-file $spnegoKeyConfigPath -Encoding utf8
}
catch
{
    Write-Host "$($_.Exception.Message)"
    exit 1
}
