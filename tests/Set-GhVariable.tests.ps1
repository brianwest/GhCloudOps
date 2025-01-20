Describe 'Set-GhVariable' {
    BeforeAll {
        $repoRoot = Split-Path -Path $PSScriptRoot -Parent
        $modulePath = Join-Path -Path $repoRoot -ChildPath 'GitHubTools.psm1'
        Import-Module -Name $modulePath -Force

        $ghTemp = Join-Path -Path 'TestDrive:' -ChildPath 'ghtemp'
        $tempFile = New-Item -ItemType File -Path $ghTemp -Force
        $originalEnv = $env:GITHUB_ENV
        $env:GITHUB_ENV = $tempFile.FullName
    }

    Context 'When paramters are configured correctly' {
        It 'Should have Name as a mandatory string parameter' {
            Get-Command -Name 'Set-GhVariable' | Should -HaveParameter 'Name' -Type 'string' -Mandatory
        }

        It 'Should have Value as a mandatory string parameter' {
            Get-Command -Name 'Set-GhVariable' | Should -HaveParameter 'Value' -Type 'string' -Mandatory
        }
    }

    Context 'When setting variables' {
        BeforeAll {
            $value1 = 'value1'
            $value2 = 'test*&^%$#@!'

            Set-GhVariable -Name 'VAR1' -Value $value1
            Set-GhVariable -Name 'VAR2' -Value $value2

            $content = Get-Content $env:GITHUB_ENV
        }

        It 'Should create multiple variables' {
            $content[0] | Should -BeExactly ('VAR1={0}' -f $value1)
            $content[1] | Should -BeExactly ('VAR2={0}' -f $value2)
        }
    }

    AfterAll {
        $env:GITHUB_ENV = $originalEnv
    }
}
