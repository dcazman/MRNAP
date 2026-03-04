#Requires -Version 5.1
<#
.SYNOPSIS
    Generates a report file name and path with various customizable options.

.DESCRIPTION
    Generates a timestamped report file name and full path. Accepts pipeline input by value
    (a bare string becomes ReportName) and by property name (pipe any object whose properties
    match parameter names). Supports custom directory, extension, UTC or local time, date-only,
    time-only, no-separator mode, automatic archival of existing files, and a configurable
    archive folder name. Works on Windows, Linux, and macOS with PowerShell 5.1 and 7+.

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

.PARAMETER OldFolderName
    Name of the subdirectory used when archiving existing files with -Move. Default: old.
    Accepts pipeline input by property name (OFN).

.PARAMETER TimestampFormat
    Controls what timestamp is prepended to the filename. Accepts pipeline input by property
    name (TF). Valid values:

      DateOnly      yyyy_MM_dd-          (default)
      DateTime      yyyy_MM_ddTHHmmss-
      DateTimeNoSec yyyy_MM_ddTHHmm-
      TimeOnly      HHmmss-
      TimeOnlyNoSec HHmm-
      JustDate      yyyy_MM_dd  (no report name appended)
      None          no timestamp

.PARAMETER UTC
    Use UTC instead of local time for the timestamp.
    Accepts pipeline input by property name.

.PARAMETER NoSeparators
    Remove underscores and dashes from the timestamp portion of the filename.
    Accepts pipeline input by property name (NoSep, NX).

.PARAMETER Move
    Before returning the path, move any file in the destination directory that exactly matches
    <ReportName>.<Extension> to the archive subdirectory (see -OldFolderName). Creates the
    destination and archive directories if they do not exist.
    Accepts pipeline input by property name (M).

.PARAMETER FlatName
    Return just the file name with no directory path and no timestamp.
    Combine with -NoExtension to get a bare name (e.g. "Tom").
    Accepts pipeline input by property name (FL).

.PARAMETER NoExtension
    Omit the file extension from the output. Most useful with -FlatName.
    Accepts pipeline input by property name (NE).

.LINK
    https://github.com/dcazman/MRNAP

.EXAMPLE
    MRNAP -ReportName 'SalesReport'
    Result: ~/Reports/2025_01_15-SalesReport.csv

.EXAMPLE
    MRNAP -ReportName 'SalesReport' -DirectoryName '/srv/data' -Extension 'txt' -UTC -Move
    Result: /srv/data/2025_01_15T213022-SalesReport.txt
    (any existing /srv/data/SalesReport.txt is moved to /srv/data/old/)

.EXAMPLE
    MRNAP -ReportName 'SalesReport' -Move -OldFolderName 'archive'
    Result: ~/Reports/2025_01_15-SalesReport.csv
    (existing SalesReport.csv is moved to ~/Reports/archive/)

.EXAMPLE
    MRNAP -ReportName 'Audit' -TimestampFormat DateTime
    Result: ~/Reports/2025_01_15T143022-Audit.csv

.EXAMPLE
    MRNAP -ReportName 'Audit' -TimestampFormat DateTimeNoSec
    Result: ~/Reports/2025_01_15T1430-Audit.csv

.EXAMPLE
    MRNAP -TimestampFormat JustDate -DirectoryName '~/Archive'
    Result: ~/Archive/2025_01_15.csv

.EXAMPLE
    MRNAP -TimestampFormat None
    Result: ~/Reports/<ScriptName>.csv  or  ~/Reports/<RandomWord>.csv

.EXAMPLE
    MRNAP -ReportName 'MonthlyReport' -UTC -NoSeparators
    Result: ~/Reports/20250115T213022MonthlyReport.csv

.EXAMPLE
    'DailyReport' | MRNAP -DirectoryName '~/Reports'
    Result: ~/Reports/2025_01_15-DailyReport.csv

.EXAMPLE
    [PSCustomObject]@{ ReportName = 'Sales'; DirectoryName = '/tmp/reports'; Move = $true } | MRNAP
    Result: /tmp/reports/2025_01_15-Sales.csv

.EXAMPLE
    'Users', 'Groups', 'Devices' | MRNAP -DirectoryName '~/Reports'
    Results:
      ~/Reports/2025_01_15-Users.csv
      ~/Reports/2025_01_15-Groups.csv
      ~/Reports/2025_01_15-Devices.csv

.NOTES
    Author: Dan Casmas
    Version: 11.0
    Date: 3/2026
    Designed to work on Windows, Linux, and macOS. Tested with PowerShell 5.1 and 7+.
#>
function MRNAP {
    [Alias("MoldReportNameAndPath")]
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "The name of the report. If not specified, the calling script name or a random word is used.")]
        [Alias("RN")][string]$ReportName,

        [parameter(Position = 1, Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Destination directory. Default: ~/Reports.")]
        [Alias("DN")][string]$DirectoryName,

        [parameter(Position = 2, Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "File extension. Default: csv.")]
        [Alias("EXT", "E")][string]$Extension = "csv",

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Archive subfolder name used by -Move. Default: old.")]
        [Alias("OFN")][string]$OldFolderName = "old",

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Timestamp style: DateOnly (default), DateTime, DateTimeNoSec, TimeOnly, TimeOnlyNoSec, JustDate, None.")]
        [Alias("TF")]
        [ValidateSet("DateOnly", "DateTime", "DateTimeNoSec", "TimeOnly", "TimeOnlyNoSec", "JustDate", "None")]
        [string]$TimestampFormat = "DateOnly",

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Use UTC instead of local time.")]
        [switch]$UTC,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Remove underscores and dashes from the timestamp.")]
        [Alias("NoSep", "NX")][switch]$NoSeparators,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Move matching existing files to the archive subdirectory before returning the path.")]
        [Alias("M")][switch]$Move,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Return just the file name — no path, no timestamp.")]
        [Alias("FL")][switch]$FlatName,

        [parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Omit the file extension from the output.")]
        [Alias("NE")][switch]$NoExtension
    )

    begin {
        function GetScriptName {
            try {
                $callStack = Get-PSCallStack
                $modulePath = $callStack[0].ScriptName
                foreach ($frame in $callStack) {
                    if ([string]::IsNullOrWhiteSpace($frame.ScriptName)) { continue }
                    if ($frame.ScriptName -eq $modulePath) { continue }
                    return [IO.Path]::GetFileNameWithoutExtension((Split-Path $frame.ScriptName -Leaf))
                }
                return $null
            }
            catch { return $null }
        }

        function GetRandomWord {
            $words = @(
                'Alpha', 'Ace', 'Bravo', 'Cat', 'Dan', 'Delta', 'Echo', 'Ethan',
                'Foxtrot', 'Golf', 'Hotel', 'India', 'Juliet', 'Kathie', 'Kilo',
                'Lima', 'Mat', 'November', 'Oscar', 'Phil', 'Quebec', 'Romeo',
                'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey', 'X-ray', 'Yoyo',
                'Zachary', 'Zulu'
            )
            return Get-Random -InputObject $words
        }
    }

    process {
        # Resolve report name
        if ([string]::IsNullOrWhiteSpace($ReportName) -and $TimestampFormat -ne "JustDate") {
            $scriptName = GetScriptName
            $ReportName = if ([string]::IsNullOrWhiteSpace($scriptName)) { GetRandomWord } else { $scriptName }
        }

        # Resolve directory
        if ([string]::IsNullOrWhiteSpace($DirectoryName)) {
            $DirectoryName = [IO.Path]::Combine($HOME, "Reports")
        }
        elseif (-not [IO.Path]::IsPathRooted($DirectoryName)) {
            $DirectoryName = [IO.Path]::DirectorySeparatorChar + $DirectoryName
        }

        # Resolve extension
        if (-not $NoExtension -and -not $Extension.StartsWith(".")) {
            $Extension = ".$Extension"
        }

        $ReportNameExt = if ($NoExtension) { $ReportName } else { "$ReportName$Extension" }

        # Short-circuit for flat name
        if ($FlatName) {
            return [string]$ReportNameExt
        }

        # Build timestamp
        $now = if ($UTC) { (Get-Date).ToUniversalTime() } else { Get-Date }

        $timestamp = switch ($TimestampFormat) {
            "DateOnly"      { $now.ToString("yyyy_MM_dd-") }
            "DateTime"      { $now.ToString("yyyy_MM_ddTHHmmss-") }
            "DateTimeNoSec" { $now.ToString("yyyy_MM_ddTHHmm-") }
            "TimeOnly"      { $now.ToString("HHmmss-") }
            "TimeOnlyNoSec" { $now.ToString("HHmm-") }
            "JustDate"      { $now.ToString("yyyy_MM_dd") }
            "None"          { "" }
        }

        if ($NoSeparators) {
            $timestamp = $timestamp -replace "_", "" -replace "-", ""
        }

        # JustDate uses only the timestamp as the filename
        $fileName = if ($TimestampFormat -eq "JustDate") {
            "$timestamp$Extension"
        } else {
            "$timestamp$ReportNameExt"
        }

        $FullPath = Join-Path $DirectoryName $fileName

        # Move existing matching file to archive folder
        if ($Move) {
            if (-not (Test-Path $DirectoryName)) {
                try {
                    New-Item -ItemType Directory -Path $DirectoryName -Force -ErrorAction Stop | Out-Null
                }
                catch {
                    Write-Warning "Unable to create directory: $DirectoryName"
                }
            }
            else {
                $items = @()
                try {
                    $items = Get-ChildItem -Path $DirectoryName -Filter $ReportNameExt -File -Force -ErrorAction Stop
                }
                catch {
                    Write-Warning "Unable to list files in: $DirectoryName"
                }

                if ($items.Count -gt 0) {
                    $oldDirectory = Join-Path $DirectoryName $OldFolderName

                    if (-not (Test-Path $oldDirectory)) {
                        try {
                            New-Item -ItemType Directory -Path $oldDirectory -Force -ErrorAction Stop | Out-Null
                        }
                        catch {
                            Write-Warning "Unable to create archive directory: $oldDirectory"
                        }
                    }

                    try {
                        $items | Move-Item -Destination $oldDirectory -Force -ErrorAction Stop | Out-Null
                    }
                    catch {
                        Write-Warning "Problem moving files to: $oldDirectory"
                    }
                }
            }
        }

        return [string]$FullPath
    }
}
