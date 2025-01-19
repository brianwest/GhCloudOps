Describe 'Convert-Token' {
	BeforeAll {
		$repoRoot = Split-Path -Path $PSScriptRoot -Parent
		$modulePath = Join-Path -Path $repoRoot -ChildPath 'GitHubTools.psm1'
		Import-Module -Name $modulePath -Force

		$helperPath = Join-Path -Path $repoRoot -ChildPath 'tests' -AdditionalChildPath 'helpers'
		$inputFile = Join-Path -Path $helperPath -ChildPath 'test.bicepparam'
		$outputFile = Join-Path -Path $helperPath -ChildPath 'output' -AdditionalChildPath 'expanded.bicepparam'

		$tokenMap = @{
			string = 'string'
			int    = 1
			bool   = $true
			null   = $null
		}

		Mock -CommandName 'Write-Error' -ModuleName 'GitHubTools'
		Mock -CommandName 'Write-Warning' -ModuleName 'GitHubTools'
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
	}

	Context 'When tokens are missing from the token map' {
		BeforeAll {
			$unmatchedTokenMap = $tokenMap.Clone()
			$unmatchedTokenMap.Remove('string')
		}

		It 'Should thow' {
			{ Convert-Token -InputFile $inputFile -OutputFile $outputFile -TokenMap $unmatchedTokenMap } | Should -Throw
		}

		It 'Should write an error' {
			Should -Invoke 'Write-Error' -Times 1 -Exactly -Scope 'Context' -ModuleName 'GitHubTools' -ParameterFilter {
				$Message -eq 'Unmatched tokens found'
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

	AfterAll {
		Remove-Item -Path $outputFile -Force
	}
}
