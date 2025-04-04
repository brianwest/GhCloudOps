Describe 'Convert-Token' {
	BeforeAll {
		$repoRoot = Split-Path -Path $PSScriptRoot -Parent
		$modulePath = Join-Path -Path $repoRoot -ChildPath 'src' -AdditionalChildPath 'GhCloudOps.psm1'
		Import-Module -Name $modulePath -Force

		$helperPath = Join-Path -Path $repoRoot -ChildPath 'tests' -AdditionalChildPath 'helpers'
		$script:bicepFile = Join-Path -Path $helperPath -ChildPath 'test.bicepparam'
		$script:bicepOutputFile = Join-Path -Path 'TestDrive:' -ChildPath 'expanded.bicepparam'
		$script:terraformFile = Join-Path -Path $helperPath -ChildPath 'test.tfvars'
		$script:terraformOutputFile = Join-Path -Path 'TestDrive:' -ChildPath 'expanded.tfvars'
		$script:jsonFile = Join-Path -Path $helperPath -ChildPath 'test.json'
		$script:jsonOutputFile = Join-Path -Path 'TestDrive:' -ChildPath 'expanded.json'
		$script:psd1File = Join-Path -Path $helperPath -ChildPath 'test.psd1'
		$script:psd1OutputFile = Join-Path -Path 'TestDrive:' -ChildPath 'expanded.psd1'
		$script:unsupportedFile = Join-Path -Path $helperPath -ChildPath 'test.txt'
		$script:unsupportedOutputFile = Join-Path -Path 'TestDrive:' -ChildPath 'expanded.txt'

		$script:pattern = '\{\{[^\}]+\}\}'

		$tokenMap = @{
			name     = 'test'
			count    = 1
			enabled  = $true
			identity = $null
		}

		$tempFile = Join-Path 'TestDrive:' -ChildPath 'tempfile.tmp'
		Mock -CommandName 'New-TemporaryFile' -ModuleName 'GhCloudOps' -MockWith { New-Item -ItemType File -Path $tempFile -Force }
		Mock -CommandName 'Write-Error' -ModuleName 'GhCloudOps'
		Mock -CommandName 'Write-Warning' -ModuleName 'GhCloudOps'
		Mock -CommandName 'Write-Host' -ModuleName 'GhCloudOps'
	}

	Context 'When parameters are properly configured' {
		It 'Should have InputFile as a mandatory string parameter' {
			Get-Command -Name 'Convert-Token' | Should -HaveParameter 'InputFile' -Type 'string' -Mandatory
		}

		It 'Should have OutputFile as a mandatory string parameter' {
			Get-Command -Name 'Convert-Token' | Should -HaveParameter 'OutputFile' -Type 'string' -Mandatory
		}

		It 'Should have TokenMap as a mandatory hashtable parameter' {
			Get-Command -Name 'Convert-Token' | Should -HaveParameter 'TokenMap' -Type 'hashtable' -Mandatory
		}
	}

	Context 'When parameter file has a bicepparam file extension' {
		BeforeAll {
			$script:bicepParams = @{
				InputFile  = $bicepFile
				OutputFile = $bicepOutputFile
				TokenMap   = $tokenMap
			}

			Convert-Token @bicepParams
			$script:unmatchedTokens = Select-String -Path $bicepOutputFile -Pattern $pattern -AllMatches
		}

		It 'Should replace tokens with tokenized values' {
			$unmatchedTokens | Should -BeNullOrEmpty
		}

		It 'Should not write a warning' {
			Should -Not -Invoke 'Write-Warning' -Scope 'Context' -ModuleName 'GhCloudOps'
		}

		It 'Should notify the user that tokens were replaced' {
			Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GhCloudOps' -ParameterFilter {
				$Object -eq ("Converted tokens in '{0}' to '{1}'" -f $bicepFile, $bicepOutputFile)
			}
		}
	}

	Context 'When parameter file has a tfvars file extension' {
		BeforeAll {
			$terraformParams = @{
				InputFile  = $terraformFile
				OutputFile = $terraformOutputFile
				TokenMap   = $tokenMap
			}

			Convert-Token @terraformParams
			$script:unmatchedTokens = Select-String -Path $terraformOutputFile -Pattern $pattern -AllMatches
		}

		It 'Should replace tokens with tokenized values' {
			$unmatchedTokens | Should -BeNullOrEmpty
		}

		It 'Should not write a warning' {
			Should -Not -Invoke 'Write-Warning' -Scope 'Context' -ModuleName 'GhCloudOps'
		}

		It 'Should notify the user that tokens were replaced' {
			Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GhCloudOps' -ParameterFilter {
				$Object -eq ("Converted tokens in '{0}' to '{1}'" -f $terraformFile, $terraformOutputFile)
			}
		}
	}

	Context 'When parameter file has a json file extension' {
		BeforeAll {
			$jsonParams = @{
				InputFile  = $jsonFile
				OutputFile = $jsonOutputFile
				TokenMap   = $tokenMap
			}

			Convert-Token @jsonParams
			$script:unmatchedTokens = Select-String -Path $jsonOutputFile -Pattern $pattern -AllMatches
		}

		It 'Should replace tokens with tokenized values' {
			$unmatchedTokens | Should -BeNullOrEmpty
		}

		It 'Should not write a warning' {
			Should -Not -Invoke 'Write-Warning' -Scope 'Context' -ModuleName 'GhCloudOps'
		}

		It 'Should notify the user that tokens were replaced' {
			Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GhCloudOps' -ParameterFilter {
				$Object -eq ("Converted tokens in '{0}' to '{1}'" -f $jsonFile, $jsonOutputFile)
			}
		}
	}

	Context 'When parameter file has a psd1 file extension' {
		BeforeAll {
			$psd1Params = @{
				InputFile  = $psd1File
				OutputFile = $psd1OutputFile
				TokenMap   = $tokenMap
			}

			Convert-Token @psd1Params
			$script:unmatchedTokens = Select-String -Path $psd1OutputFile -Pattern $pattern -AllMatches
		}

		It 'Should replace tokens with tokenized values' {
			$unmatchedTokens | Should -BeNullOrEmpty
		}

		It 'Should not write a warning' {
			Should -Not -Invoke 'Write-Warning' -Scope 'Context' -ModuleName 'GhCloudOps'
		}

		It 'Should notify the user that tokens were replaced' {
			Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GhCloudOps' -ParameterFilter {
				$Object -eq ("Converted tokens in '{0}' to '{1}'" -f $psd1File, $psd1OutputFile)
			}
		}
	}

	Context 'When output file already exists' {
		BeforeAll {
			Mock -CommandName 'Clear-Content' -ModuleName 'GhCloudOps'

			New-Item -ItemType File -Path $bicepOutputFile -Force

			Convert-Token @bicepParams
		}

		It 'Should clear the contents of the output file' {
			Should -Invoke 'Clear-Content' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GhCloudOps' -ParameterFilter {
				$Path -eq $bicepOutputFile
			}
		}
	}

	Context 'When file extension is not supported' {
		BeforeAll {
			$script:unsupportedParams = @{
				InputFile  = $unsupportedFile
				OutputFile = $unsupportedOutputFile
				TokenMap   = $tokenMap
			}

			$script:item = Get-Item -Path $unsupportedFile
		}

		It 'Should throw an error' {
			{ Convert-Token @unsupportedParams } | Should -Throw -ExpectedMessage ('Unsupported file type: {0}' -f $item.Extension)
		}
	}

	Context 'When tokens are missing from the token map' {
		BeforeAll {
			$unmatchedTokenMap = $tokenMap.Clone()
			$unmatchedTokenMap.Remove('name')
		}

		It 'Should thow' {
			{ Convert-Token -InputFile $bicepFile -OutputFile $bicepOutputFile -TokenMap $unmatchedTokenMap } | Should -Throw
		}

		It 'Should write an error' {
			Should -Invoke 'Write-Error' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GhCloudOps' -ParameterFilter {
				$Message -eq 'Unmatched tokens found' -and
				$ErrorAction -eq 'Continue'
			}
		}
	}

	Context 'When extra tokens are present in the token map' {
		BeforeAll {
			$extraTokenMap = $tokenMap.Clone()
			$extraToken = 'extra'
			$extraTokenMap.Add($extraToken, 'extra')

			Convert-Token -InputFile $bicepFile -OutputFile $bicepOutputFile -TokenMap $extraTokenMap
		}

		It 'Should write a warning' {
			Should -Invoke 'Write-Warning' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GhCloudOps' -ParameterFilter {
				$Message -eq ('Unused tokens: {0}' -f $extraToken)
			}
		}
	}

	Context 'When input file does not exist' {
		It 'Should throw' {
			{ Convert-Token -InputFile 'nonexistent.bicepparam' -OutputFile $bicepOutputFile -TokenMap $tokenMap } | Should -Throw
		}
	}

	Context 'When token map is empty' {
		It 'Should throw' {
			{ Convert-Token -InputFile $bicepFile -OutputFile $bicepOutputFile -TokenMap @{} } | Should -Throw
		}
	}
}
