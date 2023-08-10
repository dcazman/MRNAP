<#
.SYNOPSIS
This function maps a network drive to a specified share on a remote computer.

.DESCRIPTION
The function takes parameters for the remote computer name, share name, and optionally the drive letter to use for mapping. It supports providing credentials for authentication if required.

.PARAMETER ComputerName
The name of the remote computer where the network share resides.

.PARAMETER ShareName
The name of the network share to be mapped.

.PARAMETER Letter
(Optional) The drive letter to use for mapping the network share. If not provided or unavailable, an available letter will be automatically assigned.

.PARAMETER Auth
(Optional) Credentials for authentication, if required.

.NOTES
File system drives can be mapped using this function, and it provides error handling and warnings for various scenarios.

#>
function MapADrive {
    #Requires -Version 5.1
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)][string]$ComputerName,
        [parameter(Mandatory = $true)][string]$ShareName,
        [parameter(Mandatory = $False)][ValidatePattern("[e-z]")][ValidateLength(1, 1)][string]$Letter,
        $Auth = [System.Management.Automation.PSCredential]::Empty
    )

    # Set credentials for authentication if provided
    if ($Auth -ne [System.Management.Automation.PSCredential]::Empty) {
        $Splat = @{
            UserName = $Auth.UserName
            Password = $Auth.Password
        }
    }
  
    # Check if the provided drive letter is available, or assign an available letter
    If (-not $Letter -or (Get-PSDrive $Letter -ErrorAction SilentlyContinue)) {
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
    }

    $Drive = $Letter + ':'

    # Define a function to join paths and handle directory separators
    function Join-AnyPath {
        Return ($Args -join '\') -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
    }
    
    $NameToMap = Join-AnyPath \\ $ComputerName $ShareName

    # Check if the drive is already mapped to the same share
    IF ((Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty DisplayRoot) -contains $NameToMap) {
        $FullMap = Get-PSDrive -PSProvider FileSystem | Select-Object name, Root, DisplayRoot | Where-Object { $_.DisplayRoot -EQ $NameToMap }
        $AlreadyMap = join-anypath $FullMap.root $FullMap.DisplayRoot
        Write-Warning "$AlreadyMap is already mapped"
        $Result = [PSCustomObject]@{
            Letter       = $FullMap.name
            Drive        = $FullMap.Root
            mapping      = $AlreadyMap
            Computername = $ComputerName
            ShareName    = $ShareName
        }
        Return [PSCustomObject]$Result
    }

    # Map the drive with or without authentication based on input
    If ($Auth) {
        New-PSDrive -Name $Letter -Root $NameToMap -PSProvider "FileSystem" -Persist -ErrorAction SilentlyContinue -ErrorVariable ProcessError -Credential @Splat
    }
    Else {
        New-PSDrive -Name $Letter -Root $NameToMap -PSProvider "FileSystem" -Persist -ErrorAction SilentlyContinue -ErrorVariable ProcessError
    }

    # Handle errors that occurred during mapping
    If ($ProcessError) {
        Write-Warning "$Drive to $ComputerName and $ShareName can't be mapped."
        Return $null
    }

    # Construct the final mapped path
    $FinalMap = Join-AnyPath $Drive $ComputerName $ShareName

    # Create and return the result object
    $Result = [PSCustomObject]@{
        Letter       = $Letter
        Drive        = $Drive
        mapping      = $FinalMap
        Computername = $ComputerName
        ShareName    = $ShareName
    }

    Return [PSCustomObject]$Result
}
