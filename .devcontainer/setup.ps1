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
$curlParams.ArgumentList = 'install', '-y', 'wget'

Start-Process @curlParams
Write-Host -Object 'Installed wget'

$pwshParams = $commonParams.Clone()
$pwshParams.FilePath = 'wget'
$pwshParams.ArgumentList = 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell_7.5.0-1.deb_amd64.deb'

Start-Process @pwshParams

$pwshDpkgParams = $commonParams.Clone()
$pwshDpkgParams.FilePath = 'dpkg'
$pwshDpkgParams.ArgumentList = '-i', 'powershell_7.5.0-1.deb_amd64.deb'

Start-Process @pwshDpkgParams

$missingDependenciesParmams = $commonParams.Clone()
$missingDependenciesParmams.FilePath = 'apt-get'
$missingDependenciesParmams.ArgumentList = 'install', '-f'

Start-Process @missingDependenciesParmams

$removeDebParams = $commonParams.Clone()
$removeDebParams.FilePath = 'rm'
$removeDebParams.ArgumentList = 'powershell_7.5.0-1.deb_amd64.deb'

Start-Process @removeDebParams
Write-Host -Object 'Installed PowerShell 7.5.0'

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
