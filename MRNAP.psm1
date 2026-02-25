#Requires -Version 5.1
<#
.SYNOPSIS
    Generates a report file name and path with various customizable options.

.DESCRIPTION
    Generates a timestamped report file name and full path. Accepts pipeline input by value
    (a bare string becomes ReportName) and by property name (pipe any object whose properties
    match parameter names). Supports custom directory, extension, UTC or local time, date-only,
    time-only, no-separator mode, and automatic archival of existing files to an 'old'
    subdirectory. Works on Windows, Linux, and macOS with PowerShell 5.1 and 7+.

.PARAMETER ReportName
    The base name of the report file. Accepts pipeline input by value and by property name (RN).
    If omitted, the calling script's filename (without extension) is used; falls back to a
    random word when running interactively.

.PARAMETER DirectoryName
    Destination directory for the report file. Accepts pipeline input by property name (DN).
    Defaults to ~/Reports ($HOME/Reports). If a relative path is supplied, a leading path
    separator is prepended to root it.

.PARAMETER Extension
    File extension for the report. Accepts pipeline input by property name (EXT, E). Default: csv.
    A leading dot is added automatically if omitted.

.PARAMETER NoDateTimeSeconds
    Omit the timestamp entirely — only the report name and extension are used.
    Accepts pipeline input by property name (NODTS, N).

.PARAMETER UTC
    Use UTC instead of local time for the timestamp. Also forces the full datetime format
    (yyyy_MM_ddTHHmmss-). Accepts pipeline input by property name.

.PARAMETER NoSeparators
    Remove underscores and dashes from the timestamp portion of the filename.
    Accepts pipeline input by property name (NoSep, NX).

.PARAMETER NoSeconds
    Include time in the timestamp but omit seconds (HHmm instead of HHmmss).
    Accepts pipeline input by property name (NoSec, NS).

.PARAMETER AddTime
    Include full date and time (yyyy_MM_ddTHHmmss-) in the timestamp.
    Accepts pipeline input by property name (AT).

.PARAMETER NoDate
    Use only the time component (HHmmss-) — no date in the filename.
    Accepts pipeline input by property name (ND).

.PARAMETER JustDate
    Use only the date (yyyy_MM_dd) with no report name.
    Accepts pipeline input by property name (JD).

.PARAMETER Move
    Before returning the path, move any file in the destination directory that exactly matches
    <ReportName>.<Extension> to an 'old' subdirectory. Creates the destination and 'old'
    directories if they do not exist. Accepts pipeline input by property name (M).

.PARAMETER FlatName
    Return just the file name with no directory path and no timestamp.
    By default the extension is included (e.g. "Tom.csv"). Combine with -NoExtension to get a
    bare name (e.g. "Tom"). Accepts pipeline input by property name (FL).

.PARAMETER NoExtension
    Omit the file extension from the output. Most useful with -FlatName to produce a bare name
    like "Tom". Accepts pipeline input by property name (NE).

.LINK
    https://github.com/dcazman/MRNAP

.EXAMPLE
    MRNAP -ReportName "SalesReport" -DirectoryName "/tmp/Apple" -Extension "txt" -UTC -Move
    Generates a report file name and path with the specified options and moves existing files to an 'old' directory.
    Result: /tmp/Apple/2025_01_15T213022-SalesReport.txt

.EXAMPLE
    MRNAP -ReportName "MonthlyReport" -UTC -NoSeparators
    Generates a file path with name "MonthlyReport" using UTC time and without separators.
    Result: ~/Reports/20250115T213022MonthlyReport.csv

.EXAMPLE
    MRNAP -NoDateTimeSeconds
    Generates a filename and file path with no timestamp.
    Result: ~/Reports/<ScriptName>.csv
    or
    Result: ~/Reports/<RandomWord>.csv

.EXAMPLE
    'DailyReport' | MRNAP -DirectoryName '~/Reports'
    Pipes a string directly as the report name.
    Result: ~/Reports/2025_01_15-DailyReport.csv

.EXAMPLE
    [PSCustomObject]@{ ReportName = "Sales"; DirectoryName = "/tmp/reports" } | MRNAP
    Pipes an object with named properties to generate a report path.
    Result: /tmp/reports/2025_01_15-Sales.csv

.NOTES
    Author: Dan Casmas
    Version: 10.0
    Date: 2/2026
    Designed to work on Windows, Linux, and macOS. Tested with PowerShell 5.1 and 7+.
#>
function MRNAP {
    [Alias("MoldReportNameAndPath")]
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, HelpMessage = "The name of the report. If not specified, a random word or script name will be used.")]
        [Alias("RN")][string]$ReportName,

        [parameter(Position = 1, Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "The destination directory where the report file will be stored. Default is the user's home directory.")]
        [Alias("DN")][string]$DirectoryName,

        [parameter(Position = 2, Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "The file extension for the report file. The default value is 'csv'.")]
        [Alias("EXT", "E")][string]$Extension = "csv",

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Exclude the timestamp in the file name.")]
        [Alias("NODTS", "N")][switch]$NoDateTimeSeconds,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Use Coordinated Universal Time (UTC) for the timestamp in the file name.")]
        [switch]$UTC,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Do not use separators (underscores and dashes).")]
        [Alias("NoSep", "NX")][switch]$NoSeparators,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Exclude seconds from the timestamp.")]
        [Alias("NoSec", "NS")][switch]$NoSeconds,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Include time in the timestamp.")]
        [Alias("AT")][switch]$AddTime,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Exclude the date in the file name.")]
        [Alias("ND")][switch]$NoDate,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Only the date in file name.")]
        [Alias("JD")][switch]$JustDate,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Move similar files to an 'old' directory if similar files exist.")]
        [Alias("M")][switch]$Move,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Return just the file name with no path or timestamp.")]
        [Alias("FL")][switch]$FlatName,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Omit the file extension from the output.")]
        [Alias("NE")][switch]$NoExtension
    )

    begin {
        # Helper functions are defined once here so they are not redefined on every pipeline input.

        function GetScriptName {
            Try {
                $callStack = Get-PSCallStack
                $modulePath = $callStack[0].ScriptName  # path to MRNAP.psm1
                foreach ($frame in $callStack) {
                    if ([string]::IsNullOrWhiteSpace($frame.ScriptName)) { continue }
                    if ($frame.ScriptName -eq $modulePath) { continue }
                    return [IO.Path]::GetFileNameWithoutExtension((Split-Path $frame.ScriptName -Leaf))
                }
                return $null  # No script frame found — running interactively
            }
            catch {
                return $null
            }
        }

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
    }

    process {
        $timestamp = ""

        # Set default report name if not provided
        if ([string]::IsNullOrWhiteSpace($ReportName) -and (-not $JustDate -or ($JustDate -and $NoDateTimeSeconds))) {
            $ScriptName = GetScriptName
            if ([string]::IsNullOrWhiteSpace($ScriptName)) {
                $ReportName = GetRandomWord
            }
            else {
                $ReportName = $ScriptName
            }
        }

        # Set default directory name if not provided
        if ([string]::IsNullOrWhiteSpace($DirectoryName)) {
            $DirectoryName = [IO.Path]::Combine($HOME, "Reports")
        }
        elseif (-not [IO.Path]::IsPathRooted($DirectoryName)) {
            # Relative path supplied — root it with the platform separator (\ on Windows, / on Linux/macOS)
            $DirectoryName = [IO.Path]::DirectorySeparatorChar + $DirectoryName
        }

        # Ensure the extension starts with a dot
        if (-not $NoExtension -and -not $Extension.StartsWith(".")) {
            $Extension = ".$Extension"
        }

        # Build the basic report name with extension
        $ReportNameExt = if ($NoExtension) { $ReportName } else { "$ReportName$Extension" }

        # Short-circuit for flat name: return just the filename with no path or timestamp
        if ($FlatName) {
            return [string]$ReportNameExt
        }

        # Format the timestamp based on the specified options
        if (-not $NoDateTimeSeconds) {
            $timestampFormat = "yyyy_MM_dd-"

            if ($AddTime) {
                $timestampFormat = "yyyy_MM_ddTHHmmss-"
            }
            elseif ($JustDate) {
                $timestampFormat = "yyyy_MM_dd"
            }
            elseif ($NoSeconds) {
                $timestampFormat = "yyyy_MM_ddTHHmm-"
            }

            if ($UTC) {
                # Handle UTC formatting for NoDate case
                if ($JustDate) {
                    $timestamp = (Get-Date).ToUniversalTime().ToString($timestampFormat)  # Only date in UTC
                }
                elseif ($NoDate) {
                    $fmt = if ($NoSeconds) { "HHmm-" } else { "HHmmss-" }
                    $timestamp = (Get-Date).ToUniversalTime().ToString($fmt)  # Only time in UTC, no date
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
                    $fmt = if ($NoSeconds) { "HHmm-" } else { "HHmmss-" }
                    $timestamp = (Get-Date).ToString($fmt)  # Local time with no date
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
        $FullPath = Join-Path $DirectoryName "$timestamp$ReportNameExt"

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
                $items = @()
                try {
                    $items = Get-ChildItem -Path $DirectoryName -Filter $ReportNameExt -File -ErrorAction Stop -Force
                }
                catch {
                    Write-Warning "Unable to list files in $DirectoryName."
                }

                if ($items.count -gt 0) {
                    $oldDirectory = Join-Path $DirectoryName "old"

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
