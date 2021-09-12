<# This functions adds a slash between two strings. Join-AnyPath Z: Hello (Returns Z:\Hello).
Courtesy of the https://stackoverflow.com/ community. #>
function Join-AnyPath {
    Return ($Args -join '\') -replace '(?!^)([\\/])+', [IO.Path]::DirectorySeparatorChar
}