function Invoke-Step
{
    param
    (
        [Parameter(Mandatory)]
        [string] $Description,

        [Parameter(Mandatory)]
        [scriptblock] $Script
    )

    Write-Host -NoNewline 'Loading ' $Description.PadRight(28)
    & $Script
    Write-Host "`u{2705}" # checkmark emoji
}

[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Write-Host "Loading PowerShell $($PSVersionTable.PSVersion)..." -ForegroundColor DarkMagenta
Write-Host

Set-Alias -Name ls -Value Get-ChildItem

Invoke-Step -Description 'Import-Module' -Script {
    $modulesToImport = @(
        'Terminal-Icons'
        'posh-git'
    )

    Import-Module $modulesToImport
}

Invoke-Step -Description 'Set-PSReadLineOption' -Script {
    Set-PSReadLineOption -EditMode Emacs

    Set-PSReadLineOption -PredictionSource History

    Set-PSReadLineOption -PredictionViewStyle ListView
}

Invoke-Step -Description 'Register-ArgumentCompleter' -Script {
    Register-ArgumentCompleter -CommandName Set-AzContext -ParameterName Subscription -ScriptBlock {
        param
        (
            [string] $CommandName,

            [string] $ParameterName,

            [string] $StringMatch
        )

        (Get-AzSubscription).Where({ $_.Name -like "$StringMatch*" }).Name
    }
}
