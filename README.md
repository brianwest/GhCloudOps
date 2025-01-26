# PowerShell GitHub Tools

A PowerShell module providing utilities for GitHub Actions and Azure deployments.

## Functions

### [`Convert-Token`](GitHubTools.psm1)

Converts tokenized Bicep parameter files by replacing tokens with values from a provided map. Useful for managing configuration across different environments.

```powershell
$tokenMap = @{
    string = 'string'
    int    = 1
    bool   = $true
    null   = $null
}

Convert-Token -InputFile 'params.bicepparam' -OutputFile 'expanded.bicepparam' -TokenMap $tokenMap
```

#### Tokenized Parameter File

```bicep
using 'test.bicep'

param stringTest = '{{ string }}'

param intTest = '{{ int }}'

param boolTest = '{{ bool }}'

param nullTest = '{{ null }}'

```

#### Expanded Parameter File

```bicep
using 'test.bicep'

param stringTest = 'string'

param intTest = 1

param boolTest = true

param nullTest = null
```

### [`Set-GhVariable`](GitHubTools.psm1)

Sets GitHub Actions variables during workflow execution.

Environment variables can be set as follows:

```powershell
Set-GhVariable -Name 'DEPLOY_ENV' -Value 'production'
```

Output variables can be set as follows:

```powershell
Set-GhVariable -Name 'DEPLOY_URL' -Value 'https://example.com' -IsOutput
```

### [`Set-RandomKeyVaultSecret`](GitHubTools.psm1)

Generates and sets a random secret in an Azure Key Vault.

```powershell
Set-RandomKeyVaultSecret -KeyVaultName 'my-vault' -SecretName 'app-secret' -Length 32
```

## Testing

The module includes Pester tests located in the [tests](tests) directory. To run the tests:

```powershell
Invoke-Build -File ./build.ps1 -Task Test
```

## Requirements

- PowerShell 7
- Az PowerShell module (for Key Vault operations)
- GitHub Actions environment (for `Set-GhVariable`)

## Installation

```powershell
Import-Module ./GitHubTools.psm1
```
