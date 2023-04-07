$YesNoResponse = $null
while ($YesNoResponse -ne "y" -and $YesNoResponse -ne "n") {
    Clear-Host
    write-host "Hit enter to break script. "  -ForegroundColor Magenta -NoNewline
    Write-Host "Do something?." -ForegroundColor Blue -NoNewline
    $YesNoResponse = Read-Host " [Y/N] "
    If ([string]::IsNullOrWhiteSpace($YesNoResponse)) {
        Return Write-Host "Enter was inputted" -ForegroundColor Black -BackgroundColor White
    }
}
