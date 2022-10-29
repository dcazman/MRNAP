<#
This is my current favorite creation. A simple script that tries to find if there are the following DNS records A,MX,SPF,DMARC and DKIM.
Run the script and enter the full domain name,an email address or entire URL.
Examples:
.\isdomainactive.ps1 -domain facebook.com
switch -sub will test the subdomain
.\isdomainactive.ps1 -domain cnn.facebook.com -sub
switch -selector will test dkim with the string provided
.\isdomainactive.ps1 -domain cnn.facebook.com -selector face
switch -notmore will return simple true of false
.\isdomainactive.ps1 -domain cnn.facebook.com -notmore
examples:
.\isdomainactive.ps1 -domain cnn.facebook.com -sub -notmore -selector face
.\isdomainactive.ps1 -domain cnn.facebook.com -sub -selector face
.\isdomainactive.ps1 -domain cnn.facebook.com -selector face
.\isdomainactive.ps1 -domain cnn.facebook.com -sub -notmore
.\isdomainactive.ps1 -domain cnn.facebook.com -sub -notmore -selector face
.\isdomainactive.ps1 -domain cnn.facebook.com -sub -selector face
.\isdomainactive.ps1 -domain cnn.facebook.com -selector face
Results if any comes back as an object and on host.
#>
function isdomainactive {
    param (
        [parameter(Mandatory = $true,
            HelpMessage = "Enter the full domain name. Example Facebook.com,enter an entire email address or enter full URL.")]
        [ValidateScript({
                if ($_ -like "*.*") {
                    return $true
                }
                else {
                    Throw [System.Management.Automation.ValidationMetadataException] "Enter a domain name like facebook.com or an entire email address."
                }
            })][string]$Domain,
        [parameter(Mandatory = $false,
            HelpMessage = "Allow subdomain. Example mail.facebook.com")][switch]$Sub,
        [parameter(Mandatory = $false,
            HelpMessage = "Return simple true or false for A,MX,SPF,DMARC and DKIM. DKIM needs -Selector to appear.")][switch]$NotMore,
        [parameter(Mandatory = $false,
            HelpMessage = "DKIM selector. DKIM won't be checked without this string.")][string]$Selector = 'unchecked'
    )

    <#
ver 2,Author Dan Casmas 10/2022. Designed to work on Windows OS.
Has only been tested with 5.1 and 7 PS Versions. Requires a minimum of PS 5.1
Parts of this code was written by Jordan W.
#>
    #Requires -Version 5.1

    #if email address pull down to domain and if not test domain
    $TestDomain = $null
    Try {
        $TestDomain = ([Net.Mail.MailAddress]$Domain).Host
    }
    Catch {
        try {
            $TestDomain = ([System.Uri]$Domain).Host
        }
        catch {
            [string]$TestDomain = $Domain
        }
    }

    #Removes @
    If ([string]::IsNullOrWhiteSpace($TestDomain)) {
        Try { 
            [string]$TestDomain = $Domain.Replace('@','').Trim()
        }
        Catch {
            Write-Error "Problem with $Domain as entered. Please see help."
            break script
        }
    }

    #get the last two items in the array and join them with dot
    if (-not $Sub) {
        [string]$TestDomain = $TestDomain.Split(".")[-2,-1] -join "."
    }

    $resultdkim = 'unchecked'

    [string]$resultA = If (Resolve-DnsName -Name $TestDomain -Type 'A' -Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.type -eq 'a' } ) { $true } Else { $false }

    #more detail on the return
    $resultmx = $null
    If (-not $NotMore) {
        #Brings back each record
        $mx = Resolve-DnsName -Name $TestDomain -Type 'MX' -Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue | Sort-Object -Property Preference -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($mx.NameExchange)) {
            [string]$resultmx = $false
        }
        Else {
            [string]$resultmx = "name pref ttl`n"  
            foreach ($Item in $mx) {
                [string]$resultmx += $Item.NameExchange + " $($Item.Preference)" + " $($Item.ttl)`n"
            }
        }

        $SPF = Resolve-DnsName -Name $TestDomain -Type 'TXT'-Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue
        $resultspf = $false
        foreach ($Item in $SPf.strings) {
            if ($Item -match "v=spf1") {
                [string]$resultspf = $Item
            }
        }

        $DMARC = Resolve-DnsName -Name "_dmarc.$($TestDomain)" -Type 'TXT' -Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue
        $resultdmarc = $false
        foreach ($Item in $DMARC) {
            if ($Item.type -eq 'txt') {
                [string]$resultdmarc = $Item.Strings
            }
        }
   
        if ($Selector -ne 'unchecked') {
            $DKIM = Resolve-DnsName -Type 'TXT' -Name "$($Selector)._domainkey.$($TestDomain)" -Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue
            $resultdkim = $false
            foreach ($Item in $DKIM) {
                if ($Item.type -eq 'txt') {
                    [string]$resultdkim = $Item.Strings
                }
            }
        }
    }
    Else {
        #brings back True or False
        [string]$resultmx = If (Resolve-DnsName -Name $TestDomain -Type 'MX' -Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.type -eq 'mx' } ) { $true } Else { $false }

        if ($Selector -ne 'unchecked') {
            [string]$resultdkim = If (Resolve-DnsName -Type 'TXT' -Name "$($Selector)._domainkey.$($TestDomain)" -Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue | where-object { $_.strings -match "v=DKIM1" } ) { $true } Else { $false }
        }

        [string]$resultspf = If (Resolve-DnsName -Name $TestDomain -Type 'TXT'-Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue | where-object { $_.strings -match "v=spf1" } ) { $true } Else { $false }

        [string]$resultDMARC = if (Resolve-DnsName -Name "_dmarc.$($TestDomain)" -Type 'TXT' -Server '8.8.8.8' -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.type -eq 'txt' } ) { $true } Else { $false }
    }

    #Output
    Return [PSCustomObject]@{
        A        = $resultA
        MX       = $resultmx.trimend("`r`n")
        SPF      = $resultspf
        DMARC    = $resultdmarc
        DKIM     = $resultdkim
        Selector = $Selector
        DOMAIN   = $TestDomain
    }
}
