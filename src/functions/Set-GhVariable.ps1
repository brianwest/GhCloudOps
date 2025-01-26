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

		.PARAMETER IsOutput
			Indicates whether the variable should be set in the GITHUB_OUTPUT file instead of the GITHUB_ENV file.

		.EXAMPLE
			Set-GhVariable -Name 'MY_VAR' -Value 'my_value'

			Sets the environment variable 'MY_VAR' to 'my_value' in the GITHUB_ENV file.

		.EXAMPLE
			Set-GhVariable -Name 'MY_OUTPUT_VAR' -Value 'output_value' -IsOutput

			Sets the output variable 'MY_OUTPUT_VAR' to 'output_value' in the GITHUB_OUTPUT file.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]
		$Name,

		[Parameter(Mandatory)]
		[string]
		$Value,

		[Parameter()]
		[switch]
		$IsOutput
	)

	$setVariableParams = @{
		InputObject = '{0}={1}' -f $Name, $Value
		FilePath    = $IsOutput ? $env:GITHUB_OUTPUT : $env:GITHUB_ENV
		Append      = $true
	}

	Out-File @setVariableParams
}
