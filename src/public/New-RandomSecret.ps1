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
		[int]
		$Length
	)

	$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+=<>?[]{}|;:,.`~'
	$secretValueParams = @{
		String      = -join (1..$Length | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })
		AsPlainText = $true
		Force       = $true
	}

	$secretValue = ConvertTo-SecureString @secretValueParams
	return $secretValue
}
