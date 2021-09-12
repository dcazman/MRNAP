<# Finds a free drive letter. Excludes letters a,b,c, and d. Courtesy of the https://stackoverflow.com/ community. #>
function FreeDriveLetter {
    $AvailableLetter =
    try {
        $null = Get-PSDrive -ErrorAction Stop -Name ([char[]] 'efghijklmnopqrstuvwxyz')
    }
    catch {
        $_.TargetObject
    }
    
    if (-not $AvailableLetter) {
        Write-Warning "No drive letters available."
        Return $null 
    }

    Return [string]$AvailableLetter       
}