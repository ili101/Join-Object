[CmdLetBinding()]
Param
(
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName,

    [ValidateNotNullOrEmpty()]
    [String]$NugetApiKey,

    [Switch]$Force,

    [Switch]$PowerShellGallery,

    [Switch]$AppVeyorZip
)

$ErrorActionPreferenceOrg = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
try
{
    # Get Script Root
    if ($PSScriptRoot)
    {
        $ScriptRoot = $PSScriptRoot
    }
    elseif ($psISE.CurrentFile.IsUntitled -eq $false)
    {
        $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
    }
    elseif ($null -ne $psEditor.GetEditorContext().CurrentFile.Path -and $psEditor.GetEditorContext().CurrentFile.Path -notlike 'untitled:*')
    {
        $ScriptRoot = Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path
    }
    else
    {
        $ScriptRoot = '.'
    }

    # Get Module Info
    if (!$ModuleName)
    {
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension((Get-ChildItem -File -Filter *.psm1 -Name -Path "$ScriptRoot\.."))
    }
    $VersionLocal = ((Get-Module -Name $ModuleName -ListAvailable).Version | Measure-Object -Maximum).Maximum
    "[Progress] Deploy Script Start for Module: $ModuleName, Version: $VersionLocal"

    if ((!$Env:APPVEYOR -or $Env:APPVEYOR_REPO_BRANCH -eq 'master') -and $PowerShellGallery)
    {
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

        "[Output] PowerShellGallery. $ModuleName, VersionGallery: $VersionGallery, VersionLocal: $VersionLocal"
        if ($VersionGallery -lt $VersionLocal -or $Force)
        {
            if (!$NugetApiKey)
            {
                $NugetApiKey = $Env:NugetApiKey
            }
            "[Output] PowerShellGallery. Deploying $ModuleName version $VersionLocal"
            Publish-Module -Name $ModuleName -NuGetApiKey $NugetApiKey -RequiredVersion $VersionLocal
        }
        else
        {
            '[Output] PowerShellGallery Deploy Skipped (Version Check)'
        }
    }
    if ($Env:APPVEYOR -and $AppVeyorZip)
    {
        $ZipFileName = "{0} {1} {2:yyyy-MM-dd HH-mm-ss}.zip" -f $ModuleName, $VersionLocal, (Get-Date)
         "[Output] AppVeyorZip. $ModuleName, ZipFileName: $ZipFileName"
        $ModulePath = (Get-Module -Name $ModuleName -ListAvailable).ModuleBase | Split-Path
        #Compress-Archive -Path $ModulePath -DestinationPath (Join-Path -Path $ScriptRoot -ChildPath $ZipFileName)
        Push-AppveyorArtifact $ModulePath -FileName $ZipFileName -DeploymentName $ModuleName
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