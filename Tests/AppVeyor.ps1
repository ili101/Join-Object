param
(
    [Switch]$Finalize
)

# Initialize
$PSVersion = $PSVersionTable.PSVersion.Major
$TestFile = "TestResultsPS$PSVersion.xml"
#$VerbosePreference = 'Continue'

# Run a test with the current version of PowerShell
if(!$Finalize)
{
    "[Progress] Testing with PowerShell $PSVersion"
    . .\Install.ps1
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