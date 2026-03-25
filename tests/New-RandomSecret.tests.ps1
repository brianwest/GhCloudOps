Describe 'New-RandomSecret' {
    BeforeAll {
        $repoRoot = Split-Path -Path $PSScriptRoot -Parent
        $modulePath = Join-Path -Path $repoRoot -ChildPath 'src' -AdditionalChildPath 'GhCloudOps.psm1'
        Import-Module -Name $modulePath -Force
    }

    Context 'When parameters are properly configured' {
        It 'Should have Length as a mandatory int parameter' {
            Get-Command -Name 'New-RandomSecret' | Should -HaveParameter 'Length' -Type 'int' -Mandatory
        }
    }

    Context 'When generating secrets' {
        It 'Should return a secure string of the specified length' {
            $secureString = New-RandomSecret -Length 16
            $secureString | Should -BeOfType [System.Security.SecureString]
        }
    }

    Context 'When Length is invalid' {
        It 'Should throw for a length lower than 1' {
            { New-RandomSecret -Length 0 } | Should -Throw
        }
    }
}
