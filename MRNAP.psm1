<#
.SYNOPSIS
    Generates a report file name and path with various customizable options.

.DESCRIPTION
    This script generates a report file name and path based on the provided parameters. It supports options for specifying the report name, directory, file extension, timestamp format, and more. The script can also move existing similar files to an 'old' directory if specified.

.PARAMETER ReportName
    The name of the report. If not specified, a random word or script name will be used. Alias: RN.

.PARAMETER DirectoryName
    The destination directory where the report file will be stored. Default is the user's home directory. Alias DN.

.PARAMETER Extension
    The file extension for the report file. The default value is 'csv'. Alias: EXT, E.

.PARAMETER NoDateTimeSeconds
    Exclude the timestamp in the file name. Alias: NODTS, N.

.PARAMETER UTC
    Use Coordinated Universal Time (UTC) for the timestamp in the file name.

.PARAMETER NoSeparators
    Do not use separators (underscores and dashes) in the timestamp. Alias: NoSep, NX

.PARAMETER NoSeconds
    Exclude seconds from the timestamp. Alias: NoSec, NS.

.PARAMETER AddTime
    Include time in the timestamp. Alias: AT.

.PARAMETER NoDate
    Exclude the date in the file name. Alias ND.

.PARAMETER JustDate
    Include only the date in the file name. No filename or words just the date. Alias JD.

.PARAMETER Move
    Move files to an 'old' directory if files exist in destination directory. Alias M.

.LINK
    https://github.com/dcazman/MRNAP

.EXAMPLE
    MRNAP -ReportName "SalesReport" -DirectoryName "C:\Apple" -Extension "txt" -UTC -Move
    Generates a report file name and path with the specified options and moves existing files to an 'old' directory.
    Result C:\Apple\2025_01_01-SalesReport.txt

.EXAMPLE
    MRNAP -ReportName "MonthlyReport" -UTC -NoSeparators
    Generates a file path with name "MonthlyReport" using UTC time and without separators.
    Result: C:\Users\<UN>\Reports\2025_01_01T120000MonthlyReport.csv

.EXAMPLE
    MRNAP -NoDateTimeSeconds
    Generates a filename and file path with no timestamp
    Result: C:\Users\<UN>\Reports\<ScriptName>.csv
    or 
    Result: C:\Users\<UN>\Reports\<RandomWord>.csv

.EXAMPLE
    $output | MRNAP
    Generates a filename and file path.
    Result: C:\Users\<UN>\Reports\2025_01_01-<ScriptName>.csv
    or 
    Result: C:\Users\<UN>\Reports\2025_01_01-<RandomWord>.csv

.NOTES
    Author: Dan Casmas
    Version: 9.5
    Date: 1/2025
    Designed to work on Windows, Linux, and macOS. Tested with PowerShell 5.1 and 7.
#>
function MRNAP {
    [Alias("MoldReportNameAndPath")]
    #Requires -Version 5.1
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True, HelpMessage = "The name of the report. If not specified, a random word or script name will be used.")]
        [Alias("RN")][string]$ReportName,

        [parameter(Position = 1, Mandatory = $False, HelpMessage = "The destination directory where the report file will be stored. Default is the user's home directory.")]
        [Alias("DN")][string]$DirectoryName,

        [parameter(Position = 2, Mandatory = $False, HelpMessage = "The file extension for the report file. The default value is 'csv'.")]
        [Alias("EXT", "E")][string]$Extension = "csv",

        [parameter(Mandatory = $False, HelpMessage = "Exclude the timestamp in the file name.")]
        [Alias("NODTS", "N")][switch]$NoDateTimeSeconds,

        [parameter(Mandatory = $False, HelpMessage = "Use Coordinated Universal Time (UTC) for the timestamp in the file name.")]
        [switch]$UTC,

        [parameter(Mandatory = $False, HelpMessage = "Do not use separators (underscores and dashes).")]
        [Alias("NoSep", "NX")][switch]$NoSeparators,

        [parameter(Mandatory = $False, HelpMessage = "Exclude seconds from the timestamp.")]
        [Alias("NoSec", "NS")][switch]$NoSeconds,

        [parameter(Mandatory = $False, HelpMessage = "Include time in the timestamp.")]
        [Alias("AT")][switch]$AddTime,

        [parameter(Mandatory = $False, HelpMessage = "Exclude the date in the file name.")]
        [Alias("ND")][switch]$NoDate,

        [parameter(Mandatory = $False, HelpMessage = "Only the date in file name.")]
        [Alias("JD")][switch]$JustDate,

        [parameter(Mandatory = $False, HelpMessage = "Move similar files to an 'old' directory if similar files exist.")]
        [Alias("M")][switch]$Move
    )

    process {
        function GetScriptName {
            Try {
                $callStack = Get-PSCallStack
                if ($callStack.Location -eq "<No file>") {
                    return $null  # Running interactively, return nothing
                }
                return $callStack[2].Location  # Get the outermost script location
            }
            catch {
                return $null
            }
        }

        # Function to get a random word
        function GetRandomWord {
            $Words = @(
                'Alpha', 'Ace', 'Bravo', 'Cat', 'Dan', 'Delta', 'Echo', 'Ethan', 
                'Foxtrot', 'Golf', 'Hotel', 'India', 'Juliet', 'Kathie', 'Kilo', 
                'Lima', 'Mat', 'November', 'Oscar', 'Phil', 'Quebec', 'Romeo', 
                'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey', 'X-ray', 'Yoyo', 
                'Zachary', 'Zulu'
            )
            return Get-Random -InputObject $Words
        }

        # Set default report name if not provided
        if ([string]::IsNullOrWhiteSpace($ReportName) -and (-not $JustDate -or ($JustDate -and $NoDateTimeSeconds))) {
            $ScriptName = GetScriptName
            if ([string]::IsNullOrWhiteSpace($ScriptName)) {
                $ReportName = GetRandomWord
            }
            else {
                $ReportName = $ScriptName -replace '\.[^.]+$', ''
            }
        }

        # Set default directory name if not provided
        if ([string]::IsNullOrWhiteSpace($DirectoryName)) {
            $DirectoryName = [IO.Path]::Combine($HOME, "Reports")
        }
        elseif (-not $DirectoryName.Contains(":")) {
            if (-not $DirectoryName.StartsWith([IO.Path]::DirectorySeparatorChar)) {
                $DirectoryName = [IO.Path]::DirectorySeparatorChar + $DirectoryName
            }
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

        # Format the timestamp based on the specified options
        if (-not $NoDateTimeSeconds) {
            $timestampFormat = "yyyy_MM_dd-"

            if ($AddTime) {
                $timestampFormat = "yyyy_MM_ddTHHmmss-"
            }
            elseif ($NoSeconds) {
                $timestampFormat = "yyyy_MM_ddTHHmm-"
            }
            elseif ($JustDate) {
                $timestampFormat = "yyyy_MM_dd"
            }

            if ($UTC) {
                # Handle UTC formatting for NoDate case
                if ($JustDate) {
                    $timestamp = (Get-Date).ToUniversalTime().ToString($timestampFormat)  # Only date in UTC
                }
                elseif ($NoDate) {
                    $timestamp = (Get-Date).ToUniversalTime().ToString("HHmmss-")  # Only time in UTC, no date
                }
                else {
                    $timestampFormat = "yyyy_MM_ddTHHmmss-"
                    if ($NoSeconds) {
                        $timestampFormat = "yyyy_MM_ddTHHmm-"
                    }
                    $timestamp = (Get-Date).ToUniversalTime().ToString($timestampFormat)  # Full date and time in UTC
                }
            }
            else {
                # Handle local time formatting
                if ($NoDate) {
                    $timestamp = (Get-Date).ToString("HHmmss-")  # Local time with no date
                }
                elseif ($JustDate) {
                    $timestamp = (Get-Date).ToString($timestampFormat)
                }
                else {
                    $timestamp = Get-Date -Format $timestampFormat  # Full date and time in local time
                }
            }
        }

        # Handle separators if needed
        if ($NoSeparators) {
            $timestamp = $timestamp -replace "_", "" -replace "-", ""
        }

        # Build the full file path
        $FullPath = Join-AnyPath $DirectoryName "$timestamp$ReportNameExt"

        # Move files to "old" directory if specified
        if ($Move) {
            if (-not (Test-Path $DirectoryName)) {
                try {
                    New-Item -ItemType Directory -Path $DirectoryName -Force -ErrorAction Stop | Out-Null
                }
                catch {
                    Write-Warning "Unable to create directory $DirectoryName"
                }
            }
            Else {
                $items = Get-ChildItem -Path $DirectoryName -Filter $ReportNameExt -File -ErrorAction Stop -Force

                if ($items.count -gt 0) {
                    $oldDirectory = Join-AnyPath $DirectoryName "old"

                    if (-not (Test-Path $oldDirectory)) {
                        try {
                            New-Item -ItemType Directory -Path $oldDirectory -Force -ErrorAction Stop | Out-Null
                        }
                        catch {
                            Write-Warning "Unable to create directory and move any related files to $oldDirectory"
                        }
                    }

                    try {
                        $items | Move-Item -Destination $oldDirectory -ErrorAction Stop -Force | Out-Null
                    }
                    catch {
                        Write-Warning "Problem moving files to $oldDirectory."
                    }
                }
            }
        }

        return [string]$FullPath
    }
}
