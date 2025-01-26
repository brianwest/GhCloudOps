$files = Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 -Recurse

foreach ($file in $files)
{
    . $file.FullName
}
