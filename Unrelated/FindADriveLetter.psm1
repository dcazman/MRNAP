<#
.SYNOPSIS
Find A Drive Letter that is free and if desired will return the letter of a drive if it is already mapped and if not it returns a free letter to map.
.PARAMETER NameToMap
-NameToMap use any part of the shared file name or description and this function will try and return the drive letter. Otherwise a free drive letter is returned
.Description
Find A Drive Letter function. Optionally use the -NameToMap switch with any part of a drive detail. 
Designed to work on Windows OS.
.NOTES
The goal of this function is to Find A Drive Letter that is free to map. No colon is returned. Just a single drive letter. Drive letters A,B,C and D are excluded from consideration.
.Link
https://github.com/dcazman/MRNAP/tree/main/Unrelated
.EXAMPLE
Run FindADriveLetter or alias FADL like the following
FindADrive (Returns a free drive letter without a colon)
FindADrive -NameToMap open (If a drive is mapped with any portion of the name or description is like the word open the drive letter will be returned otherwise a free drive letter will be returned.)
FADL (Returns a free drive letter without a colon)
FADL -NameToMap open (If a drive is mapped with any portion of the name or description like the word open the drive letter will be returned otherwise a free drive letter will be returned.)
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
    function FreeDriveLetter {
        #this $Letter bit of code below is curtosy of https://stackoverflow.com/
        $AvailableLetter =
        try {
            $null = Get-PSDrive -ErrorAction Stop -Name ([char[]] 'efghijklmnopqrstuvwxyz')
        }
        catch {
            $_.TargetObject
        }
        
        if (-not $AvailableLetter) {
            Write-Warning "No drive letters available."
            Return $null 
        }
    
        Return [string]$AvailableLetter       
    }

    If ([string]::IsNullOrWhiteSpace($NameToMap)) {
        $Letter = FreeDriveLetter
    }
    Else {
        $Letter = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue -ErrorVariable ProcessError | Where-Object { $_.Name -like ([regex]'[efghijklmnopqrstuvwxyz]') -and ($_.displayroot -like "*$NameToMap*" -or $_.Description -like "*$NameToMap*" ) } | Select-Object -ExpandProperty Name

        If ($ProcessError -or [string]::IsNullOrWhiteSpace($Letter)) {
            $Letter = FreeDriveLetter
        }

        If ($Letter.count -gt 1) {
            Write-Warning "$($Letter.count) drives found with a similar name or description to $NameToMap"
            [string]$Letter = $Letter[0]
        }
    }

    Return [string]$Letter
}