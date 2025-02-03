$commonParams = @{
    Wait        = $true
    NoNewWindow = $true
}

$modules = @(
    'InvokeBuild'
    'Terminal-Icons'
    'posh-git'
)

$customProfilePath = Join-Path -Path $PSScriptRoot -ChildPath 'profile.ps1'
$vsCodeProfile = ($PROFILE).Replace('Microsoft.PowerShell', 'Microsoft.VSCode')

$aptUpdateParams = $commonParams.Clone()
$aptUpdateParams.FilePath = 'apt-get'
$aptUpdateParams.ArgumentList = 'update'

Start-Process @aptUpdateParams
Write-Host -Object 'Updated apt-get repositories'

$curlParams = $commonParams.Clone()
$curlParams.FilePath = 'apt-get'
$curlParams.ArgumentList = 'install', '-y', 'curl'

Start-Process @curlParams
Write-Host -Object 'Installed curl'

$crlfParams = $commonParams.Clone()
$crlfParams.FilePath = 'git'
$crlfParams.ArgumentList = 'config', '--global', 'core.autocrlf', 'true'

Start-Process @crlfParams
Write-Host -Object 'Configured git to automatically convert line endings'

$eolParams = $commonParams.Clone()
$eolParams.FilePath = 'git'
$eolParams.ArgumentList = 'config', '--global', 'core.eol', 'crlf'

Start-Process @eolParams
Write-Host -Object 'Configured git to use CRLF line endings'

Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'
Write-Host -Object 'Trusted PSGallery'

Install-Module -Name $modules -Force
Write-Host -Object ('Installed {0}' -f ($modules -join ', '))

$null = New-Item -ItemType File -Path $vsCodeProfile -Force
Set-Content -Path $vsCodeProfile -Value (Get-Content -Path $customProfilePath)
Write-Host -Object ("Created profile '{0}' from '{1}'" -f $vsCodeProfile, $customProfilePath)
