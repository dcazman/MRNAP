try {
    $filename = [System.IO.Path]::Combine(
        $home,
        (Get-Date).ToString("yyyy-MM-dd_") + 
        [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path) + ".csv"
    )
} catch {
    Write-Error "Failed to generate filename: $_"
}

# or

$filename = $home + [IO.Path]::DirectorySeparatorChar + (Get-Date).ToString("yyyy-MM-dd_") + [System.IO.Path]::GetFileName($MyInvocation.MyCommand.Path) -replace '\.[^.]+$','.csv'

# either option above will try to create a filename based on the running script name.
