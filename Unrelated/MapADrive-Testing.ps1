<#In testing#>
function MapADrive {
    param (
        [parameter(Mandatory = $true)][string]$ComputerName,
        [parameter(Mandatory = $true)][string]$ShareName,
        [parameter(Mandatory = $False)][ValidatePattern("[e-z]")][ValidateLength(1, 1)][string]$Letter,
        $Auth = [System.Management.Automation.PSCredential]::Empty
    )

    if ($Auth -ne [System.Management.Automation.PSCredential]::Empty) {
        $Splat = @{
            UserName = $Auth.UserName
            Password = $Auth.Password
        }
    }
  
    If (!$Letter -or (Get-PSDrive $Letter -ErrorAction SilentlyContinue)) {
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

    function Join-AnyPath {
        Return ($Args -join '\') -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
    }
    
    $NameToMap = Join-AnyPath \\ $ComputerName $ShareName

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

    If ($Auth) {
        New-PSDrive -Name $Letter -Root $NameToMap -PSProvider "FileSystem" -Persist -ErrorAction SilentlyContinue -ErrorVariable $ProcessError -Credential @Splat

    }
    Else {
        New-PSDrive -Name $Letter -Root $NameToMap -PSProvider "FileSystem" -Persist -ErrorAction SilentlyContinue -ErrorVariable $ProcessError
    }

    If ($ProcessError) {
        Write-Warning "$Drive to $ComputerName and $ShareName can't be mapped."
        Return $null
    }

    $FinalMap = Join-AnyPath $Drive $ComputerName $ShareName

    $Result = [PSCustomObject]@{
        Letter       = $Letter
        Drive        = $Drive
        mapping      = $FinalMap
        Computername = $ComputerName
        ShareName    = $ShareName
    }

    Return [PSCustomObject]$Result
}