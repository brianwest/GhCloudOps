# PowerShell GitHub Tools

A PowerShell module providing utilities for GitHub Actions and cloud infrastructure deployments.

## Functions

### [`Convert-Token`](src/public/Convert-Token.ps1)

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

### [`Set-GhVariable`](src/public/Set-GhVariable.ps1)

Sets GitHub Actions variables during workflow execution.

Environment variables can be set as follows:

```powershell
Set-GhVariable -Name 'DEPLOY_ENV' -Value 'production'
```

Output variables can be set as follows:

```powershell
Set-GhVariable -Name 'DEPLOY_URL' -Value 'https://example.com' -IsOutput
```

Secret variables can be set as follows:

```powershell
Set-GhVariable -Name 'DEPLOY_SECRET' -Value 'supersecret' -IsSecret
```

```powershell
Set-GhVariable -Name 'DEPLOY_SECRET' -Value 'supersecret' -IsSecret -IsOutput
```

**Note:** Secret variables are not available to subsequent jobs in the workflow.

### [`New-RandomSecret`](src/public/New-RandomSecret.ps1)

Generates a random secure string.

```powershell
New-RandomSecret -Length 32
```

### [`Get-TagVersion`](src/public/Get-TagVersion.ps1)

Returns a version for tagging infrastructure resources by looking at the git ref, latest tag or a default value provided

Tag from git ref:

```powershell
Get-TagVersion -Ref 'refs/tags/v2.0.0'
v2.0.0
```

Tag from latest git tag:

```powershell
Get-TagVersion -Ref 'refs/heads/main'
v2.0.1 #Assuming v2.0.1 is that latest git tag
```

Tag from default value:

```powershell
Get-TagVersion -Ref 'refs/heads/main' -DefaultVersion 'v0.1.0-beta'x
v0.1.0-beta
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
Install-Module GhCloudOps
```
