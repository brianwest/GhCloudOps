# PowerShell GitHub Tools

A PowerShell module providing utilities for GitHub Actions and Azure deployments.

## Functions

### [`Convert-Token`](GitHubTools.psm1)
Converts tokenized Bicep parameter files by replacing tokens with values from a provided map. Useful for managing configuration across different environments.

```powershell
$tokenMap = @{
    string = 'value'
    int    = 1
    bool   = $true
    null   = $null
}

Convert-Token -InputFile 'params.bicepparam' -OutputFile 'expanded.bicepparam' -TokenMap $tokenMap
```

### [`Set-GhVariable`](GitHubTools.psm1)
Sets GitHub Actions environment variables during workflow execution.

```powershell
Set-GhVariable -Name 'DEPLOY_ENV' -Value 'production'
```

### [`Set-RandomKeyVaultSecret`](GitHubTools.psm1)
Generates and sets a random secret in an Azure Key Vault.

```powershell
Set-RandomKeyVaultSecret -KeyVaultName 'my-vault' -SecretName 'app-secret' -Length 32
```

## Testing

The module includes Pester tests located in the [tests](tests) directory. To run the tests:

```powershell
Invoke-Pester tests/*.tests.ps1
```

## Requirements

- PowerShell 5.1 or higher
- Az PowerShell module (for Key Vault operations)
- GitHub Actions environment (for `Set-GhVariable`)

## Installation

```powershell
Import-Module ./GitHubTools.psm1
```
