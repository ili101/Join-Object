# Remove BOM from the file
[CmdLetBinding()]
Param (
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName,

    [ValidateNotNullOrEmpty()]
    [String]$ModulePath,

    [ValidateNotNullOrEmpty()]
    [String]$FromGitHub# = 'https://github.com/ili101/Test/raw/master/Install.ps1'
    ,
    [ValidateSet('CurrentUser','AllUsers')]
    [string]
    $Scope = 'CurrentUser'
)

Try 
{
    Write-Verbose -Message 'Module installation started'

    if (!$ModulePath)
    {
        if ($Scope -eq 'CurrentUser')
        {
            $ModulePath = ($Env:PSModulePath -split ';')[0]
        }
        else
        {
            $ModulePath = ($Env:PSModulePath -split ';')[1]
        }
    }
    
    $Files = @(
        '*.dll', 
        '*.psd1', 
        '*.psm1', 
        '*.ps1'
    )
    $ExcludeFiles = @(
        'Install.ps1'
    )

    if ($FromGitHub)
    {
        $WebClient = New-Object System.Net.WebClient
        $GitUri = ($FromGitHub -Split '/raw/')[0]
        $Links = ((Invoke-WebRequest -Uri $GitUri).Links | Where-Object {$_.innerText -match '^.'+($Files -join '$|^.')+'$' -and $_.innerText -notmatch '^'+($ExcludeFiles -join '$|^.')+'$' -and $_.class -eq 'js-navigation-open'}).innerText
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension(($Links | Where-Object {$_ -like '*.psm1'}))
        $ModuleVersion = (. ([Scriptblock]::Create((Invoke-WebRequest -Uri "$GitUri/raw/master/$ModuleName.psd1").Content))).ModuleVersion
    }
    else
    {
        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension((Get-ChildItem -File -Filter *.psm1 -Name -Path $PSScriptRoot))
        $ModuleVersion = (. ([Scriptblock]::Create((Get-Content -Path "$PSScriptRoot\$ModuleName.psd1" | Out-String)))).ModuleVersion
    }

    $TargetPath = Join-Path -Path $ModulePath -ChildPath $ModuleName
    $TargetPath = Join-Path -Path $TargetPath -ChildPath $ModuleVersion

    # Create Directory
    if (-not (Test-Path -Path $TargetPath)) 
    {
        $null = New-Item -Path $TargetPath -ItemType Directory -ErrorAction Stop
        Write-Verbose -Message "$ModuleName created module folder '$TargetPath'"
    }

    # Copy Files
    if ($FromGitHub)
    {
        $Links | ForEach-Object {
            $WebClient.DownloadFile(($GitUri + '/raw/master/' + $_),"$TargetPath\$_")
            $File = Get-Content "$TargetPath\$_"
            $File | Set-Content "$TargetPath\$_"
            Write-Verbose -Message ("{0} installed module file '{1}'" -f $ModuleName, $_)
        }
    }
    else
    {
        Get-ChildItem -Path "$PSScriptRoot\*" -Include $Files -Exclude $ExcludeFiles | ForEach-Object -Process {
            Copy-Item -Path $_ -Destination $TargetPath
            Write-Verbose -Message ("{0} installed module file '{1}'" -f $ModuleName, $_)
        }
    }
    
    # Import Module
    Import-Module -Name Join-Object -Force
    Write-Verbose -Message "$ModuleName module installation successful to $TargetPath"
}
Catch 
{
    throw ("Failed installing the module '{0}': {1} in Line {2}" -f $ModuleName, $_, $_.InvocationInfo.ScriptLineNumber)
}
Write-Verbose -Message 'Module installation end'