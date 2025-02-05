# PowerShell GitHub Tools

A PowerShell module providing utilities for GitHub Actions and cloud infrastructure deployments.

## Functions

### [`Convert-Token`](AzGhOps.psm1)

Converts tokenized .bicepparam, .json and .tfvars files by replacing tokens with values from a provided map. Useful for managing a single configuration file across different environments.

#### Convert Bicep Parameter File

```powershell
$tokenMap = @{
    name     = 'test'
    count    = 1
    enabled  = $true
    identity = $null
}

Convert-Token -InputFile 'params.bicepparam' -OutputFile 'expanded.bicepparam' -TokenMap $tokenMap
```

#### Tokenized Bicep Parameter File

```bicep
using 'test.bicep'

param name = '{{ name }}'

param count = '{{ count }}'

param enabled = '{{ enabled }}'

param identity = '{{ identity }}'

```

#### Expanded Bicep Parameter File

```bicep
using 'test.bicep'

param name = 'test'

param count = 1

param enabled = true

param identity = null
```

#### Convert Json Parameter File

```powershell
$tokenMap = @{
    name     = 'test'
    count    = 1
    enabled  = $true
    identity = $null
}

Convert-Token -InputFile 'params.json' -OutputFile 'expanded.json' -TokenMap $tokenMap
```

#### Tokenized Json Parameter File

```json
{
    "name": "{{ name }}",
    "count": "{{ count }}",
    "enabled": "{{ enabled }}",
    "identity": "{{ identity }}"
}

```

#### Expanded Json Parameter File

```json
{
    "name": "test",
    "count": 1,
    "enabled": true,
    "identity": null
}

```

#### Convert Terraform Tfvars File

```powershell
$tokenMap = @{
    name     = 'test'
    count    = 1
    enabled  = $true
    identity = $null
}

Convert-Token -InputFile 'params.tfvars' -OutputFile 'expanded.tfvars' -TokenMap $tokenMap
```

#### Tokenized Terraform Tfvars File

```hcl
name = "{{ name }}"

count = "{{ count }}"

enabled = "{{ enabled }}"

identity = "{{ identity }}"
```

#### Expanded Terraform Tfvars File

```hcl
name = "test"

count = 1

enabled = true

identity = null
```

### [`Set-GhVariable`](AzGhOps.psm1)

Sets GitHub Actions variables during workflow execution.

Environment variables can be set as follows:

```powershell
Set-GhVariable -Name 'DEPLOY_ENV' -Value 'production'
```

Output variables can be set as follows:

```powershell
Set-GhVariable -Name 'DEPLOY_URL' -Value 'https://example.com' -IsOutput
```

### [`New-RandomSecret`](AzGhOps.psm1)

Generates and sets a random secure string.

```powershell
New-RandomSecret -Length 32
```

## Testing

The module includes Pester tests located in the [tests](tests) directory. To run the tests:

```powershell
Invoke-Build -File ./build.ps1 -Task Test
```

## Requirements

- PowerShell 7
- GitHub Actions environment (for `Set-GhVariable`)

## Installation

```powershell
Install-Module AzGhOps
```
