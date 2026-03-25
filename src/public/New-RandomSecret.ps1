<#
	.SYNOPSIS
		Generates a random secure string.

	.DESCRIPTION
		Generates a random secure string of a given length.

	.PARAMETER Length
		The length of the random string to be generated.

	.EXAMPLE
		New-RandomSecret -Length 16

		Creates a random secure string that's 16 characters long.
#>
function New-RandomSecret
{
	[Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
	[OutputType([System.Security.SecureString])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateRange(1, 1024)]
		[int]
		$Length
	)

	$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+=<>?[]{}|;:,.`~'
	$secretChars = [char[]]::new($Length)

	for ($index = 0; $index -lt $Length; $index++)
	{
		$secretChars[$index] = $chars[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($chars.Length)]
	}

	$secretValueParams = @{
		String      = -join $secretChars
		AsPlainText = $true
		Force       = $true
	}

	return ConvertTo-SecureString @secretValueParams
}
