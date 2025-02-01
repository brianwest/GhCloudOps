Describe 'Set-RandomKeyVaultSecret' {
    BeforeAll {
        $repoRoot = Split-Path -Path $PSScriptRoot -Parent
        $modulePath = Join-Path -Path $repoRoot -ChildPath 'src' -AdditionalChildPath 'AzGhOps.psm1'
        Import-Module -Name $modulePath -Force

        Mock -CommandName 'Set-AzKeyVaultSecret' -ModuleName 'AzGhOps'
        Mock -CommandName 'Write-Host' -ModuleName 'AzGhOps'
    }

    Context 'When parameters are properly configured' {
        It 'Should have KeyVaultName as a mandatory string parameter' {
            Get-Command -Name 'Set-RandomKeyVaultSecret' | Should -HaveParameter 'KeyVaultName' -Type 'string' -Mandatory
        }

        It 'Should have SecretName as a mandatory string parameter' {
            Get-Command -Name 'Set-RandomKeyVaultSecret' | Should -HaveParameter 'SecretName' -Type 'string' -Mandatory
        }

        It 'Should have Length as a mandatory int parameter' {
            Get-Command -Name 'Set-RandomKeyVaultSecret' | Should -HaveParameter 'Length' -Type 'int' -Mandatory
        }
    }

    Context 'When generating secrets' {
        BeforeAll {
            $vault = 'testvault'
            $secret = 'testsecret'

            $testParams = @{
                KeyVaultName = $vault
                SecretName   = $secret
                Length       = 16
            }

            Set-RandomKeyVaultSecret @testParams
        }

        It 'Should set the secret in the key vault' {
            Should -Invoke 'Set-AzKeyVaultSecret' -Times 1 -Exactly -Scope 'Context' -ModuleName 'AzGhOps' -ParameterFilter {
                $VaultName -eq $vault -and
                $Name -eq $secret -and
                $SecretValue.GetType().Name -eq 'SecureString'
            }
        }

        It 'Should notify the user that the secret has been set' {
            Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ModuleName 'AzGhOps' -ParameterFilter {
                $Object -eq ("Secret '{0}' set in Key Vault '{1}'." -f $secret, $vault)
            }
        }
    }
}
