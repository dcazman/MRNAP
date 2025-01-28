<#
.SYNOPSIS
    Generates a report file name and path with various customizable options.

.DESCRIPTION
    This script generates a report file name and path based on the provided parameters. It supports options for specifying the report name, directory, file extension, timestamp format, and more. The script can also move existing similar files to an 'old' directory if specified.

.PARAMETER ReportName
    The name of the report. If not specified, a random word will be used.

.PARAMETER DirectoryName
    The destination directory where the report file will be stored. Default is the user's home directory.

.PARAMETER Extension
    The file extension for the report file. The default value is 'csv'.

.PARAMETER NoDateTimeSeconds
    Exclude the timestamp in the file name.

.PARAMETER UTC
    Use Coordinated Universal Time (UTC) for the timestamp in the file name.

.PARAMETER NoSeparators
    Do not use separators (underscores and dashes) in the timestamp.

.PARAMETER NoSeconds
    Exclude seconds from the timestamp.

.PARAMETER AddTime
    Include time in the timestamp.

.PARAMETER NoDate
    Exclude the date in the file name.

.PARAMETER Move
    Move similar files to an 'old' directory if similar files exist.

.EXAMPLE
    MRNAP -ReportName "SalesReport" -DirectoryName "C:\Reports" -Extension "txt" -UTC -AddTime -Move
    Generates a report file name and path with the specified options and moves existing similar files to an 'old' directory.

.EXAMPLE
    MRNAP -ReportName "MonthlyReport" -UTC -NoSeparators
    Generates a file path with name "MonthlyReport" using UTC time and without separators.

.NOTES
    Author: Dan Casmas
    Version: 9
    Date: 1/2025
    Designed to work on Windows, Linux, and macOS. Tested with PowerShell 5.1 and 7.
#>
function MRNAP {
    [Alias("MoldReportNameAndPath")]
    #Requires -Version 5.1
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $False, HelpMessage = "The name of the report. If not specified, a random word will be used.")]
        [Alias("RN")][string]$ReportName,

        [parameter(Position = 1, Mandatory = $False, HelpMessage = "The destination directory where the report file will be stored. Default is the user's home directory.")]
        [Alias("DN")][string]$DirectoryName,

        [parameter(Position = 2, Mandatory = $False, HelpMessage = "The file extension for the report file. The default value is 'csv'.")]
        [Alias("EXT", "E")][string]$Extension = "csv",

        [parameter(Mandatory = $False, HelpMessage = "Exclude the timestamp in the file name.")]
        [Alias("NODTS")][switch]$NoDateTimeSeconds,

        [parameter(Mandatory = $False, HelpMessage = "Use Coordinated Universal Time (UTC) for the timestamp in the file name.")]
        [switch]$UTC,

        [parameter(Mandatory = $False, HelpMessage = "Do not use separators (underscores and dashes).")]
        [Alias("NoSep")][switch]$NoSeparators,

        [parameter(Mandatory = $False, HelpMessage = "Exclude seconds from the timestamp.")]
        [Alias("NoSec")][switch]$NoSeconds,

        [parameter(Mandatory = $False, HelpMessage = "Include time in the timestamp.")]
        [Alias("AT")][switch]$AddTime,

        [parameter(Mandatory = $False, HelpMessage = "Exclude the date in the file name.")]
        [Alias("ND")][switch]$NoDate,

        [parameter(Mandatory = $False, HelpMessage = "Move similar files to an 'old' directory if similar files exist.")]
        [Alias("M")][switch]$Move
    )

    # Function to get a random word
    function GetRandomWord {
        $Words = @(
            'Alpha', 'Ace', 'Bravo', 'Cat', 'Dan', 'Delta', 'Dog', 'Echo', 'Ethan', 
            'Foxtrot', 'Golf', 'Hotel', 'India', 'January', 'Juliet', 'Kathie', 'Kilo', 
            'Lima', 'Mat', 'March', 'November', 'October', 'Oscar', 'Phil', 'Quebec', 'Romeo', 
            'September', 'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey', 'X-ray', 'Yoyo', 
            'Zachary', 'Zulu'
        )
        return Get-Random -InputObject $Words
    }

    # Set default report name if not provided
    if ([string]::IsNullOrWhiteSpace($ReportName)) {
        $ReportName = GetRandomWord
    }

    # Set default directory name if not provided
    if ([string]::IsNullOrWhiteSpace($DirectoryName)) {
        $DirectoryName = [IO.Path]::Combine($HOME, "Reports")
    }

    # Ensure the extension starts with a dot
    if (-not $Extension.StartsWith(".")) {
        $Extension = ".$Extension"
    }

    # Build the basic report name with extension
    $ReportNameExt = "$ReportName$Extension"

    # Function to join paths in a platform-independent way
    function Join-AnyPath {
        return ($Args -join [IO.Path]::DirectorySeparatorChar) -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
    }

    If (-not $NoDateTimeSeconds) {
        # Format the timestamp based on the specified options
        $timestampFormat = "yyyy_MM_dd-"

        if ($AddTime) {
            $timestampFormat = "yyyy_MM_ddTHHmmss-"
        }
        elseif ($NoSeconds) {
            $timestampFormat = "yyyy_MM_ddTHHmm-"
        }

        if ($UTC) {
            $timestamp = if ($NoDate) {
            (Get-Date).ToUniversalTime().ToString("HHmmss-")
            }
            else {
            (Get-Date).ToUniversalTime().ToString($timestampFormat)
            }
        }
        else {
            $timestamp = if ($NoDate) {
                $null
            }
            else {
                Get-Date -Format $timestampFormat
            }
        }

        if ($NoSeparators) {
            $timestamp = $timestamp -replace "_", "" -replace "-", ""
        }
    }

    # Build the full file path
    $FullPath = Join-AnyPath $DirectoryName "$timestamp$ReportNameExt"

    # Move files to "old" directory if specified
    if ($Move) {
        if (-not (Test-Path $DirectoryName)) {
            try {
                New-Item -ItemType Directory -Path $DirectoryName -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "Unable to create directory $DirectoryName"
            }
        }
        
        $oldDirectory = Join-AnyPath $DirectoryName "old"
        $dirflag = $true
        if (-not (Test-Path $oldDirectory)) {
            try {
                New-Item -ItemType Directory -Path $oldDirectory -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "Unable to create directory and move any related files to $oldDirectory"
                $dirflag = $false
            }
        }

        if ($dirflag) {
            try {
                Get-ChildItem -Path $DirectoryName -Filter "*$ReportNameExt" -File -ErrorAction Stop -Force | Move-Item -Destination $oldDirectory -ErrorAction Stop -Force
            }
            catch {
                Write-Warning "Problem moving files to $oldDirectory."
            }
        }
    }

    return [string]$FullPath
}
