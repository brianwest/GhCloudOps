<#
	.SYNOPSIS
		Converts tokenized bicep parameter, json or HCL files to expanded files using a token map.

	.DESCRIPTION
		Converts tokenized bicep parameter, json or HCL files to expanded files using a token map.  The token map
		is a hashtable where the key is the token and the value is the replacement value.  The token is in the
		format '{{ token }}'. The function reads the input file line by line and replaces the tokens with the
		corresponding values.  The expanded content is written to the output file.  The function also checks for
		unmatched tokens and unused tokens.

	.PARAMETER InputFile
		The path to the input file.

	.PARAMETER OutputFile
		The path to the output file.

	.PARAMETER TokenMap
		The hashtable containing the token map.

	.EXAMPLE
		$tokenParams = @{
			InputFile = 'C:\input.txt'
			OutputFile = 'C:\output.txt'
			TokenMap = @{
				string = 'string'
				int    = 1
				bool   = $true
				null   = $null
			}
		}

		Convert-Token @tokenParams

		Converts the input file 'C:\input.txt' to the output file 'C:\output.txt' using the token map.
		The token map is a hashtable where '{{ string }}' is replaced with 'string', '{{ int }}' is replaced with 1,
		'{{ bool }}' is replaced with true, '{{ null }}' is replaced with null.
#>
function Convert-Token
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateScript({ Test-Path -Path $_ })]
		[string]
		$InputFile,

		[Parameter(Mandatory)]
		[string]
		$OutputFile,

		[Parameter(Mandatory)]
		[ValidateScript({ $_.Count -gt 0 })]
		[hashtable]
		$TokenMap
	)

	$item = Get-Item -LiteralPath $InputFile
	if ($item.Extension -eq '.bicepparam')
	{
		$quotedString = "'{0}'"
	}
	elseif (($item.Extension -eq '.json') -or ($item.Extension -eq '.tfvars'))
	{
		$quotedString = '"{0}"'
	}
	else
	{
		throw 'Unsupported file type: {0}' -f $item.Extension
	}

	$content = Get-Content -Path $InputFile
	$temporaryFile = New-TemporaryFile
	$usedTokens = New-Object -TypeName System.Collections.ArrayList
	foreach ($line in $content)
	{
		foreach ($key in $TokenMap.Keys)
		{
			$token = "{{ $key }}"
			if ($line -match $token)
			{
				$value = $TokenMap[$key]
				if ($null -eq $value)
				{
					$line = $line.Replace(($quotedString -f $token), ('null'.Replace("'", '')))
				}
				elseif ($value.GetType() -eq [string])
				{
					$line = $line.Replace($token, $value)
				}
				elseif ($value.GetType() -eq [int])
				{
					$line = $line.Replace(($quotedString -f $token), $value)
				}
				elseif ($value.GetType() -eq [bool])
				{
					$line = $line.Replace(($quotedString -f $token), $value.ToString().ToLower())
				}

				$null = $usedTokens.Add($key)
			}
		}

		Out-File -InputObject $line -FilePath $temporaryFile -Append
	}

	$pattern = '\{\{[^\}]+\}\}'
	$unmatchedTokens = Select-String -Path $temporaryFile -Pattern $pattern -AllMatches
	if ($unmatchedTokens)
	{
		Write-Error -Message 'Unmatched tokens found' -ErrorAction 'Continue'
		throw $unmatchedTokens
	}

	$unusedTokens = New-Object -TypeName System.Collections.ArrayList
	foreach ($key in $TokenMap.Keys)
	{
		if (-not $usedTokens.Contains($key))
		{
			$null = $unusedTokens.Add($key)
		}
	}

	if ($unusedTokens.Count -gt 0)
	{
		Write-Warning -Message ('Unused tokens: {0}' -f ($unusedTokens -join ', '))
	}

	if (Test-Path -Path $OutputFile)
	{
		Clear-Content -Path $OutputFile
	}
	else
	{
		$null = New-Item -Path $OutputFile -ItemType File
	}

	Set-Content -Path $OutputFile -Value (Get-Content -Path $temporaryFile)
	Write-Host -Object ("Converted tokens in '{0}' to '{1}'" -f $InputFile, $OutputFile)
}
