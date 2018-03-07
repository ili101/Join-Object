#Get-ChildItem Env:
#Get-Variable
[CmdLetBinding()]
Param (
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName,

    [ValidateNotNullOrEmpty()]
    [String]$NugetApiKey,

    [Switch]$Force
)
Write-Verbose -Message 'Deploy start'
$ErrorActionPreference = 'Stop'
try
{
    if (!$Env:APPVEYOR -or $Env:APPVEYOR_REPO_BRANCH -eq "master")
    {
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension((Get-ChildItem -File -Filter *.psm1 -Name -Path "$PSScriptRoot\.."))
        try
        {
            $VersionGallery = (Find-Module -Name $ModuleName -ErrorAction Stop).Version
        }
        catch
        {
            if ($_.Exception.Message -notlike 'No match was found for the specified search criteria*' -or !$Force)
            {
                Write-Error $_
            }
        }

        $VersionLocal = ((Get-Module -Name $ModuleName -ListAvailable).Version | Measure-Object -Maximum).Maximum
        Write-Verbose -Message "$ModuleName VersionGallery $VersionGallery, VersionLocal $VersionLocal"
        if ($VersionGallery -lt $VersionLocal -or $Force)
        {
            if (!$NugetApiKey)
            {
                $NugetApiKey = $Env:NugetApiKey
            }
            Write-Verbose -Message "Deploying $ModuleName version $VersionLocal"
            Publish-Module -Name $ModuleName -NuGetApiKey $NugetApiKey -RequiredVersion $VersionLocal
        }
    }
}
catch
{
    "Error was $_"
    $line = $_.InvocationInfo.ScriptLineNumber
    "Error was in Line $line"
}
Write-Verbose -Message 'Deploy end'