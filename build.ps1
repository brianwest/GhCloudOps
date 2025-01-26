#requires -Version 7.0

$requiredModules = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'RequiredModules.psd1')
$testPath = Join-Path -Path $PSScriptRoot -ChildPath 'tests'
$coveragePercentTarget = 95
$sourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$moduleName = (Get-ChildItem -Path $sourcePath -Filter '*.psm1').BaseName
$moduleFile = '{0}.psm1' -f $moduleName
$manifestFile = '{0}.psd1' -f $moduleName
$coveragePath = Join-Path -Path $sourcePath -ChildPath $moduleFile
$manifestPath = Join-Path -Path $sourcePath -ChildPath $manifestFile
$publicFunctions = Get-ChildItem -Path (Join-Path -Path $sourcePath -ChildPath 'public') -Filter '*.ps1' -Recurse
$privateFunctions = Get-ChildItem -Path (Join-Path -Path $sourcePath -ChildPath 'private') -Filter '*.ps1' -Recurse
$outputFolder = Join-Path -Path $PSScriptRoot -ChildPath 'output'

task set_environment_variables {
    $env:MODULE_VERSION = '0.0.0'
    $env:PROJECT_URI = 'https://github.com/brianwest/GitHubTools'
    $env:RELEASE_NOTES = 'Only for testing local build'
}

task install_modules {
    Import-Module -Name PowerShellGet -Force
    $currentPath = $env:PSModulePath
    $env:PSModulePath = '{0};{1}' -f $currentPath, $outputFolder
    $projectRequiredModules = $requiredModules.Modules
    $moduleRequiredModules = (Import-PowerShellDataFile -Path $manifestPath).RequiredModules
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
            Save-Module @requiredModuleParams -Path $outputFolder -Force
            Import-Module -Name $requiredModule.ModuleName -Force
        }
    }
}

task clean_output {
    if (Test-Path -Path $outputFolder)
    {
        Remove-Item -Path $outputFolder -Recurse -Force
    }
}

task test install_modules, {
    $config = New-PesterConfiguration
    $config.Run.Path = $testPath
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.CoveragePercentTarget = $coveragePercentTarget
    $config.CodeCoverage.Path = $coveragePath
    $config.CodeCoverage.OutputPath = Join-Path -Path $testPath -ChildPath 'coverage.xml'
    $config.Output.Verbosity = 'Detailed'
    Invoke-Pester -Configuration $config

    $jacocoReportPath = Join-Path -Path $testPath -ChildPath 'coverage.xml'

    if (Test-Path -Path $jacocoReportPath)
    {
        [xml]$jacocoReport = Get-Content $jacocoReportPath

        if ($null -eq $jacocoReport.report.counter)
        {
            $noCoverage = "No coverage data found in JaCoCo report at path '{0}'" -f $jacocoReportPath
            throw $noCoverage
        }

        $coverage = ($jacocoReport.report.counter).Where({ $_.type -eq 'INSTRUCTION' })
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
            Write-Host -Object $successMessage -ForegroundColor Green
        }
    }
    else
    {
        $noReport = "JaCoCo report not found at path '{0}'" -f $jacocoReportPath
        throw $noReport
    }
}

task build_module clean_output, {
    $script:releaseFolder = Join-Path -Path $outputFolder -ChildPath $moduleName -AdditionalChildPath $env:MODULE_VERSION
    $script:builtModulePath = Join-Path -Path $releaseFolder -ChildPath $moduleFile

    New-Item -ItemType File -Path $builtModulePath -Force
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
    $builtManifestPath = Join-Path -Path $releaseFolder -ChildPath $manifestFile

    $manifest = Import-PowerShellDataFile -Path $manifestPath
    $manifest.FunctionsToExport = $script:functionsToExport
    $manifest.PrivateData.PSData.ProjectUri = $env:PROJECT_URI
    $manifest.PrivateData.PSData.ReleaseNotes = $env:RELEASE_NOTES
    $manifestParams = @{
        Path                       = $builtManifestPath
        RootModule                 = Split-Path -Path $builtModulePath -Leaf
        ModuleVersion              = $env:MODULE_VERSION
        Guid                       = $manifest.Guid
        Author                     = $manifest.Author
        Copyright                  = $manifest.Copyright
        Description                = $manifest.Description
        PowerShellVersion          = $manifest.PowerShellVersion
        RequiredModules            = $manifest.RequiredModules
        FunctionsToExport          = $manifest.FunctionsToExport
        AliasesToExport            = $manifest.AliasesToExport
        Tags                       = $manifest.PrivateData.PSData.Tags
        LicenseUri                 = $manifest.PrivateData.PSData.LicenseUri
        ProjectUri                 = $manifest.PrivateData.PSData.ProjectUri
        ReleaseNotes               = $manifest.PrivateData.PSData.ReleaseNotes
        ExternalModuleDependencies = $manifest.PrivateData.PSData.ExternalModuleDependencies
    }

    New-ModuleManifest @manifestParams
}

task build install_modules, clean_output, build_module, update_manifest

task local_build set_environment_variables, install_modules, clean_output, build_module, update_manifest
