<#
.SYNOPSIS
    Queries a DNS server for a DNS record.
.DESCRIPTION
    The dig function queries a DNS server for a DNS record using the nslookup command. 
    By default, it returns all the lines of the nslookup output. 
    It also provides the option to return only the last line of the output and to display verbose output.
.PARAMETER Domain
    Specifies the domain name or IP address to query.
.PARAMETER Server
    Specifies the DNS server to query. The default value is '8.8.8.8'.
.PARAMETER Type
    Specifies the type of DNS record to retrieve. The default value is 'A'.
.PARAMETER Short
    Specifies whether to return only the last line of the nslookup output.
.PARAMETER Trace
    Specifies whether to display verbose output.
.EXAMPLE
    PS C:\> dig example.com
    This command queries the DNS server '8.8.8.8' for the A record of the domain 'example.com'.
.EXAMPLE
    PS C:\> dig example.com -Server 192.168.1.1 -Type MX -Short
    This command queries the DNS server '192.168.1.1' for the MX record of the domain 'example.com' 
    and returns only the last line of the nslookup output.
#>
function dig {
    [CmdletBinding()]
    #Requires -Version 5.1
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,

        [Parameter(Position = 1)]
        [ValidatePattern("^(\d{1,3}\.){3}\d{1,3}$|^([a-zA-Z0-9][-a-zA-Z0-9]{0,62}\.)+[a-zA-Z]{2,}$")]
        [string]$Server = '8.8.8.8',

        [Parameter(Position = 2)]
        [ValidateSet('A', 'AAAA', 'CNAME', 'MX', 'NS', 'PTR', 'SOA', 'SRV', 'TXT')]
        [string]$Type = 'A',

        [Parameter()]
        [switch]$Short,

        [Parameter()]
        [switch]$Trace
    )

    # If -Trace is used, display verbose output.
    if ($Trace.IsPresent) {
        $VerbosePreference = 'Continue'
    }

    # Check if the Server parameter is a valid IP address or hostname.
    if ($Server -match "^(\d{1,3}\.){3}\d{1,3}$|^([a-zA-Z0-9][-a-zA-Z0-9]{0,62}\.)+[a-zA-Z]{2,}$") {
        # Construct the nslookup command based on the parameters.
        $command = "nslookup -type=$Type $Domain $Server"
        try {
            # Run the nslookup command and return the output.
            $result = $null
            $result = Invoke-Expression $command -ErrorAction SilentlyContinue 2> $null

            # If -Short is used, return only the last line of the output.
            if ($Short.IsPresent) {
                $result = $result[-1]
            }

            # Determine whether the answer is authoritative or non-authoritative.
            $NSCommand = "nslookup -type=ns -debug $Domain $Server"
            $isAuthoritative = (Invoke-Expression $NSCommand -ErrorAction SilentlyContinue) 2> $null
            
            if ($isAuthoritative -match ".*server =\s+$Server.*" -and $isAuthoritative -match ".*$Domain\..*") {
                $isAuthoritativeTF = $true
            }
            else {
                $isAuthoritativeTF = $false
            }

            if (($isAuthoritative | Select-String -Pattern 'REFUSED') -match "REFUSED") {
                $refused = $true
            }
            else {
                $refused = $false
            }

            # Create a custom object to hold the output and include the relevant information.
            $output = [pscustomobject]@{
                Type            = $Type
                Domain          = $Domain
                Server          = $Server
                Query           = "$Type record for $Domain on server $Server"
                Command         = $Command
                IsAuthoritative = $isAuthoritativeTF
                Short           = $Short.IsPresent
                Trace           = $Trace.IsPresent
                Refused         = $refused
                Result          = $result | Format-List | Out-String
            }

            Return $output
        }
        catch {
            Write-Error "Error querying DNS server: $_"
        }
    }
    else {
        Write-Error "Invalid server address: $Server"
    }
}
