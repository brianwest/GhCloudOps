Describe 'Get-TagVersion' {
    BeforeAll {
        $repoRoot = Split-Path -Path $PSScriptRoot -Parent
        $modulePath = Join-Path -Path $repoRoot -ChildPath 'src' -AdditionalChildPath 'GhCloudOps.psm1'
        Import-Module -Name $modulePath -Force

        $commitHash = '1234567890'
        $latestTag = 'v1.0.0'

        Mock -CommandName 'Start-Process' -ModuleName 'GhCloudOps' -MockWith { $commitHash } -ParameterFilter {
            $FilePath -eq 'git' -and
            $ArgumentList -eq @('rev-list', '--tags', '--max-count=1')
        }

        Mock -CommandName 'Start-Process' -ModuleName 'GhCloudOps' -MockWith { $latestTag } -ParameterFilter {
            $FilePath -eq 'git' -and
            $ArgumentList -eq @('describe', '--tags', $commitHash)
        }

        Mock -CommandName 'Write-Host' -ModuleName 'GhCloudOps'
    }

    Context 'When parameters are properly configured' {
        It 'Should have Ref as a mandatory string parameter' {
            Get-Command -Name 'Get-TagVersion' | Should -HaveParameter 'Ref' -Type 'string' -Mandatory
        }

        It 'Should have DefaultVersion as an optional string parameter' {
            Get-Command -Name 'Get-TagVersion' | Should -HaveParameter 'DefaultVersion' -Type 'string' -DefaultValue 'v1.0.0-beta'
        }
    }

    Context 'When the Ref parameter is a version tag' {
        BeforeAll {
            $ref = 'refs/tags/v2.0.0'
            $script:currentTag = $ref.Split('/')[-1]

            $script:result = Get-TagVersion -Ref $ref
        }

        It 'Should notify the user that the version is being set by the ref' {
            Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ParameterFilter {
                $Object -eq ("Version '{0}' is being set by ref '{1}." -f $latestTag, $ref)
            }
        }

        It 'Should return the tag version' {
            $result | Should -Be $currentTag
        }
    }

    Context 'When the Ref parameter is not a version tag' {
        BeforeAll {
            $script:ref = 'refs/tags/invalid'
        }

        It 'Should throw an error' {
            { Get-TagVersion -Ref $ref } | Should -Throw -ExpectedMessage ("The tag '{0}' is not a version tag. Please, use a version tag in the format 'v*.*.*'." -f $ref)
        }
    }

    Context 'When the Ref parameter is not a version tag and a tag is found' {
        BeforeAll {
            $ref = 'refs/heads/main'

            $script:result = Get-TagVersion -Ref $ref
        }

        It 'Should notify the user that the version is being set by the latest tag' {
            Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ParameterFilter {
                $Object -eq ("Version '{0}' is being set by the latest tag." -f $latestTag)
            }
        }

        It 'Should return the latest tag' {
            $result | Should -Be $latestTag
        }
    }

    Context 'When the Ref parameter is not a version tag and no tag is found' {
        BeforeAll {
            Mock -CommandName 'Start-Process' -ModuleName 'GhCloudOps' -MockWith { $null } -ParameterFilter {
                $FilePath -eq 'git' -and
                $ArgumentList -eq @('rev-list', '--tags', '--max-count=1')
            }

            $ref = 'refs/heads/main'
            $defaultVersion = 'v1.0.0-beta'

            $script:result = Get-TagVersion -Ref $ref -DefaultVersion $defaultVersion
        }

        It 'Should notify the user that the version is being set by the default value' {
            Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ParameterFilter {
                $Object -eq ("Version '{0}' is being set by the default value." -f $defaultVersion)
            }
        }

        It 'Should return the default version' {
            $result | Should -Be $defaultVersion
        }
    }
}
