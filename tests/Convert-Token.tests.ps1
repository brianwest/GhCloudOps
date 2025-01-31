Describe 'Convert-Token' {
	BeforeAll {
		$repoRoot = Split-Path -Path $PSScriptRoot -Parent
		$modulePath = Join-Path -Path $repoRoot -ChildPath 'src' -AdditionalChildPath 'GitHubTools.psm1'
		Import-Module -Name $modulePath -Force

		$helperPath = Join-Path -Path $repoRoot -ChildPath 'tests' -AdditionalChildPath 'helpers'
		$inputFile = Join-Path -Path $helperPath -ChildPath 'test.bicepparam'
		$outputFile = Join-Path -Path 'TestDrive:' -ChildPath 'expanded.bicepparam'

		$tokenMap = @{
			name     = 'test'
			count    = 1
			enabled  = $true
			identity = $null
		}

		$tempFile = Join-Path 'TestDrive:' -ChildPath 'tempfile.tmp'
		Mock -CommandName 'New-TemporaryFile' -ModuleName 'GitHubTools' -MockWith { New-Item -ItemType File -Path $tempFile -Force }
		Mock -CommandName 'Write-Error' -ModuleName 'GitHubTools'
		Mock -CommandName 'Write-Warning' -ModuleName 'GitHubTools'
		Mock -CommandName 'Write-Host' -ModuleName 'GitHubTools'
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

	Context 'When tokens match tokenized values' {
		BeforeAll {
			Convert-Token -InputFile $inputFile -OutputFile $outputFile -TokenMap $tokenMap
			$pattern = '\{\{[^\}]+\}\}'
			$unmatchedTokens = Select-String -Path $outputFile -Pattern $pattern -AllMatches
		}

		It 'Should replace tokens with tokenized values' {
			$unmatchedTokens | Should -BeNullOrEmpty
		}

		It 'Should not write a warning' {
			Should -Not -Invoke 'Write-Warning' -Scope 'Context' -ModuleName 'GitHubTools'
		}

		It 'Should notify the user that tokens were replaced' {
			Should -Invoke 'Write-Host' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GitHubTools' -ParameterFilter {
				$Object -eq ("Converted tokens in '{0}' to '{1}'" -f $inputFile, $outputFile)
			}
		}
	}

	Context 'When output file already exists' {
		BeforeAll {
			Mock -CommandName 'Clear-Content' -ModuleName 'GitHubTools'

			New-Item -ItemType File -Path $outputFile -Force

			Convert-Token -InputFile $inputFile -OutputFile $outputFile -TokenMap $tokenMap
		}

		It 'Should clear the contents of the output file' {
			Should -Invoke 'Clear-Content' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GitHubTools' -ParameterFilter {
				$Path -eq $outputFile
			}
		}
	}

	Context 'When tokens are missing from the token map' {
		BeforeAll {
			$unmatchedTokenMap = $tokenMap.Clone()
			$unmatchedTokenMap.Remove('name')
		}

		It 'Should thow' {
			{ Convert-Token -InputFile $inputFile -OutputFile $outputFile -TokenMap $unmatchedTokenMap } | Should -Throw
		}

		It 'Should write an error' {
			Should -Invoke 'Write-Error' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GitHubTools' -ParameterFilter {
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

			Convert-Token -InputFile $inputFile -OutputFile $outputFile -TokenMap $extraTokenMap
		}

		It 'Should write a warning' {
			Should -Invoke 'Write-Warning' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GitHubTools' -ParameterFilter {
				$Message -eq ('Unused tokens: {0}' -f $extraToken)
			}
		}
	}

	Context 'When input file does not exist' {
		It 'Should throw' {
			{ Convert-Token -InputFile 'nonexistent.bicepparam' -OutputFile $outputFile -TokenMap $tokenMap } | Should -Throw
		}
	}

	Context 'When token map is empty' {
		It 'Should throw' {
			{ Convert-Token -InputFile $inputFile -OutputFile $outputFile -TokenMap @{} } | Should -Throw
		}
	}
}
