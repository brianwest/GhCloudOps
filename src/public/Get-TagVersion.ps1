<#
    .SYNOPSIS
        Get the version from the latest tag or the tag specified in the parameter.

    .DESCRIPTION
        Get the version from the latest tag or the tag specified in the parameter.

    .PARAMETER Ref
        The tag reference to get the version from.

    .PARAMETER DefaultVersion
        The default version to return if no tag is found.

    .EXAMPLE
        Get-Version.ps1 -Ref refs/tags/v1.0.0
        Returns 'v1.0.0'.
#>
function Get-TagVersion
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Ref,

        [Parameter()]
        [string]
        $DefaultVersion = 'v1.0.0-beta'
    )

    $commonParams = @{
        NoNewWindow = $true
        Wait        = $true
    }

    $commitParams = $commonParams.Clone()
    $commitParams.FilePath = 'git'
    $commitParams.ArgumentList = @('rev-list', '--tags', '--max-count=1')
    $latestTagCommitHash = Start-Process @commitParams
    if ($null -ne $latestTagCommitHash)
    {
        Write-Host -Object ("The latest tag commit hash is '{0}'." -f $latestTagCommitHash)
        $tagParams = $commonParams.Clone()
        $tagParams.FilePath = 'git'
        $tagParams.ArgumentList = @('describe', '--tags', $latestTagCommitHash)
        $latestTagVersion = Start-Process @tagParams
        Write-Host -Object ("The latest tag is '{0}'." -f $latestTagVersion)
    }

    if ($Ref -like 'refs/tags/v*.*.*')
    {
        $tag = $Ref.Split('/')[-1]
        $version = $tag
        Write-Host -Object ("Version '{0}' is being set by ref '{1}." -f $version, $Ref)
    }
    elseif ($Ref -like 'refs/tags/*')
    {
        throw ("The tag '{0}' is not a version tag. Please, use a version tag in the format 'v*.*.*'." -f $Ref)
    }
    elseif ($null -ne $latestTagVersion)
    {
        $version = $latestTagVersion
        Write-Host -Object ("Version '{0}' is being set by the latest tag." -f $version , $latestTagVersion)
    }
    else
    {
        $version = $DefaultVersion
        Write-Host -Object ("Version '{0}' is being set by the default value." -f $version, $DefaultVersion)
    }

    return $version
}
