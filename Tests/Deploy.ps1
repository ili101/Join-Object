[CmdLetBinding()]
Param
(
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName,

    [ValidateNotNullOrEmpty()]
    [String]$NugetApiKey,

    [Switch]$Force
)

$ErrorActionPreferenceOrg = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
try
{
    if (!$Env:APPVEYOR -or $Env:APPVEYOR_REPO_BRANCH -eq 'master')
    {
        '[Progress] Deploy Start'
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension((Get-ChildItem -File -Filter *.psm1 -Name -Path "$PSScriptRoot\.."))
        try
        {
            $VersionGallery = (Find-Module -Name $ModuleName -ErrorAction Stop).Version
        }
        catch
        {
            if ($_.Exception.Message -notlike 'No match was found for the specified search criteria*' -or !$Force)
            {
                throw $_
            }
        }

        $VersionLocal = ((Get-Module -Name $ModuleName -ListAvailable).Version | Measure-Object -Maximum).Maximum
        "[Output] $ModuleName, VersionGallery: $VersionGallery, VersionLocal: $VersionLocal"
        if ($VersionGallery -lt $VersionLocal -or $Force)
        {
            if (!$NugetApiKey)
            {
                $NugetApiKey = $Env:NugetApiKey
            }
            "[Output] Deploying $ModuleName version $VersionLocal"
            Publish-Module -Name $ModuleName -NuGetApiKey $NugetApiKey -RequiredVersion $VersionLocal
        }
        else
        {
            '[Progress] Deploy Skipped (Version)'
        }
    }
    else
    {
        '[Progress] Deploy Skipped'
    }
}
catch
{
    throw $_
}
finally
{
    $ErrorActionPreference = $ErrorActionPreferenceOrg
}
'[Progress] Deploy Ended'