<#
.Description
Requires GAM, windows and PS 5.1 or greater to work. Author Dan Casmas 9/2021.
GAM will add or remove delegation.
Enter email addresses, -add or -remove then -Mailbox, -Calendar or -CalAndMail and the result will return.
If no values are given the function will request for input.
This function will make a csv report of the results in C:\Reports\ unless the -NoReport switch is used.
.EXAMPLE
.\GAMAllDelegate
.\GAMAllDelegate -SourceEmail SExample@domain.com -DestinationEmail DExample@domain.com -Add -Calendar
.\GAMAllDelegate -SourceEmail SExample@domain.com -DestinationEmail DExample@domain.com -Remove -NoReport -CalAndMail
#>
param (
    [parameter(Mandatory = $False,
        HelpMessage = "Enter the source email address like name@domain.com.")]
    [string]$SourceEmail,
    [parameter(Mandatory = $False,
        HelpMessage = "Enter the destination email address like name@domain.com.")]
    [string]$DestinationEmail,
    [parameter(Mandatory = $False,
        HelpMessage = "Delegate Mailbox.")]
    [switch]$Mailbox,
    [parameter(Mandatory = $False,
        HelpMessage = "Delegate calendar.")]
    [switch]$Calendar,
    [parameter(Mandatory = $False,
        HelpMessage = "Delegate alendar and mailbox.")]
    [switch]$CalAndMail,
    [parameter(Mandatory = $False,
        HelpMessage = "Add to calendar.")]
    [switch]$Add,
    [parameter(Mandatory = $False,
        HelpMessage = "Remove from calendar.")]
    [switch]$Remove,
    [parameter(Mandatory = $False,
        HelpMessage = "No Report file is generated.")]
    [switch]$NoReport
)
#Requires -Version 5.1
<# Requires GAM, windows and PS 5.1 or greater to work.
    Author Dan Casmas 9/2021 #>

If ($Add -and $Remove) {
    Write-Warning "Add and Remove switches can't be used together"
    Return $null
}

If (!($Mailbox -or $Calendar -or $CalAndMail)) {
    $Delegation = $null
    while ($Delegation -ne "1" -and $Delegation -ne "2" -and $Delegation -ne "3") {
        write-host "Hit enter to break. "  -ForegroundColor red  -NoNewline
        write-host "Please Enter " -NoNewline
        write-host "1 for calendar" -ForegroundColor Green -NoNewline
        write-host ", " -NoNewline
        write-host "2 for mailbox" -ForegroundColor Blue -NoNewline
        Write-host " or " -NoNewline
        Write-host "3 for both" -ForegroundColor Cyan -NoNewline
        $Delegation = Read-Host " ?"
        if ($Delegation -eq "") {
            Return Write-Host "Enter was inputted" -ForegroundColor Black -BackgroundColor White
        }
    }
    If ($Delegation -eq "1") {
        $Mailbox = $true
    }
    If ($Delegation -eq "2") {
        $Calendar = $True
    }
    If ($Delegation -eq "3") {
        $CalAndMail = $true
    }
}

IF ($Mailbox) {
    $Type = 'Mailbox'
}

If ($Calendar) {
    $Type = 'Calendar'
}

IF ($CalAndMail) {
    $Type = 'Calendar&Mailbox' 
}

If (!($Add -or $Remove)) {
    $ActionCheck = $null
    while ($ActionCheck -ne "1" -and $ActionCheck -ne "2") {
        write-host "Hit enter to break. "  -ForegroundColor red  -NoNewline
        write-host "Please Enter " -NoNewline
        write-host "1 for add" -ForegroundColor Green -NoNewline
        Write-host " or " -NoNewline
        write-host "2 for remove" -ForegroundColor Blue -NoNewline
        $ActionCheck = Read-Host " ?"
        if ($ActionCheck -eq "") {
            Return Write-Host "Enter was inputted" -ForegroundColor Black -BackgroundColor White
        }
    }
    If ($ActionCheck -eq "1") {
        $Add = $true
    }
    Else {
        $Add = $False
    }
}

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
If ($Add) {
    If ($Calendar -or $CalAndMail) {
        & gam.exe calendar $SourceEmail add editor $DestinationEmail
        $Flag = 'Add'
    }
    If ($Mailbox -or $CalAndMail) {
        & gam.exe user $SourceEmail delegate to $DestinationEmail
        $Flag = 'Add'
    }
}
Else {
    If ($Calendar -or $CalAndMail) {
        & gam.exe calendar $SourceEmail delete $DestinationEmail
        $Flag = 'Remove'
    }
    If ($Mailbox -or $CalAndMail) {
        & gam.exe user $SourceEmail delete delegate $DestinationEmail
        $Flag = 'Remove'
    }
}

If (!$NoReport) {
    If (!(Test-Path "C:\reports")) {
        Try {
            New-Item -Path C:\reports -ItemType Directory -ErrorAction SilentlyContinue -ErrorVariable $Problem -Force | Out-Null
        }
        Catch {
            Write-Warning "Problem trying to create report! $Type of $SourceEmail $Flag $DestinationEmail"
        }
    }

    If (!$Problem) {
        $result = [PSCustomObject]@{
            Source      = $SourceEmail
            Destination = $DestinationEmail
            Action      = $Flag
            Type        = $Type
            Error       = $LASTEXITCODE
        }
        $Filename = 'C:\reports\' + $SourceEmail.Split('@')[0] + '_' + $DestinationEmail.Split('@')[0] + "_$Flag" + "-Delegate" + '.csv'
        $result | Export-Csv $filename -NoTypeInformation
        write-host $filename
    }
}

If ($LASTEXITCODE -or $error) {
    Write-Warning "Problem! $Type of $SourceEmail $Flag $DestinationEmail"
}
Else {
    write-host "$Type of $SourceEmail $Flag $DestinationEmail processed" -ForegroundColor Green
}
     
return [object]$result
