<#
.SYNOPSIS
Find A Drive Letter and if desired will return the letter of a drive if it is already mapped and if not it return a free letter to map
.PARAMETER NameToMap
-NameToMap use any part of the shared rive name and this function will try and return the drive letter. Otherwise a free drive letter is returned
.Description
Find A Drive Letter function. Optionally use the -NameToMap switch with any part of a drive detail. 
Designed to work on Windows OS.
.NOTES
The goal of this function is to Find A Drive Letter to map. No colon is returned. Just a single drive letter. Drive letters A,B,C and D are excluded from consideration
.Link
https://github.com/dcazman/MRNAP/tree/main/Unrelated
.EXAMPLE
Run FindADriveLetter or alias FADL like the following
FindADrive (Returns a free drive letter without a colon)
FindADrive -NameToMap open (If a drive is mapped with any portion if the name containing open the drive letter will be returned otherwsie a free drive letter will be returned.)
FADL (Returns a free drive letter without a colon)
FADL -NameToMap open (If a drive is mapped with any portion if the name containing open the drive letter will be returned otherwsie a free drive letter will be returned.)
#>
function FindADriveLetter {
    [alias("FADL")]
    param (
        [parameter(Mandatory = $False)][string]$NameToMap
    )

    <# ver 1.0  Author Dan Casmas 9/2021. Designed to work on Windows OS.
    Has only been tested with 5.1 and 7 PS Versions. Requires a minimum of PS 5.1 .#>
    #Requires -Version 5.1

    $Letter = $null
    function FreeLetter {
        #this $Letter bit of code below is curtosy of https://stackoverflow.com/
        $Letter =
        try {
            $null = Get-PSDrive -ErrorAction Stop -Name ([char[]] 'efghijklmnopqrstuvwxyz')
        }
        catch {
            $_.TargetObject
        }
        
        if (-not $Letter) {
            Write-Warning "No drive letters available."
            Return $null 
        }

        Return [string]$Letter        
    }

    If ([string]::IsNullOrWhiteSpace($NameToMap)) {
        $Letter = FreeLetter
    }
    Else {
        $Letter = Get-PSDrive -PSProvider FileSystem | Select-Object name, displayroot -ExpandProperty name | Where-Object { $_.displayroot -like "*$NameToMap*" } -ErrorAction SilentlyContinue -ErrorVariable ProcessError

        If ($ProcessError -or $null -eq $Letter) {
            $Letter = FreeLetter
        }
    }

    Return [string]$Letter
}