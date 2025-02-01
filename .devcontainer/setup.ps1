$commonParams = @{
    Wait        = $true
    NoNewWindow = $true
}

$crlfParams = $commonParams.Clone()
$crlfParams.FilePath = 'git'
$crlfParams.ArgumentList = 'config', '--global', 'core.autocrlf', 'true'

Start-Process @crlfParams
Write-Host -Object 'Configured git to use CRLF line endings'

$eolParams = $commonParams.Clone()
$eolParams.FilePath = 'git'
$eolParams.ArgumentList = 'config', '--global', 'core.eol', 'crlf'

Start-Process @eolParams
Write-Host -Object 'Configured git to use CRLF line endings'

Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'
Install-Module -Name 'InvokeBuild' -Force
