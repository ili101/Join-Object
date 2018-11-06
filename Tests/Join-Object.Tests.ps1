#Requires -Modules Pester
#Requires -Modules @{ModuleName = 'Assert' ; ModuleVersion = '0.9.2.1'}

$Verbose = @{Verbose = $false}
#$Verbose = @{Verbose = $true}

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

$TestDataSetSmall = {
    $PSCustomObjects = @(
        [PSCustomObject]@{ID = 1 ; Sub = 'S1' ; IntO = 6}
        [PSCustomObject]@{ID = 2 ; Sub = 'S2' ; IntO = 7}
        [PSCustomObject]@{ID = 3 ; Sub = 'S3' ; IntO = $null}
    )

    $DataTable = [Data.DataTable]::new('Test')
    $null = $DataTable.Columns.Add('IDD', [System.Int32])
    $null = $DataTable.Columns.Add('Name')
    $null = $DataTable.Columns.Add('Junk')
    $null = $DataTable.Columns.Add('IntT', [System.Int32])
    $null = $DataTable.Rows.Add(1, 'A', 'AAA', 5)
    $null = $DataTable.Rows.Add(3, 'C', $null, $null)
}
#. $TestDataSetSmall

function Format-Test
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [HashTable]$Test
    )
    if ($TestDataSetName, $Test.Params.Left, $Test.Params.Right, $Test.Description -contains $null)
    {
        Throw 'Missing param'
    }

    $Test.TestName = '{0}, {3}. {1} - {2}' -f $TestDataSetName, $Test.Params.Left, $Test.Params.Right, $Test.Description
    $Test.TestDataSet = Get-Variable -Name $TestDataSetName -ValueOnly
    $Test
}

function Get-Params
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String]$Param
    )
    $ParamSplit = $Param -split '(?=\[)'
    $Output = (Get-Variable -Name $ParamSplit[0]).Value
    if ($null -ne $ParamSplit[1])
    {
        , $Output.Item($ParamSplit[1].Trim('[]'))
    }
    else
    {
        , $Output
    }
}

Describe -Name 'Join-Object' -Fixture {
    $TestDataSetName = 'TestDataSetSmall'
    Context -Name $TestDataSetName -Fixture {
        It -name "Testing <TestName>" -TestCases @(
            Format-Test @{
                Description = 'BasicError'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'DataTableError'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }
            Format-Test @{
                Description = 'Basic'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'Ordered'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = [ordered]@{Sub = 'Subscription' ; ID = 'ID'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'Basic'
                Params      = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                }
            }
            Format-Test @{
                Description = 'PassThru'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                }
            }
            Format-Test @{
                Description = 'PassThru'
                Params      = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    LeftProperties        = @{IDD = 'IDD' ; Name = 'NewName'}
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    PassThru              = $true
                }
            }
            Format-Test @{
                Description = 'DBNull to $null'
                Params      = @{
                    Left              = 'PSCustomObjects'
                    Right             = 'DataTable'
                    LeftJoinProperty  = 'ID'
                    RightJoinProperty = 'IDD'
                }
            }
            Format-Test @{
                Description = 'DataTable'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }
            Format-Test @{
                Description = 'DataTable'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }
            Format-Test @{
                Description = 'AllInBoth'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Description = 'AllInBoth'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Description = 'Basic Single'
                Params      = @{
                    Left                   = 'PSCustomObjects[0]'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'Basic KeepRightJoinProperty'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    KeepRightJoinProperty  = $true
                }
            }
            Format-Test @{
                Description = 'Basic Multi Join'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID', 'Sub'
                    RightJoinProperty      = 'IDD', 'Name'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
                RunScript   = {
                    $PSCustomObjects += [PSCustomObject]@{ID = 4 ; Sub = 'S4' ; IntO = 77}
                    $null = $DataTable.Rows.Add(4, 'S4', 'ZZZ', 55)
                }
            }
            Format-Test @{
                Description = 'Basic JoinScript'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'Sub'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    LeftJoinScript         = {param ($Line) ($Line.$LeftJoinProperty).Replace('S', 'X')}
                    RightJoinScript        = {param ($Line) 'X' + ($Line.$RightJoinProperty)}
                }
            }
            Format-Test @{
                Description = 'DataTableTypes'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    DataTableTypes         = @{R_IntO = [Int]} # TODO: "Cannot set Column 'R_IntO' to be null. Please use DBNull instead"
                }
                #RunScript   = {$PSCustomObjects[-1].IntO = 0}
            }
        ) -test {
            param (
                $Params,
                $TestDataSet,
                $TestName,
                $Description,
                $RunScript
            )
            #if ($TestName -ne 'Small: PSCustomObjects - DataTable, DataTable') {Continue}

            # Load Data
            . $TestDataSet
            if ($RunScript)
            {
                . $RunScript
            }
            $Params.Left = Get-Params -Param $Params.Left
            $Params.Right = Get-Params -Param $Params.Right

            # Save Before Data Copy
            $BeforeLeft = [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($Params.Left, 2))
            $BeforeRight = [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($Params.Right, 2))

            # Execute Cmdlet
            $JoindOutput = Join-Object @Params
            Write-Verbose ('it returns:' + ($JoindOutput | Format-Table | Out-String)) @Verbose
            #$JoindOutputXml = [System.Management.Automation.PSSerializer]::Serialize($JoindOutput)
            #$JoindOutputNew = [System.Management.Automation.PSSerializer]::Deserialize($JoindOutputXml)

            # Save CompareData (Xml)
            #Export-Clixml -LiteralPath "$ScriptRoot\CompareData\$TestName.xml" -InputObject $JoindOutput
            ##$JoindOutputXml | Set-Content -LiteralPath "$ScriptRoot\CompareData\$TestName.xml"

            # Get CompareData
            $CompareDataXml = (Get-Content -LiteralPath "$ScriptRoot\CompareData\$TestName.xml") -join [Environment]::NewLine
            $CompareDataNew = [System.Management.Automation.PSSerializer]::Deserialize($CompareDataXml)
            Write-Verbose ('it should return:' + ($CompareDataNew | Format-Table | Out-String)) @Verbose

            # Test
            #$CompareDataXml | Should -Be $JoindOutputXml
            if ($Description -like '*Error*')
            {
                {Assert-Equivalent -Actual $JoindOutput -Expected $CompareDataNew -StrictOrder -StrictType} | Should -Throw
            }
            else
            {
                Assert-Equivalent -Actual $JoindOutput -Expected $CompareDataNew -StrictOrder -StrictType
            }

            if ($Params.PassThru)
            {
                #[System.Management.Automation.PSSerializer]::Serialize($Params.Left) | Should -Be $CompareDataXml
                Assert-Equivalent -Actual $Params.Left -Expected $CompareDataNew -StrictOrder -StrictType
            }
            else
            {
                #[System.Management.Automation.PSSerializer]::Serialize($Params.Left) | Should -Be $BeforeLeftXml
                Assert-Equivalent -Actual $Params.Left -Expected $BeforeLeft -StrictOrder -StrictType
            }
            #[System.Management.Automation.PSSerializer]::Serialize($Params.Right) | Should -Be $BeforeRightXml
            Assert-Equivalent -Actual $Params.Right -Expected $BeforeRight -StrictOrder -StrictType

            if (!$Params.PassThru)
            {
                if ($Params.DataTable)
                {
                    Should -BeOfType -ActualValue $JoindOutput -ExpectedType 'System.Data.DataTable'
                    $JoindOutput | Should -BeOfType -ExpectedType 'System.Data.DataRow'
                }
                else
                {
                    if ($JoindOutput.Count -gt 0)
                    {
                        Should -BeOfType -ActualValue $JoindOutput -ExpectedType 'System.Array'
                    }
                    else
                    {
                        Should -BeOfType -ActualValue $JoindOutput -ExpectedType 'PSCustomObject'
                    }
                    $JoindOutput | Should -BeOfType -ExpectedType 'PSCustomObject'
                }
            }
        }
    }
}