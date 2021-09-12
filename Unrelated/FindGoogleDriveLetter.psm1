<# Returns the drive letter for the google drive if one is mapped #>
function FindGoogleDriveLetter {
    Return [string]( Get-PSDrive | Where-Object { $_.Description -eq 'Google Drive'} ).Name
}