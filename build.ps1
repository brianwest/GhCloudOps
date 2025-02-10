#requires -Version 7.0

$sourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$moduleName = (Get-ChildItem -Path $sourcePath -Filter '*.psm1').BaseName
$moduleFile = '{0}.psm1' -f $moduleName
$manifestFile = '{0}.psd1' -f $moduleName
$manifestPath = Join-Path -Path $sourcePath -ChildPath $manifestFile
$publicFunctions = Get-ChildItem -Path (Join-Path -Path $sourcePath -ChildPath 'public') -Filter '*.ps1' -Recurse
$privateFunctions = Get-ChildItem -Path (Join-Path -Path $sourcePath -ChildPath 'private') -Filter '*.ps1' -Recurse
$outputFolder = Join-Path -Path $PSScriptRoot -ChildPath 'output'
$requiredModulesOutputPath = Join-Path -Path $PSScriptRoot -ChildPath 'requiredModules'
$projectRequiredModules = (Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'RequiredModules.psd1')).Modules
$moduleRequiredModules = (Import-PowerShellDataFile -Path $manifestPath).RequiredModules
$testPath = Join-Path -Path $PSScriptRoot -ChildPath 'tests'
$coveragePercentTarget = 95
$resultPath = Join-Path -Path $testPath -ChildPath 'testResults.xml'
$coveragePath = Join-Path -Path $testPath -ChildPath 'coverage.xml'
$releaseFolder = Join-Path -Path $outputFolder -ChildPath $moduleName -AdditionalChildPath $env:MODULE_VERSION
$builtModulePath = Join-Path -Path $releaseFolder -ChildPath $moduleFile
$builtManifestPath = Join-Path -Path $releaseFolder -ChildPath $manifestFile

task set_environment_variables {
    $env:MODULE_VERSION = '1.2.0'
    $env:PROJECT_URI = 'https://github.com/brianwest/GhCloudOps'
    $env:RELEASE_NOTES = 'Only for testing local build'
}

task clean_output {
    if (Test-Path -Path $outputFolder)
    {
        Remove-Item -Path $outputFolder -Recurse -Force
    }
}

task install_modules clean_output, {
    Import-Module -Name 'PowerShellGet' -Force
    $null = New-Item -ItemType Directory -Path $requiredModulesOutputPath -Force
    $currentPath = $env:PSModulePath
    if (-not $env:PSModulePath.Contains($requiredModulesOutputPath))
    {
        $env:PSModulePath = '{0};{1}' -f $currentPath, $requiredModulesOutputPath
    }

    $combinedRequiredModules = $projectRequiredModules + $moduleRequiredModules
    foreach ($requiredModule in $combinedRequiredModules)
    {
        $requiredModuleParams = @{
            Name            = $requiredModule.ModuleName
            RequiredVersion = $requiredModule.ModuleVersion
        }

        $module = Get-InstalledModule @requiredModuleParams -ErrorAction SilentlyContinue
        if ($null -eq $module)
        {
            $modulePath = Join-Path -Path $requiredModulesOutputPath -ChildPath $requiredModule.ModuleName
            Save-Module @requiredModuleParams -Path $requiredModulesOutputPath -Force
            Write-Verbose -Message ('Module {0} version {1} installed to path {2}' -f $requiredModule.ModuleName, $requiredModule.ModuleVersion, $modulePath)
            Import-Module -Name $modulePath -Force
            Write-Verbose -Message ('Module {0} version {1} imported' -f $requiredModule.ModuleName, $requiredModule.ModuleVersion)
        }
    }
}

task test install_modules, {
    $config = New-PesterConfiguration
    $config.Run.Path = $testPath
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.CoveragePercentTarget = $coveragePercentTarget
    $config.CodeCoverage.Path = $sourcePath
    $config.CodeCoverage.OutputPath = $coveragePath
    $config.Output.Verbosity = 'Detailed'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = $resultPath
    Invoke-Pester -Configuration $config

    if (Test-Path -Path $resultPath)
    {
        [xml]$testResults = Get-Content -Path $resultPath
        if ($testResults.'test-results'.failures -gt 0)
        {
            throw ('{0} tests failed.' -f $testResults.'test-results'.failures)
        }
        else
        {
            $successMessage = 'All tests passed.'
            Write-Host -Object $successMessage
        }
    }
    else
    {
        $noResults = "Pester test results not found at path '{0}'" -f $resultPath
        throw $noResults
    }

    if (Test-Path -Path $coveragePath)
    {
        [xml]$coverageReport = Get-Content $coveragePath

        if ($null -eq $coverageReport.report.counter)
        {
            $noCoverage = "No coverage data found in coverage report at path '{0}'" -f $coveragePath
            throw $noCoverage
        }

        $coverage = ($coverageReport.report.counter).Where({ $_.type -eq 'INSTRUCTION' })
        $covered = [int]$coverage.covered
        $missed = [int]$coverage.missed
        $total = $covered + $missed
        $percentageCovered = [math]::Round(($covered / $total) * 100, 2)

        if ($percentageCovered -lt $config.CodeCoverage.CoveragePercentTarget.Value)
        {
            $failMessage = 'Coverage percentage is {0}% and target is {1}%.' -f $percentageCovered, $config.CodeCoverage.CoveragePercentTarget.Value
            throw $failMessage
        }
        else
        {
            $successMessage = 'Coverage percentage is {0}% and target is {1}%.' -f $percentageCovered, $config.CodeCoverage.CoveragePercentTarget.Value
            Write-Host -Object $successMessage
        }
    }
    else
    {
        $noReport = "Coverage report not found at path '{0}'" -f $coveragePath
        throw $noReport
    }
}

task build_module clean_output, {
    $null = New-Item -ItemType File -Path $builtModulePath -Force
    $script:functionsToExport = @()
    foreach ($publicFunction in $publicFunctions)
    {
        $publicFunctionName = $publicFunction.BaseName
        $publicFunctionPath = $publicFunction.FullName
        $content = Get-Content -Path $publicFunctionPath
        Out-File -FilePath $builtModulePath -InputObject $content -Append
        $script:functionsToExport += $publicFunctionName
    }

    foreach ($privateFunction in $privateFunctions)
    {
        $privateFunctionPath = $privateFunction.FullName
        $content = Get-Content -Path $privateFunctionPath
        Out-File -FilePath $builtModulePath -InputObject $content -Append
    }
}

task update_manifest clean_output, build_module, {
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    $manifest.FunctionsToExport = $script:functionsToExport
    $manifest.PrivateData.PSData.ProjectUri = $env:PROJECT_URI
    $manifest.PrivateData.PSData.ReleaseNotes = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'releases' -AdditionalChildPath ('v{0}.md' -f $env:MODULE_VERSION)) -Raw
    $manifestParams = @{
        Path              = $builtManifestPath
        RootModule        = Split-Path -Path $builtModulePath -Leaf
        ModuleVersion     = $env:MODULE_VERSION
        Guid              = $manifest.Guid
        Author            = $manifest.Author
        Copyright         = $manifest.Copyright
        Description       = $manifest.Description
        PowerShellVersion = $manifest.PowerShellVersion
        FunctionsToExport = $manifest.FunctionsToExport
        AliasesToExport   = $manifest.AliasesToExport
        Tags              = $manifest.PrivateData.PSData.Tags
        LicenseUri        = $manifest.PrivateData.PSData.LicenseUri
        ProjectUri        = $manifest.PrivateData.PSData.ProjectUri
        ReleaseNotes      = $manifest.PrivateData.PSData.ReleaseNotes
    }

    if ($manifest.RequiredModules.Count -gt 0)
    {
        $manifestParams.Add('RequiredModules', $manifest.RequiredModules)
    }

    if ($manifest.PrivateData.PSData.ExternalModuleDependencies.Count -gt 0)
    {
        $manifestParams.Add('ExternalModuleDependencies', $manifest.PrivateData.PSData.ExternalModuleDependencies)
    }

    New-ModuleManifest @manifestParams
}

task build install_modules, clean_output, build_module, update_manifest

task local_build set_environment_variables, install_modules, clean_output, build_module, update_manifest
