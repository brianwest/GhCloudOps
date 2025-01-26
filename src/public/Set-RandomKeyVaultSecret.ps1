<#
	.SYNOPSIS
		Sets a random secret in an Azure Key Vault.

	.DESCRIPTION
		Sets a random secret in an Azure Key Vault. The function generates a random string of the specified length
		and sets it as the value of the secret in the specified Key Vault.

	.PARAMETER KeyVaultName
		The name of the Azure Key Vault where the secret will be stored.

	.PARAMETER SecretName
		The name of the secret to be created or updated in the Key Vault.

	.PARAMETER Length
		The length of the random string to be generated for the secret value.

	.EXAMPLE
		Set-RandomKeyVaultSecret -KeyVaultName 'myKeyVault' -SecretName 'mySecret' -Length 16

		Creates or updates a secret named 'mySecret' in the Key Vault 'myKeyVault' with a random string of length 16.
#>
function Set-RandomKeyVaultSecret
{
	[Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
	[CmdletBinding()]
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
	$secretValueParams = @{
		String      = -join (1..$Length | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })
		AsPlainText = $true
		Force       = $true
	}

	$secretParams = @{
		VaultName   = $KeyVaultName
		Name        = $SecretName
		SecretValue = ConvertTo-SecureString @secretValueParams
	}

	$null = Set-AzKeyVaultSecret @secretParams
	Write-Host -Object ("Secret '{0}' set in Key Vault '{1}'." -f $SecretName, $KeyVaultName)
}
