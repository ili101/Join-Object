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

function Convert-LikeToMatch
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeLine)]
        [String]$Filters
    )
    begin
    {
        $Output = @()
    }
    process
    {
        $Filters = [regex]::Escape($Filters)
        if ($Filters -match "^\\\*")
        {
            $Filters = $Filters.Remove(0, 2)
        }
        else
        {
            $Filters = '^' + $Filters
        }
        if ($Filters -match "\\\*$")
        {
            $Filters = $Filters.Substring(0, $Filters.Length - 2)
        }
        else
        {
            $Filters = $Filters + '$'
        }
        $Output += $Filters
    }
    end
    {
        ($Output -join '|').replace('\*', '.*').replace('\?', '.')
    }
}

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
        '*.ps1',
        'morelinq*'
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
        $GitUri = $FromGitHub.AbsolutePath.Split('/')[1, 2] -join '/'
        $GitBranch = $FromGitHub.AbsolutePath.Split('/')[3]
        #$Links = ((Invoke-WebRequest -Uri $GitUri).Links | Where-Object {$_.innerText -match '^.'+($Files -join '$|^.')+'$' -and $_.innerText -notmatch '^'+($ExcludeFiles -join '$|^.')+'$' -and $_.class -eq 'js-navigation-open'}).innerText
        $Links = (Invoke-RestMethod -Uri "https://api.github.com/repos/$GitUri/contents" -Body @{ref = $GitBranch}) | Where-Object {$_.name -match ($Files | Convert-LikeToMatch) -and $_.name -notmatch ($ExcludeFiles | Convert-LikeToMatch)}

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
            $TargetPathItem = Join-Path -Path $TargetPath -ChildPath $Link.name
            if ($Link.type -ne 'dir')
            {
                $WebClient.DownloadFile($Link.download_url, $TargetPathItem)
                #$File = Get-Content "$TargetPath\$_"
                #$File | Set-Content "$TargetPath\$_"
                Write-Verbose -Message ("{0} installed module file '{1}'" -f $ModuleName, $Link.name)
            }
            else
            {
                if (-not (Test-Path -Path $TargetPathItem))
                {
                    $null = New-Item -Path $TargetPathItem -ItemType Directory -ErrorAction Stop
                    Write-Verbose -Message "$ModuleName created module folder '$TargetPathItem'"
                }
                $SubLinks = (Invoke-RestMethod -Uri $Link.git_url -Body @{recursive = '1'}).tree #| Where-Object 'type' -EQ 'blob'
                foreach ($SubLink in $SubLinks)
                {
                    $TargetPathSub = Join-Path -Path $TargetPathItem -ChildPath $SubLink.path
                    if ($SubLink.'type' -EQ 'tree')
                    {
                        if (-not (Test-Path -Path $TargetPathSub))
                        {
                            $null = New-Item -Path $TargetPathSub -ItemType Directory -ErrorAction Stop
                            Write-Verbose -Message "$ModuleName created module folder '$TargetPathSub'"
                        }
                    }
                    else
                    {
                        $WebClient.DownloadFile(
                            ('https://raw.githubusercontent.com/{0}/{1}/{2}/{3}' -f $GitUri, $GitBranch, $Link.name, $SubLink.path),
                            $TargetPathSub
                        )
                    }
                }
            }
        }
    }
    else
    {
        Get-ChildItem -Path ".\" -Exclude $ExcludeFiles | Where-Object -Property Name -Match ($Files | Convert-LikeToMatch) | ForEach-Object {
            if ($_.Attributes -ne 'Directory')
            {
                Copy-Item -Path $_ -Destination $TargetPath
                Write-Verbose -Message ("{0} installed module file '{1}'" -f $ModuleName, $_)
            }
            else
            {
                Copy-Item -Path $_ -Destination $TargetPath -Recurse -Force
                Write-Verbose -Message ("{0} installed module file '{1}'" -f $ModuleName, $_)
            }
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