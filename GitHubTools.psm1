function Convert-Token
{
	<#
		.SYNOPSIS
			Converts tokenized bicep parameter files to expanded files using a token map.

		.DESCRIPTION
			Converts tokenized bicep parameter files to expanded files using a token map.  The token map is a hashtable
			where the key is the token and the value is the replacement value.  The token is in the format '{{ token }}'.
			The function reads the input file line by line and replaces the tokens with the corresponding values.  The
			expanded content is written to the output file.  The function also checks for unmatched tokens and unused
			tokens.

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
					$line = $line.Replace(("'{0}'" -f $token), ('null'.Replace("'", '')))
				}
				elseif ($value.GetType() -eq [string])
				{
					$line = $line.Replace($token, $value)
				}
				elseif ($value.GetType() -eq [int])
				{
					$line = $line.Replace(("'{0}'" -f $token), $value)
				}
				elseif ($value.GetType() -eq [bool])
				{
					$line = $line.Replace(("'{0}'" -f $token), $value.ToString().ToLower())
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
		Write-Error -Message 'Unmatched tokens found'
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
		New-Item -Path $OutputFile -ItemType File
	}

	Set-Content -Path $OutputFile -Value (Get-Content -Path $temporaryFile)
}

function Set-GhVariable
{
	<#
		.SYNOPSIS
			Sets a GitHub Actions environment variable.

		.DESCRIPTION
			Sets a GitHub Actions environment variable by appending the variable to the GITHUB_ENV file.
			The function takes the name and value of the variable as parameters and writes them to the file
			in the format 'NAME=VALUE'.

		.PARAMETER Name
			The name of the environment variable.

		.PARAMETER Value
			The value of the environment variable.

		.EXAMPLE
			Set-GhVariable -Name 'MY_VAR' -Value 'my_value'

			Sets the environment variable 'MY_VAR' to 'my_value' in the GITHUB_ENV file.
	#>
	param
	(
		[Parameter(Mandatory)]
		[string]
		$Name,

		[Parameter(Mandatory)]
		[string]
		$Value
	)

	$setVariableParams = @{
		InputObject = '{0}={1}' -f $Name, $Value
		FilePath    = $env:GITHUB_ENV
		Append      = $true
	}

	Out-File @setVariableParams
}

function Set-RandomKeyVaultSecret
{
	param
	(
		[Parameter(Mandatory)]
		[string]
		$KeyVaultName,

		[Parameter(Mandatory)]
		[string]
		$SecretName,

		[Parameter(Mandatory)]
		[int]
		$Length
	)

	$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+=<>?[]{}|;:,.`~'
	$secretValue = ConvertTo-SecureString -String ( -join (1..$Length | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] }) ) -AsPlainText -Force
	$secretParams = @{
		VaultName   = $KeyVaultName
		Name        = $SecretName
		SecretValue = $secretValue
	}

	$null = Set-AzKeyVaultSecret @secretParams
	Write-Host -Object ('Secret {0} set in Key Vault {1}' -f $SecretName, $KeyVaultName)
}
