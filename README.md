# PowerShell GitHub Tools

A PowerShell module providing utilities for GitHub Actions and Azure deployments.

## Functions

### [`Convert-Token`](GitHubTools.psm1)

Converts tokenized Bicep parameter files by replacing tokens with values from a provided map. Useful for managing configuration across different environments.

```powershell
$tokenMap = @{
    name     = 'test'
    count    = 1
    enabled  = $true
    identity = $null
}

Convert-Token -InputFile 'params.bicepparam' -OutputFile 'expanded.bicepparam' -TokenMap $tokenMap
```

#### Tokenized Parameter File

```bicep
using 'test.bicep'

param name = '{{ name }}'

param count = '{{ count }}'

param enabled = '{{ enabled }}'

param identity = '{{ identity }}'

```

#### Expanded Parameter File

```bicep
using 'test.bicep'

param name = 'test'

param count = 1

param enabled = true

param identity = null
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
Install-Module GitHubTools
```
