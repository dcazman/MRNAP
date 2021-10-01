<#
.Description
Requires GAM, windows and PS 5.1 or greater to work. Author Dan Casmas 9/2021.
GAM will delegate the source calendar to the destination email address. 
Enter email addresses and the result will return.
If no values are given the function will request email addresses.
This function will make a csv report of the results in C:\Reports\ unless the -NoReport switch is used.
.EXAMPLE
GAMDelegateCalendar -SourceEmail SExample@domain.com -DestinationEmail DExample@domain.com
GAMDelegateCalendar -SourceEmail SExample@domain.com -DestinationEmail DExample@domain.com -NoReport
#>
function GAMDelegateCalendar {
    param (
        [parameter(Mandatory = $False,
            HelpMessage = "Enter the source email address like name@domain.com.")]
        [string]$SourceEmail,
        [parameter(Mandatory = $False,
            HelpMessage = "Enter the destination email address like name@domain.com.")]
        [string]$DestinationEmail,
        [parameter(Mandatory = $False,
            HelpMessage = "No Report file is generated.")]
        [switch]$NoReport
    )
    #Requires -Version 5.1
    <# Requires GAM, windows and PS 5.1 or greater to work.
    Author Dan Casmas 9/2021 #>

    while (!($SourceEmail -as [System.Net.Mail.MailAddress])) {
        write-host "Hit enter to break. "  -ForegroundColor red  -NoNewline
        write-host "Enter source email address" -ForegroundColor Green -NoNewline
        $SourceEmail = Read-Host " ?"
        if ($SourceEmail -eq "") {
            Return Write-Host "Enter was inputted" -ForegroundColor Black -BackgroundColor White
        }
    }

    while (!($DestinationEmail -as [System.Net.Mail.MailAddress])) {
        write-host "Hit enter to break. "  -ForegroundColor red  -NoNewline
        write-host "Enter destination email address" -ForegroundColor Blue -NoNewline
        $DestinationEmail = Read-Host " ?"
        if ($DestinationEmail -eq "") {
            Return Write-Host "Enter was inputted" -ForegroundColor Black -BackgroundColor White
        }
    }

    $error.clear()
    & gam.exe calendar $SourceEmail add editor $DestinationEmail

    If (!($NoReport)) {
        If (!(Test-Path "C:\reports")) {
            Try {
                New-Item -Path C:\reports -ItemType Directory -ErrorAction SilentlyContinue -ErrorVariable $Problem -Force | Out-Null
            }
            Catch {
                Write-Warning "Problem trying to create report for delegation of $SourceEmail calendar to $DestinationEmail"
            }
        }

        If (!$Problem) {
            $result = [PSCustomObject]@{
                Scoure        = $SourceEmail
                Destinination = $DestinationEmail
                Error         = $LASTEXITCODE
            }
            $filename = 'C:\reports\' + $SourceEmail.Split('@')[0] + '_' + $DestinationEmail.Split('@')[0] + '.csv'
            $result | Export-Csv $filename -NoTypeInformation
            write-host $filename
        }
    }

    If ($LASTEXITCODE -or $error) {
        return Write-Warning "Problem delegating $SourceEmail calendar to $DestinationEmail"
    }
    Else {
        return write-host "$SourceEmail delegated calendar to $DestinationEmail"
    }
}