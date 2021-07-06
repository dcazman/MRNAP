<#
.SYNOPSIS
  Molds a file name along with a path. Options include no date and time, no seconds with date and time, utc time.
  Extension is default csv and the default directory is C:\Reports.
  Additionally -move will move out files of similar reportname to a nested directory example of default is
  C:\Reports\Old

.PARAMETER ReportName
  -ReportName parameter is required to run this function.
  -ReportName (name of report)

  -DirectoryName (Default is C:\Reports) but anything can be the directory with this switch followed by the directory name. -DirectoryName Test (is C:\test) or -DirectoryName Z:\ (is z:\).
  -UTC makes the DateTime Universal Time
  -Extension (Default is .csv) but can be anything with this switch followed by an extension name. -Extension .txt or -Extension txt
  -NoDateTimeSeconds makes a filename with the default directory unless directoryname switch and string are used.
   C:\reports\test.csv
  -NoSeconds makes a filename with the default directory unless directoryname switch and string are used. Date Time does not
   include seconds C:\reports\yyyy_MM_ddThhmm-test.csv
  -JustDate creates the filename and directory without time.
  -NoSeperators makes the file name without any dashs.
  -Move checks if simlar files with the reportname exist in the directory and if so moves out the similar files to a nested old 
   directory

.NOTES
  The point of this function is to generate unique report names. If you do a logging script this will help make a readable
  name and move old files out of the directory.

.EXAMPLE
  Run this function like the following

  MRNAP -ReportName Name
  (C:\reports\yyyy_MM_ddThhmmss-name.csv)

  MRNAP -ReportName Name -NoSeconds
  (produces C:\reports\yyyy_MM_ddThhmm-name.csv)

  MRNAP -ReportName Name -NoDateTimeSeconds -Move
  (C:\reports\name.csv and anything with name.txt will move to old directory))

  MRNAP -ReportName Name -Extension .txt -Move -DirectoryName B:\test
  (B:\test\yyyy_MM_ddThhmmss-name.txt and anything with -name.txt will move to old directory)
#>
Function MRNAP {
    [alias("MoldReportNameAndPath")]
    param(
        [parameter(Position = 0, Mandatory = $True)][string]$ReportName,
        [parameter(Mandatory = $False)][string]$DirectoryName = "Reports",
        [parameter(Mandatory = $False)][string]$Extension = ".csv",
        [parameter(Mandatory = $False)][switch]$UTC,
        [parameter(Mandatory = $False)][switch]$NoSeperators,
        [parameter(Mandatory = $False)][switch]$JustDate,
        [parameter(Mandatory = $False)][switch]$NoSeconds,
        [parameter(Mandatory = $False)][switch]$NoDateTimeSeconds,
        [parameter(Mandatory = $False)][switch]$Move
    )
   
    # ver 5.3, Author Dan Casmas 7/2021
    
    #Extension Section
    If ($Extension -ne ".csv") {
        If (!($Extension.contains("."))) {
            $Extension = '.' + $Extension
        }
    }

    #Test for C:\ or nothing. Skip if :\ 
    If (!($DirectoryName -like ('?:\*'))) {
        $DirectoryName = join-path -path 'c:\' -childpath $DirectoryName
    }

    $ReportNameExt = "$ReportName" + "$Extension"
    $fullPath = $null

    #FlatName Section
    If ($NoDateTimeSeconds) {
        $fullPath = $DirectoryName = $DirectoryName + '\' + ($ReportNameExt)
    }
    Else {
        # This mini function is courtesy of the https://stackoverflow.com/ community
        # Because Join-Path won't work with drive letters that don't exist
        function Join-AnyPath {
            Return ($Args -join '\') -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
        }
    }

    # Just The Date Section
    if ($JustDate -and $null -eq $fullPath) {
        If ($NoSeperator) {
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

    #No seconds section
    If ($NoSeconds -and $null -eq $fullPath) {
        If ($NoSeperator) {
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
        If ($NoSeperator) {
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
 
    #===============Move section. This moves out files like the reportname into an old directory
    If ($Move) {
        If (!(test-path $DirectoryName)) {
            New-Item -Path $DirectoryName -ItemType Directory -ErrorAction SilentlyContinue -Force | Out-Null
            Return $fullPath
            break script
        }
   
        $MoveTest = Get-Childitem -path $DirectoryName -filter ('*' + ($ReportNameExt)) -file -ErrorAction SilentlyContinue
        If ($MoveTest) {
            $DirectoryNameOld = Join-AnyPath $DirectoryName -ChildPath 'old'
            If (!(Test-Path $DirectoryNameOld)) {
                New-Item -Path $DirectoryNameOld -ItemType Directory -ErrorAction SilentlyContinue -Force | Out-Null
            }
           
            Move-Item -Path ($DirectoryName + '\*' + ($ReportNameExt)) -Destination $DirectoryNameOld -ErrorAction SilentlyContinue -Force | Out-Null
        }
    }
   
    Return $fullPath
}