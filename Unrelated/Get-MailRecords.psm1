<#
A simple script that tries to find if there are the following DNS records A, MX, SPF, DMARC and DKIM.
Run the script and enter the full domain name, an email address or entire URL.
Examples:
.\get-mailrecords.ps1 -domain facebook.com
switch -sub will test the subdomain
.\get-mailrecords.ps1 -domain cnn.facebook.com -sub
switch -selector will test dkim with the string provided
.\get-mailrecords.ps1 -domain cnn.facebook.com -selector face
switch -flag will return simple true of false
.\get-mailrecords.ps1 -domain cnn.facebook.com -flag
examples:
.\get-mailrecords.ps1 -domain cnn.facebook.com -sub -flag -selector face
.\get-mailrecords.ps1 -domain cnn.facebook.com -sub -selector face
.\get-mailrecords.ps1 -domain cnn.facebook.com -selector face
.\get-mailrecords.ps1 -domain cnn.facebook.com -sub -flag
.\get-mailrecords.ps1 -domain cnn.facebook.com -sub -flag -selector face
.\get-mailrecords.ps1 -domain cnn.facebook.com -sub -selector face
.\get-mailrecords.ps1 -domain cnn.facebook.com -selector face
Results if any comes back as an object and on host.
#>
function Get-MailRecords {
    #Requires -Version 5.1
    [Alias("GMR")]
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true,
            HelpMessage = "Enter the full domain name an example is Facebook.com, enter an entire email address or enter full URL.")]
        [ValidateScript({
                if ($_ -like "*.*") {
                    return $true
                }
                else {
                    Throw [System.Management.Automation.ValidationMetadataException] "Enter the full domain name, an example is Facebook.com, enter an entire email address or enter full URL."
                    return $false
                }
            })][string]$Domain,
        [parameter(Mandatory = $false,
            HelpMessage = "Allow subdomain. Example mail.facebook.com")][switch]$Sub,
        [parameter(Mandatory = $false,
            HelpMessage = "Return simple true or false for A, MX, SPF, DMARC and DKIM. DKIM needs -Selector to appear.")][switch]$Flag,
        [parameter(Mandatory = $false,
            HelpMessage = "DKIM selector. DKIM won't be checked without this string.")][string]$Selector = 'unchecked',
        [parameter(Mandatory = $false,
            HelpMessage = "Looks for record type TXT or CNAME or BOTH for SPF, DMARC and DKIM if -Selector is used. The default record type is TXT.")]
        [ValidateSet('TXT', 'CNAME', 'BOTH')][ValidateNotNullOrEmpty()][string]$RecordType = 'TXT',
        [parameter(Mandatory = $false,
            HelpMessage = "Server to query the default is 8.8.8.8")][ValidateNotNullOrEmpty()][string]$Server = '8.8.8.8'
    )

    <#
    ver 6,Author Dan Casmas 05/2023. Designed to work on Windows OS.
    Has only been tested with 5.1 and 7 PS Versions. Requires a minimum of PS 5.1
    Parts of this code were written by Jordan W.
    #>

    $RecordType = $RecordType.ToUpper()
    
    #if email address pull down to domain,uri pull down to domain and if not test domain
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
            [string]$TestDomain = $Domain.Replace('@', '').Trim()
        }
        Catch {
            Write-Error "Problem with $Domain as entered. Please help."
            break script
        }
    }
    
    #get the last two items in the array and join them with dot
    if (-not $Sub.IsPresent) {
        [string]$TestDomain = $TestDomain.Split(".")[-2, -1] -join "."
    }
    
    #places a value other than true or false if dkim selector is not provided.
    $resultdkim = 'unchecked'

    #If Both then loop through.
    $RecordTypeTest = @()
    if ($RecordType -eq 'BOTH') {
        $RecordTypeTest = @(
            'TXT'
            'CNAME'
        )
    }
    Else {
        $RecordTypeTest = $RecordType
    }

    #Returns true or false for A record.
    [string]$resultA = If (Resolve-DnsName -Name $TestDomain -Type 'A' -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.type -eq 'a' } ) { $true } Else { $false }
    
    $Output = $RecordTypeTest | ForEach-Object {   
        #more detail on the return for SPF, DMARC and DKIM (If selector is provided)
        If ($Flag.IsPresent) {
            if ($Selector -ne 'unchecked') {
                [string]$resultdkim = If (Resolve-DnsName -Type "$_" -Name "$($Selector)._domainkey.$($TestDomain)" -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue | where-object { $_.strings -match "v=DKIM1" } ) { $true } Else { $false }
            }

            [string]$resultmx = If (Resolve-DnsName -Name $TestDomain -Type 'MX' -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.type -eq 'mx' } ) { $true } Else { $false }
        
            [string]$resultspf = If (Resolve-DnsName -Name $TestDomain -Type "$_"-Server "$Server" -DnsOnly -ErrorAction SilentlyContinue | where-object { $_.strings -match "v=spf1" } ) { $true } Else { $false }
            
            $DType = $null
            $DType = $_
            [string]$resultDMARC = if (Resolve-DnsName -Name "_dmarc.$($TestDomain)" -Type "$_" -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.type -eq "$DType" } ) { $true } Else { $false }
        }
        Else {
            $SPF = Resolve-DnsName -Name $TestDomain -Type "$_"-Server "$Server" -DnsOnly -ErrorAction SilentlyContinue 
            $resultspf = $false
            foreach ($Item in $SPF) {
                if ($Item.strings -match "v=spf1" -and $Null -ne $Item.Strings -and $Item.type -eq "$_") {
                    [string]$resultspf = $Item.Strings
                    break
                }
            }

            $Mx = Resolve-DnsName -Name $TestDomain -Type 'MX' -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue | Sort-Object -Property Preference 
            if ([string]::IsNullOrWhiteSpace($Mx.NameExchange)) {
                $resultmx = $false
            }
            Else {
                $Outmx = foreach ($record in $Mx) {
                    $record | Select-object @{n = "Name"; e = { $_.NameExchange } }, @{n = "Pref"; e = { $_.Preference } }, TTL
                }
                [string]$resultmx = ($Outmx | Out-String).trimend("`r`n").Trim()
            }
    
            $DMARC = Resolve-DnsName -Name "_dmarc.$($TestDomain)" -Type "$_" -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue 
            $resultdmarc = $false
            foreach ($Item in $DMARC) {
                if ($Item.type -eq "$_" -and $null -ne $Item.Strings -and $Item.strings -match "v=DMARC1") {
                    [string]$resultdmarc = $Item.Strings
                    break
                }
            }
       
            if ($Selector -ne 'unchecked') {
                $DKIM = Resolve-DnsName -Type "$_" -Name "$($Selector)._domainkey.$($TestDomain)" -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue 
                $resultdkim = $false
                foreach ($Item in $DKIM) {
                    if ($Item.type -eq "$_" -and $null -ne $Item.Strings -and $Item.Strings -match "v=DKIM1") {
                        [string]$resultdkim = $Item.Strings
                        break
                    }
                }
            }
        }

        If ($RecordType -eq 'Both' -and ($resultdkim -eq 'unchecked' -or $resultdkim -eq $false)) {
            if ($_ -eq 'TXT') {
                $SelectorHold = $Selector
            }
            else {
                $Selector = $SelectorHold
            }
        }
    
        If ($resultdkim -eq 'unchecked' -and $resultdkim -ne $false ) { 
            $TempType = $null
            $TempType = $_
            $DkimSelectors = $null
            $DkimSelectors = @(
                'default'
                's'
                's1'
                's2'
                'selector1' # Microsoft
                'selector2' # Microsoft
                'google', # Google
                'everlytickey1', # Everlytic
                'everlytickey2', # Everlytic
                'eversrv', # Everlytic OLD selector
                'k1', # Mailchimp / Mandrill
                'mxvault' # Global Micro
                'dkim' # Hetzner
            )

            $line = $null
            foreach ($line in $DkimSelectors) {
                $Selector = $line
                $DKIM = $null
                $DKIM = Resolve-DnsName -Type "$TempType" -Name "$($Selector)._domainkey.$($TestDomain)" -Server "$Server" -DnsOnly -ErrorAction SilentlyContinue 
                foreach ($Item in $DKIM) {
                    if ($Item.type -eq "$TempType" -and $null -ne $Item.Strings -and $Item.Strings -match "v=DKIM1") {
                        if ($Flag) {
                            $resultdkim = $true
                        }
                        Else {
                            [string]$resultdkim = $Item.Strings
                        }
                        break
                    }
                    $Item = $null
                }
                        
                If ($resultdkim -ne $false -and $resultdkim -ne 'unchecked') {
                    break
                }
                $line = $null
            }
        }
        [PSCustomObject]@{
            A          = $resultA
            MX         = $resultmx
            "SPF_$_"   = $resultspf
            "DMARC_$_" = $resultdmarc
            "DKIM_$_"  = $resultdkim
            SELECTOR   = $Selector
            DOMAIN     = $TestDomain
            RECORDTYPE = $_
            Server     = $Server
        } 
    }
    Return $Output
}
