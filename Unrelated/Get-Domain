#Gets the domain from a url or email address.
function Get-Domain {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputString
    )

    #credit to https://xkln.net/blog/getting-mx-spf-dmarc-dkim-and-smtp-banners-with-powershell/

    try {
        $Domain = ([Net.Mail.MailAddress]$InputString).Host
    }
    catch {
        $Domain = ([System.Uri]$InputString).Host
    }

    if (($null -eq $Domain) -or ($Domain -eq "")) {
        $Domain = $InputString 
    }
    $Domain = $Domain -replace '^www\.', ''

    function Write-ColorOutput($ForegroundColor) {
        # save the current color
        $fc = $host.UI.RawUI.ForegroundColor
    
        # set the new color
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    
        # output
        if ($args) {
            Write-Output $args
        }
        else {
            $input | Write-Output
        }
    
        # restore the original color
        $host.UI.RawUI.ForegroundColor = $fc
    }

    #$Domain | Write-ColorOutput blue
    Return [string]$Domain | Write-ColorOutput blue
}
