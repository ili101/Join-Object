# Remove BOM from the file
[CmdLetBinding()]
Param (
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName,

    [ValidateNotNullOrEmpty()]
    [String]$ModulePath,

    [ValidateNotNullOrEmpty()]
    [Uri]$FromGitHub #= 'https://raw.githubusercontent.com/ili101/Join-Object/master/Install.ps1'
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
        # Fix Could not create SSL/TLS secure channel
        $SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $WebClient = [System.Net.WebClient]::new()
        #$GitUri = ($FromGitHub -Split '/raw/')[0]
        $GitUri = $FromGitHub.AbsolutePath.Split('/')[1,2] -join '/'
        #$Links = ((Invoke-WebRequest -Uri $GitUri).Links | Where-Object {$_.innerText -match '^.'+($Files -join '$|^.')+'$' -and $_.innerText -notmatch '^'+($ExcludeFiles -join '$|^.')+'$' -and $_.class -eq 'js-navigation-open'}).innerText
        $Links = (Invoke-RestMethod -Uri "https://api.github.com/repos/$GitUri/contents") | Where-Object {$_.name -match '^.'+($Files -join '$|^.')+'$' -and $_.name -notmatch '^'+($ExcludeFiles -join '$|^.')+'$'}

        $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension(($Links | Where-Object {$_.name -like '*.psm1'}))
        $ModuleVersion = (. ([Scriptblock]::Create((Invoke-WebRequest -Uri ($Links | Where-Object {$_.name -eq "$ModuleName.psd1"}).download_url)))).ModuleVersion
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
        foreach ($Link in $Links)
        {
            $WebClient.DownloadFile($Link.download_url,(Join-Path -Path $TargetPath -ChildPath $Link.name))
            #$File = Get-Content "$TargetPath\$_"
            #$File | Set-Content "$TargetPath\$_"
            Write-Verbose -Message ("{0} installed module file '{1}'" -f $ModuleName, $Link.name)
        }
    }
    else
    {
        Get-ChildItem -Path "$PSScriptRoot\*" -Include $Files -Exclude $ExcludeFiles | ForEach-Object {
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
finally
{
    if ($FromGitHub)
    {
        [Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol
    }
    Write-Verbose -Message 'Module installation end'
}