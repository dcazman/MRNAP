<#
.SYNOPSIS
Generate a file path for a report with customizable options and parameters.

.DESCRIPTION
The MRNAP function creates a file path for a report based on various options and parameters.
The function allows customization of the report name, destination directory, file extension, and various time-related options.
It can also move similar files to an "old" directory if the Move switch is specified.

.PARAMETER ReportName
The name of the report. If not provided, a placeholder name will be used.

.PARAMETER DirectoryName
The destination directory where the report file will be stored.
The default value is "C:\Reports".

.PARAMETER Extension
The file extension for the report file. The default value is ".csv".

.PARAMETER UTC
Use Coordinated Universal Time (UTC) for the timestamp in the file name.

.PARAMETER NoSeparators
Do not use separators (underscores and dashes) in the timestamp.

.PARAMETER NoSeconds
Exclude seconds from the timestamp.

.PARAMETER JustDate
Include only the date in the timestamp.

.PARAMETER NoDateTimeSeconds
Do not use the timestamp in the file name.

.PARAMETER Move
Move similar files to an "old" directory if they exist.

.Link
https://github.com/dcazman/MRNAP

.EXAMPLE
MRNAP -ReportName "SalesReport" -Extension ".xlsx" -JustDate -Move
Generates a file path for a sales report with the extension ".xlsx" and includes only the date in the timestamp.
If similar files exist, they will be moved to an "old" directory.

.EXAMPLE
MRNAP -ReportName "MonthlyReport" -UTC -NoSeparators
Generates a file path for a monthly report using UTC time and without separators in the timestamp.
#>
function MRNAP {
    [Alias("MoldReportNameAndPath")]
    #Requires -Version 5.1
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $False, HelpMessage = "The name of the report.")]
        [string]$ReportName,

        [parameter(Position = 1, Mandatory = $False, HelpMessage = "The destination directory where the report file will be stored. The default value is 'C:\Reports'.")][string]$DirectoryName = "C:\Reports",

        [parameter(Position = 2, Mandatory = $False, HelpMessage = "The file extension for the report file. The default value is '.csv'.")][string]$Extension = ".csv",

        [parameter(Mandatory = $False, HelpMessage = "Use Coordinated Universal Time (UTC) for the timestamp in the file name.")][switch]$UTC,

        [parameter(Mandatory = $False, HelpMessage = "Do not use separators (underscores and dashes) in the timestamp.")][switch]$NoSeparators,

        [parameter(Mandatory = $False, HelpMessage = "Exclude seconds from the timestamp.")][switch]$NoSeconds,

        [parameter(Mandatory = $False, HelpMessage = "Include only the date in the timestamp.")][switch]$JustDate,

        [parameter(Mandatory = $False, HelpMessage = "Exclude the timestamp in the file name. Must have -ReportName to use")][switch]$NoDateTimeSeconds,

        [parameter(Mandatory = $False, HelpMessage = "Move similar files to an 'old' directory if they exist.")]
        [switch]$Move
    )

    <# ver 8, Author Dan Casmas 8/2023. Designed to work on Windows OS.
    Has only been tested with 5.1 and 7 PS Versions. Requires a minimum of PS 5.1 .#>

    # ---Start of script----

    # Extension Section
    if ($Extension -ne ".csv") {
        if (-not $Extension.StartsWith(".")) {
            $Extension = ".$Extension"
        }
    }

    # Build the basic ReportName with extension.
    $ReportNameExt = "$ReportName$Extension"

    # Handle the case when the ReportName is not provided.
    $EmptyReportNameFlag = [string]::IsNullOrWhiteSpace($ReportName)

    <# This mini function below is courtesy of the https://stackoverflow.com/ community.
    Because Join-Path won't work with drive letters that don't exist. #>
    function Join-AnyPath {
        Return ($Args -join '\') -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
    }

    # Format the full file path based on the specified options.
    if ($NoDateTimeSeconds) {
        if ($EmptyReportNameFlag) {
            Write-Warning 'ReportName needs a value to use the NoDateTimeSeconds switch.'
            return $null
        }
         
        $FullPath = Join-AnyPath $DirectoryName $ReportNameExt
    }
    else {
        # General timestamp
        $timestampFormat = "yyyy_MM_ddTHHmmss-"

        # just date timestamp
        if ($JustDate) {
            $timestampFormat = "yyyy_MM_dd-"
        }
        elseif ($NoSeconds) {
            # no seconds timestamp
            $timestampFormat = "yyyy_MM_ddTHHmm-"
        }

        # convert to utc or standard
        if ($UTC) {
            $timestamp = (Get-Date).ToUniversalTime().ToString($timestampFormat)
        }
        else {
            $timestamp = Get-Date -Format $timestampFormat
        }

        # removes sepeartors
        if ($NoSeparators) {
            $timestamp = ($timestamp -replace "_", "" -replace "-", "")
        }

        # Removed trailing dash if no reportname
        if ($EmptyReportNameFlag) {
            $timestamp = ($timestamp -replace "-", "")
        }

        $FullPath = Join-AnyPath $DirectoryName "$timestamp$ReportNameExt"
    }

    # Move files to "old" directory if specified.
    if ($Move) {
        if ($EmptyReportNameFlag) {
            Write-Warning 'Move cannot move files with an empty ReportName value.'
        }
        else {
            $oldDirectory = Join-AnyPath $DirectoryName "old"
            $dirflag = $true
            if (-not (Test-Path $oldDirectory)) {
                Try {
                    New-Item -ItemType Directory -Path $oldDirectory -Force -ErrorAction Stop
                }
                Catch {
                    Write-Warning "Unable to create directory and move any related files to $oldDirectory"
                    $dirflag = $False
                }
            }
            If ($dirflag) {
                Try {
                    Get-ChildItem -Path $DirectoryName -Filter "*$ReportNameExt" -File -ErrorAction Stop -Force
                    Move-Item -Destination $oldDirectory -ErrorAction stop -Force
                }
                Catch {
                    Write-Warning "Problem moving files to $oldDirectory."
                }
            }
        }
    }

    return [string]$FullPath
}
