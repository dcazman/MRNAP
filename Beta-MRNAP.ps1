<#
.SYNOPSIS
Mold Report Name And Path. Options include no date and time, no seconds with date and time, utc time.
Extension is default csv and the default directory is C:\Reports.
Additionally -Move will try to move out files of similar reportname to a nested directory named old example with default is
C:\Reports\Old.
Designed to work on Windows OS.

.PARAMETER ReportName, DirectoryName, UTC, Extension, NoDateTimeSeconds, NoSeconds, JustDate, NoSeperators and Move
-ReportName (name of report).
-DirectoryName (Default is C:\Reports) but anything can be the directory with this switch followed by the directory
name. -DirectoryName Test (is C:\test) or -DirectoryName Z:\temp (is z:\temp) or -DirectoryName B:\ (is B:\).
-UTC makes the DateTime Universal Time.
-Extension (Default is .csv) but can be anything with this switch followed by an extension name. -Extension .txt 
or -Extension txt.
-NoDateTimeSeconds makes a filename with the default directory unless directoryname switch. Example C:\reports\test.csv.
-NoSeconds makes a filename with the default directory unless directoryname switch and string are used. Date Time does not
include seconds C:\reports\yyyy_MM_ddThhmm-test.csv.
-JustDate creates the filename and directory without time. Example C:\reports\yyyy_MM_ddThhmm.csv.
-NoSeperators makes the file name without any dashs. Example C:\reports\yyyyMMddThhmmss.csv.
-Move checks if simlar files with the reportname exist in the directory and if so moves out the similar files to a nested old 
directory.

.NOTES
The goal of this function is to generate unique report names. IThis function will help make a readable
filename and try move old files of similar name from the directory to a nested directory. 
If you need a unique file name this function will help. 
Designed to work on Windows OS.

.EXAMPLE
Run this function like the following
  MRNAP -ReportName Name
  (C:\reports\yyyy_MM_ddThhmmss-name.csv).

  MRNAP -ReportName Name -NoSeconds
  (produces C:\reports\yyyy_MM_ddThhmm-name.csv).

  MRNAP -ReportName Name -NoDateTimeSeconds -Move
  (C:\reports\name.csv and anything with name.csv will move to old directory).

  MRNAP -ReportName Name -Extension .txt -Move -DirectoryName B:\test
  (B:\test\yyyy_MM_ddThhmmss-name.txt and anything with *name.txt will move to old directory b:\test\old).

  MRNAP
  (produces C:\reports\yyyy_MM_ddThhmmss.csv).
#>
Function MRNAP {
    [alias("MoldReportNameAndPath")]
    param(
        [parameter(Mandatory = $False)][string]$ReportName,
        [parameter(Mandatory = $False)][string]$DirectoryName = "C:\Reports",
        [parameter(Mandatory = $False)][string]$Extension = ".csv",
        [parameter(Mandatory = $False)][switch]$UTC,
        [parameter(Mandatory = $False)][switch]$NoSeperators,
        [parameter(Mandatory = $False)][switch]$JustDate,
        [parameter(Mandatory = $False)][switch]$NoSeconds,
        [parameter(Mandatory = $False)][switch]$NoDateTimeSeconds,
        [parameter(Mandatory = $False)][switch]$Move
    )
   
    <# ver 7, Author Dan Casmas 7/2021. Designed to work on Windows OS.
    Has only been tested with 5.1 and 7 PS Versions. Requires a minimum of PS 5.1 #>
    #Requires -Version 5.1

    # Check for a value in ReportName string if NoDateTimeSeconds switch is used
    If ([string]::IsNullOrWhiteSpace($ReportName) -and $NoDateTimeSeconds) {
        Write-Warning 'ReportName needs a value to use NoDateTimeSeconds switch'
        Return $null
    }

    # Extension Section. Checks for a perion if the default is not used
    If ($Extension -ne ".csv") {
        If (!($Extension.contains("."))) {
            $Extension = '.' + $Extension
        }
    }

    # This mini function is courtesy of the https://stackoverflow.com/ community
    # Because Join-Path won't work with drive letters that don't exist
    function Join-AnyPath {
        Return ($Args -join '\') -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
    }

    # Test for C:\ or nothing. Skip if directory has :\ 
    If (!($DirectoryName -like ('?:\*'))) {
        $DirectoryName = Join-AnyPath 'c:\' $DirectoryName
    }

    # If no entry for ReportName string then add a place holder with a flag
    If ([string]::IsNullOrWhiteSpace($ReportName)) {
        $ReportName = '1H0LD'
        $EmptyReportName = $true
    }

    #Forums the basic reportname with extension
    $ReportNameExt = "$ReportName" + "$Extension"
    $fullPath = $null   

    # FlatName Section
    If ($NoDateTimeSeconds) {
        $fullPath = Join-AnyPath $DirectoryName $ReportNameExt
    }

    # Just The Date Section
    if ($JustDate -and $null -eq $fullPath) {
        If ($NoSeperators) {
            $Dash = "yyyyMMdd"
        }
        Else {
            $Dash = "yyyy_MM_dd-"
        }

        if ($UTC) {
            $fullPath = Join-AnyPath $DirectoryName ((Get-Date).ToUniversalTime().ToString("$Dash") + ($ReportNameExt))
        }
        Else {
            $fullPath = Join-AnyPath $DirectoryName ((Get-Date).ToString("$Dash") + ($ReportNameExt))
        }
    }

    # No seconds section
    If ($NoSeconds -and $null -eq $fullPath) {
        If ($NoSeperators) {
            $Dash = "yyyyMMddThhmm"
        }
        Else {
            $Dash = "yyyy_MM_ddThhmm-"
        }

        if ($UTC) {
            $fullPath = Join-AnyPath $DirectoryName ((get-date).ToUniversalTime().ToString("$Dash") + ($ReportNameExt))
        }
        Else {
            $fullPath = Join-AnyPath $DirectoryName ((Get-Date).ToString("$Dash") + ($ReportNameExt))
        }
    }

    # Default section
    If ($null -eq $fullPath) {
        If ($NoSeperators) {
            $Dash = "yyyyMMddThhmmss"
        }
        Else {
            $Dash = "yyyy_MM_ddThhmmss-"
        }

        If ($UTC) {
            $fullPath = Join-AnyPath $DirectoryName ((Get-Date).ToUniversalTime().ToString("$Dash") + ($ReportNameExt))
        }
        Else {
            $fullPath = Join-AnyPath $DirectoryName ((Get-Date).ToString("$Dash") + ($ReportNameExt))
        }
    }

    # Check for place holder flag. If there remove remove 1H0LD placeholder.
    If ($EmptyReportName) {
        Try {
            $fullPath = $fullPath.replace('-', '').replace('1H0LD', '')
        }
        Catch {
            $fullPath = $fullPath.replace('1H0LD', '')
        }
    }
 
    #===============Move section. This tries to move out file(s) like the reportname into an old directory
    If ($Move) {
        #Checks for DirectoryName and not there tries to create it
        If (!(test-path $DirectoryName)) {
            Try {
                New-Item -Path $DirectoryName -ItemType Directory -ErrorAction SilentlyContinue -Force | Out-Null
            }
            Catch {
                Write-Warning "Problem trying to create $DirectoryName."
                Return [string]$fullPath
            }
            Return [string]$fullPath
        }
   
        <# Checks is there any similar files to move and if not skips moving. If found tries to move the similar file(s) to
        a nested direction named old. #>
        $MoveTest = Get-Childitem -path $DirectoryName -filter ('*' + $ReportNameExt) -file -ErrorAction SilentlyContinue
        If ($MoveTest) {
            $DirectoryNameOld = Join-AnyPath $DirectoryName 'old'
            # test if nested old directory exists and if not tries to create it
            If (!(Test-Path $DirectoryNameOld)) {
                Try {
                    New-Item -Path $DirectoryNameOld -ItemType Directory -ErrorAction SilentlyContinue -Force | Out-Null
                }
                Catch {
                    Write-Warning "Problem trying to create $DirectoryNameOld."
                    Return [string]$fullPath
                }
            }
           
            Try {
                # Tries to move similar named files to the nested old directory
                Move-Item -Path ($DirectoryName + '\*' + $ReportNameExt) -Destination $DirectoryNameOld -ErrorAction SilentlyContinue -Force | Out-Null
            }
            Catch {
                Write-Warning "Problem trying to move files named like $ReportNameExt to $DirectoryNameOld"
                Return [string]$fullPath
            }
        }
    }
    #=============Return the filename with path and end this function======================#
    Return [string]$fullPath
}