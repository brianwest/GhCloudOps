<#
    .SYNOPSIS
        Runs Pester tests in a given path.

    .DESCRIPTION
        Runs detailed Pester tests in a given path with code coverage and throws terminating error if code coverage
        is below the given threshold.

    .PARAMETER Path
        Path to the folder containing the Pester tests.

    .PARAMETER CoveragePercentTarget
        The target code coverage percentage. Default is 75.

    .EXAMPLE
        Run-Test.ps1 -Path 'C:\path\to\tests'

        Runs Pester tests in the given path with default code coverage target of 75%.
#>
param
(
    [Parameter(Mandatory)]
    [string]
    $Path,

    [Parameter()]
    [decimal]
    $CoveragePercentTarget = 75
)

$config = New-PesterConfiguration
$config.Run.Path = Split-Path -Path $Path -Parent
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.CoveragePercentTarget = $CoveragePercentTarget
$config.CodeCoverage.OutputPath = Join-Path -Path $Path -ChildPath 'coverage.xml'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config

# Path to your JaCoCo XML report
$jacocoReportPath = Join-Path -Path $Path -ChildPath 'coverage.xml'

# Check if the file exists
if (Test-Path -Path $jacocoReportPath)
{
    # Load XML content
    [xml]$jacocoReport = Get-Content $jacocoReportPath

    # Extract coverage data
    $coverage = ($jacocoReport.report.counter).Where({ $_.type -eq "INSTRUCTION" })
    $covered = [int]$coverage.covered
    $missed = [int]$coverage.missed
    $total = $covered + $missed
    $percentageCovered = [math]::Round(($covered / $total) * 100, 2)

    if ($percentageCovered -lt $config.CodeCoverage.CoveragePercentTarget.Value)
    {
        $failMessage = "Coverage percentage is {0}% and target is {1}%." -f $percentageCovered, $config.CodeCoverage.CoveragePercentTarget.Value
        throw $failMessage
    }
    else
    {
        $successMessage = "Coverage percentage is {0}% and target is {1}%." -f $percentageCovered, $config.CodeCoverage.CoveragePercentTarget.Value
        Write-Host -Object $successMessage -ForegroundColor Green
    }
}
else
{
    $noReport = "JaCoCo report not found at path '{0}'" -f $jacocoReportPath
    throw $noReport
}
