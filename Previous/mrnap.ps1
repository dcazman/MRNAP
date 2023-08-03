<#
.SYNOPSIS
Mold Report Name And Path function. Options include report name,directory,no date and time,no seconds with date time,utc time,just date,extension and finally no separators. 
.PARAMETER ReportName,DirectoryName,Extension,UTC,NoSeperators,NoSeconds,JustDate,NoDateTimeSeconds and Move
-ReportName (name of report).
-DirectoryName (Default is C:\Reports) but anything can be the directory with this switch followed by the directory name. -DirectoryName Test (is C:\test) or -DirectoryName Z:\temp (is z:\temp)
or -DirectoryName B:\ (is B:\).
-Extension (Default is .csv) but can be anything with this switch followed by an extension name. -Extension .txt 
or -Extension txt.
-UTC makes the DateTime Universal Time.
-NoSeperators makes the filename without any dashes. Example C:\reports\yyyyMMddThhmmss.csv.
-NoSeconds makes a filename with the default directory unless directoryname switch and string are used. Date Time does not include seconds C:\reports\yyyy_MM_ddThhmm-test.csv.
-JustDate creates the filename and directory without date and time. Example C:\reports\yyyy_MM_dd.csv.
-NoDateTimeSeconds makes a filename with the default directory unless the DirectoryName switch is used. Example C:\reports\test.csv.
-Move checks if similar file(s) with the ReportName exists in the directory and if so tired to moves out the similar files to a nested old directory.
.Description
Mold Report Name And Path function. Options include report name,directory,no date and time,no seconds with date time,utc time,just date,extension and finally no separators. Extension is default .csv and the default directory is C:\Reports.
Additionally -Move will try to move files with similar ReportName to a nested directory named old. Example with the default directory is C:\Reports\Old.
If ReportName does not have a value the NoDateTimeSeconds switch can't be used.
Designed to work on Windows OS.
.NOTES
The goal of this function is to generate unique reports or filenames. This function will help make a readable
filename and tries to move old file(s) of similar name from the directory to a nested directory. 
If you need a unique readable filename this function will help.
If ReportName does not have a value the NoDateTimeSeconds switch can't be used.
Designed to work on Windows OS.
.Link
https://github.com/dcazman/MRNAP
.EXAMPLE
Run MRNAP function like the following
  MRNAP -ReportName Name
  (C:\reports\yyyy_MM_ddThhmmss-name.csv).
  MRNAP -ReportName Name -NoSeconds
  (produces C:\reports\yyyy_MM_ddThhmm-name.csv).
  MRNAP -ReportName Name -NoDateTimeSeconds -Move
  (C:\reports\name.csv and anything with name.csv will move to the old directory C:\reports\old).
  MRNAP -ReportName Name -Extension .txt -Move -DirectoryName B:\test
  (B:\test\yyyy_MM_ddThhmmss-name.txt and anything with *name.txt will move to the old directory
  b:\test\old).
  MRNAP
  (produces C:\reports\yyyy_MM_ddThhmmss.csv).
#>
Function MRNAP {
    [alias("MoldReportNameAndPath")]
    [CmdletBinding()]
    param(
        [parameter(Position = 0, Mandatory = $False)][string]$ReportName,
        [parameter(Position = 1, Mandatory = $False)][string]$DirectoryName = "C:\Reports",
        [parameter(Position = 2, Mandatory = $False)][string]$Extension = ".csv",
        [parameter(Mandatory = $False)][switch]$UTC,
        [parameter(Mandatory = $False)][switch]$NoSeperators,
        [parameter(Mandatory = $False)][switch]$NoSeconds,
        [parameter(Mandatory = $False)][switch]$JustDate,
        [parameter(Mandatory = $False)][switch]$NoDateTimeSeconds,
        [parameter(Mandatory = $False)][switch]$Move
    )
   
    <# ver 7.5,Author Dan Casmas 7/2021. Designed to work on Windows OS.
    Has only been tested with 5.1 and 7 PS Versions. Requires a minimum of PS 5.1 .#>
    #Requires -Version 5.1

    # Check for a value in the ReportName string if NoDateTimeSeconds switch is used.
    If ([string]::IsNullOrWhiteSpace($ReportName) -and $NoDateTimeSeconds) {
        Write-Warning 'ReportName needs a value to use the NoDateTimeSeconds switch.'
        Return $null
    }

    # Extension Section. Checks for a period if the default is not used.
    If ($Extension -ne ".csv") {
        If (!($Extension -like ".*")) {
            $Extension = '.' + $Extension
        }
    }

    <# This mini function below is courtesy of the https://stackoverflow.com/ community.
    Because Join-Path won't work with drive letters that don't exist. #>
    function Join-AnyPath {
        Return ($Args -join '\') -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
    }

    # Test for C:\ or nothing. Skip if DirectoryName string has a charter and : in it.
    If ($DirectoryName -ne "C:\Reports") {
        If (!($DirectoryName -like "*:*")) {
            $DirectoryName = Join-AnyPath 'C:' $DirectoryName
        }
    }

    # If there is no entry for ReportName string then add a placeholder '1H0LD' with a flag.
    If ([string]::IsNullOrWhiteSpace($ReportName)) {
        $ReportName = '1H0LD'
        $EmptyReportNameFlag = $true
    }
    Else {
        $EmptyReportNameFlag = $null
    }

    # Forums the basic ReportName with extension and sets FullPath to null.
    $ReportNameExt = "$ReportName" + "$Extension"
    $FullPath = $null

    # If NoDateTimeSeconds switch is used.
    If ($NoDateTimeSeconds) {
        $FullPath = Join-AnyPath $DirectoryName $ReportNameExt
    }
    Else {
        # test for UTC switch and then related switches below
        If ($UTC) {
            #Test for !noseperators switch
            If (!$NoSeperators) {  
                If ($JustDate) {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToUniversalTime().ToString("yyyy_MM_dd-") + ($ReportNameExt))
                }
                ElseIF ($NoSeconds) { 
                    $FullPath = Join-AnyPath $DirectoryName ((get-date).ToUniversalTime().ToString("yyyy_MM_ddThhmm-") + ($ReportNameExt))
                }
                Else {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToUniversalTime().ToString("yyyy_MM_ddThhmmss-") + ($ReportNameExt))
                }
            }

            If ($NoSeperators) {
                # Remove dash and underscores with NoSeperators switch.
                IF ($JustDate) {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToUniversalTime().ToString("yyyyMMdd") + ($ReportNameExt))
                }
                ElseIF ($NoSeconds) {
                    $FullPath = Join-AnyPath $DirectoryName ((get-date).ToUniversalTime().ToString("yyyyMMddThhmm") + ($ReportNameExt))
                }
                Else {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToUniversalTime().ToString("yyyyMMddThhmmss") + ($ReportNameExt))
                }
            }
        }
        # test for !UTC switch and then related switches
        IF (!$UTC) {
            #Test for !noseperators switch below
            IF (!$NoSeperators) {
                IF ($JustDate) {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToString("yyyy_MM_dd-") + ($ReportNameExt))
                }
                ElseIF ($NoSeconds) {
                    $FullPath = Join-AnyPath $DirectoryName ((get-date).ToString("yyyy_MM_ddThhmm-") + ($ReportNameExt))
                }
                Else {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToString("yyyy_MM_ddThhmmss-") + ($ReportNameExt))
                }
            }
            
            IF ($NoSeperators) {
                # Remove dash and underscores with NoSeperators switch.
                IF ($JustDate) {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToString("yyyyMMdd") + ($ReportNameExt))
                }
                ElseIF ($NoSeconds) {
                    $FullPath = Join-AnyPath $DirectoryName ((get-date).ToString("yyyyMMddThhmm") + ($ReportNameExt))
                }
                Else {
                    $FullPath = Join-AnyPath $DirectoryName ((Get-Date).ToString("yyyyMMddThhmmss") + ($ReportNameExt))
                }
            }
        }
    }

    # Check for placeholder flag. If flag remove 1H0LD placeholder.
    IF ($EmptyReportNameFlag) {
        Try {
            $FullPath = $FullPath.replace('-', '').replace('1H0LD', '')
        }
        Catch {
            $FullPath = $FullPath.replace('1H0LD', '')
        }
    }
    
    #===============Move section. This tries to move file(s) like the ReportName into an old nested directory.
    IF ($Move) {
        <# Checks for DirectoryName and if not there tries to create it. No need to do anything 
        else if output directory does not exist. #>
        $ProcessError = $null
        IF (!(test-path $DirectoryName)) {
            $Dircreate = New-Item -ItemType Directory -Force -Path $($DirectoryName.Substring(0, 3)) -Name $($DirectoryName.Substring(3)) -ErrorAction SilentlyContinue -ErrorVariable ProcessError | Out-Null

            If ($ProcessError) {
                Write-Warning "Problem trying to create $DirectoryName."
                [bool]$Created = $False
            }
            Else {
                [bool]$Created = $true
            }
        }

        If ($Created) {
            $Dircreate | Out-Null
            If ($FullPath -as [string]) {
                Return [string]$FullPath
            }
            Else {
                Return [string]$FullPath[1]
            }
        }
       
        <# Checks if there are any similar file(s) to move and if not skips moving. If found tries to move the similar file(s) to a nested direction named old.  Does not work without a ReportName value #>
        If ($null -eq $EmptyReportNameFlag) {
            $MoveTest = Get-Childitem -path $DirectoryName -filter ('*' + $ReportNameExt) -file -ErrorAction SilentlyContinue -ErrorVariable ProcessError
            If ($MoveTest -and (-not $ProcessError)) {
                $DirectoryNameOld = Join-AnyPath $DirectoryName 'old'
                # test if a nested old directory exists and if not try to create it.
                If (!(Test-Path $DirectoryNameOld)) {
                    $Dircreate = New-Item -ItemType Directory -Force -Path $DirectoryNameOld.Substring(0, 3) -Name $DirectoryNameOld.Substring(3) -ErrorAction SilentlyContinue -ErrorVariable ProcessError | Out-Null
                    #New-Item -Path $DirectoryNameOld -ItemType Directory -ErrorAction SilentlyContinue -ErrorVariable ProcessError -Force
                    If ($ProcessError) {
                        Write-Warning "Problem trying to create $DirectoryNameOld"
                        Return [string]$FullPath
                    }
                }
               
                # Tries to move similar named files to the nested old directory.
                Move-Item -Path ($DirectoryName + '\*' + $ReportNameExt) -Destination $DirectoryNameOld -ErrorAction SilentlyContinue -ErrorVariable ProcessError -Force
                If ($ProcessError) {
                    Write-Warning "Problem trying to move files named like $ReportNameExt to $DirectoryNameOld"
                    Return [string]$FullPath
                }
            }
            ElseIf ($MoveTest -and $ProcessError) {
                Write-Warning "Problem searching for files"
                Return [string]$FullPath
            }
        }
        Else {
            Write-Warning 'Move can not move files with the -ReportName value empty.'
        }
    }
    #=============Return the filename with path and end this function.======================#
    Return [string]$FullPath
}
