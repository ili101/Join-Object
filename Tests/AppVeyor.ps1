param
(
    [Switch]$Finalize,
    [Switch]$Initialize
)

if ($Initialize)
{
    # Update AppVeyor build
    $psd1 = (Get-ChildItem -File -Filter *.psd1 -Name -Path "$PSScriptRoot\..").PSPath
    $ModuleVersion = (. ([Scriptblock]::Create((Get-Content -Path $psd1 | Out-String)))).ModuleVersion
    Update-AppveyorBuild -Version "$ModuleVersion ($env:APPVEYOR_BUILD_NUMBER) $Env:APPVEYOR_REPO_BRANCH"
}
elseif (!$Finalize) # Run a test with the current version of PowerShell
{
    function Get-EnvironmentInfo
    {
        $Lookup = @{
            378389 = [version]'4.5'
            378675 = [version]'4.5.1'
            378758 = [version]'4.5.1'
            379893 = [version]'4.5.2'
            393295 = [version]'4.6'
            393297 = [version]'4.6'
            394254 = [version]'4.6.1'
            394271 = [version]'4.6.1'
            394802 = [version]'4.6.2'
            394806 = [version]'4.6.2'
            460798 = [version]'4.7'
            460805 = [version]'4.7'
            461308 = [version]'4.7.1'
            461310 = [version]'4.7.1'
            461808 = [version]'4.7.2'
            461814 = [version]'4.7.2'
        }

        # For extra effect we could get the Windows 10 OS version and build release id:
        try
        {
            $WinRelease, $WinVer = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" ReleaseId, CurrentMajorVersionNumber, CurrentMinorVersionNumber, CurrentBuildNumber, UBR
            $WindowsVersion = "$($WinVer -join '.') ($WinRelease)"
        }
        catch
        {
            $WindowsVersion = [System.Environment]::OSVersion.Version
        }

        Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
            Get-ItemProperty -Name Version, Release -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -eq "Full"} |
            Select-Object @(
            @{name = ".NET Framework"; expression = {$_.PSChildName}},
            @{name = "Product"; expression = {$Lookup[$_.Release]}},
            'Version',
            'Release',
            @{name = "PSComputerName"; expression = {$Env:Computername}},
            @{name = "WindowsVersion"; expression = { $WindowsVersion }},
            @{name = "PSVersion"; expression = {$PSVersionTable.PSVersion}}
        )
    }

    "[Progress] Testing On:"
    Get-EnvironmentInfo
    . .\Install.ps1
    $TestFile = "TestResultsPS{0}.xml" -f $PSVersionTable.PSVersion
    Invoke-Pester -OutputFile $TestFile
}
else # Finalize
{
    '[Progress] Finalizing'
    $Failure = $false
    # Upload results for test page
    Get-ChildItem -Path '.\TestResultsPS*.xml' | Foreach-Object {
        $Address = 'https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID
        $Source = $_.FullName
        "[Output] Uploading Files: $Address, $Source"
        [System.Net.WebClient]::new().UploadFile($Address, $Source)

        if (([Xml](Get-Content -Path $Source)).'test-results'.failures -ne '0')
        {
            $Failure = $true
        }
    }
    if ($Failure)
    {
        throw 'Tests failed'
    }
}