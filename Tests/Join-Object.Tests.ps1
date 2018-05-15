#Requires -Modules Pester
Write-Verbose -Message 'Testing start'

$TestDataSetSmall = {
    $PSCustomObjects= @(
        [PSCustomObject]@{ID = 1 ; Sub = 'S1' ; IntO = 6}
        [PSCustomObject]@{ID = 2 ; Sub = 'S2' ; IntO = 7}
        [PSCustomObject]@{ID = 3 ; Sub = 'S3' ; IntO = $null}
    )
    
    $DataTable = [Data.DataTable]::new('Test')
    $null = $DataTable.Columns.Add('IDD',[System.Int32])
    $null = $DataTable.Columns.Add('Name')
    $null = $DataTable.Columns.Add('Junk')
    $null = $DataTable.Columns.Add('IntT',[System.Int32])
    $null = $DataTable.Rows.Add(1,'A','AAA',5)
    $null = $DataTable.Rows.Add(3,'C',$null,$null)
}
#. $TestDataSetSmall

Describe -Name 'Join-Object' -Fixture {
    Context -Name "Test Small" -Fixture {
        It -name "Testing <TestName>, it returns <Expected>" -TestCases @(
            @{
                TestName = 'Small: PSCustomObjects - DataTable'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID= 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
                Expected = @"

ID Subscription R_Name R_IntT
-- ------------ ------ ------
 1 S1           A           5
 2 S2                        
 3 S3           C            



"@
                Count = 3
            }
            @{
                TestName = 'Small: PSCustomObjects - DataTable, ordered'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = [ordered]@{Sub = 'Subscription' ; ID= 'ID'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
                Expected = @"

Subscription ID R_Name R_IntT
------------ -- ------ ------
S1            1 A           5
S2            2              
S3            3 C            



"@
                Count = 3
            }
            @{
                TestName = 'Small: DataTable - PSCustomObjects'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    RightProperties         = @{ID= 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                 = '_R'
                }
                Expected = @"

IDD Name IntT Subscription_R
--- ---- ---- --------------
  1 A       5 S1            
  3 C         S3            



"@
                Count = 2
            }
            @{
                TestName = 'Small: PSCustomObjects - DataTable, PassThru'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID= 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                }
                Expected = @"

ID Subscription R_Name R_IntT
-- ------------ ------ ------
 1 S1           A           5
 2 S2                        
 3 S3           C            



"@
                Count = 3
            }
            @{
                TestName = 'Small: DataTable - PSCustomObjects, PassThru'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    LeftProperties         = @{IDD = 'IDD' ; Name = 'NewName'}
                    RightProperties        = @{ID= 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties  = 'Junk'
                    Suffix                 = '_R'
                    PassThru               = $true
                }
                Expected = @"

IDD NewName Subscription_R
--- ------- --------------
  1 A       S1            
  3 C       S3            



"@
                Count = 2
            }
            @{
                TestName = 'Small: PSCustomObjects - DataTable, DBNull to $null'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                }
                Expected = @"

ID Sub IntO Name Junk IntT
-- --- ---- ---- ---- ----
 1 S1     6 A    AAA     5
 2 S2     7               
 3 S3       C             



"@
                Count = 3
                ExtraTest = {$JoindOutput | Where-Object {$_.Junk} | Format-Table | Out-String | Should -Be @"

ID Sub IntO Name Junk IntT
-- --- ---- ---- ---- ----
 1 S1     6 A    AAA     5



"@}
            }
            @{
                TestName = 'Small: DataTable - PSCustomObjects, DataTable'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
                Expected = @"

IDD Name Junk IntT R_Sub R_IntO
--- ---- ---- ---- ----- ------
  1 A    AAA     5 S1    6     
  3 C              S3          



"@
                Count = 2
            }
            @{
                TestName = 'Small: PSCustomObjects - DataTable, DataTable'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
                Expected = @"

ID Sub IntO R_Name R_IntT
-- --- ---- ------ ------
1  S1  6    A           5
2  S2  7                 
3  S3       C            



"@
                Count = 3
            }
            @{
                TestName = 'Small: PSCustomObjects - DataTable, DataTable AllInBoth'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                }
                Expected = @"

ID Sub IntO R_Name R_IntT
-- --- ---- ------ ------
1  S1  6    A           5
2  S2  7                 
3  S3       C            



"@
                Count = 3
            }
            @{
                TestName = 'Small: DataTable - PSCustomObjects, DataTable AllInBoth'
                TestDataSet = $TestDataSetSmall
                Params = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                }
                Expected = @"

IDD Name Junk IntT R_Sub R_IntO
--- ---- ---- ---- ----- ------
  1 A    AAA     5 S1    6     
  3 C              S3          
                   S2    7     



"@
                Count = 3
            }
        ) -test {
            param ($TestDataSet, $Params, $Expected, $Count, $ExtraTest, $TestName)

            #if ($TestName -ne 'Small: PSCustomObjects - DataTable, DataTable') {Continue}
            
            . $TestDataSet
            $Params.Left  = (Get-Variable -Name $Params.Left).Value
            $Params.Right = (Get-Variable -Name $Params.Right).Value

            $BeforeLeft =  $Params.Left | Out-String
            $BeforeRight =  $Params.Right | Out-String
            $BeforeLeftType = $Params.Left.GetType()
            $BeforeRightType = $Params.Right.GetType()

            $JoindOutput = Join-Object @Params
            Write-Verbose -Message ('Start' + ($JoindOutput | Format-Table | Out-String ) + 'End')

            $JoindOutput | Format-Table | Out-String | Should -Be $Expected
            if ($Params.PassThru)
            {
                ($Params.Left | Format-Table | Out-String) | Should -Be $Expected
            }
            else
            {
                ($Params.Left | Format-Table | Out-String) | Should -Be $BeforeLeft
            }
            ($Params.Right | Format-Table | Out-String) | Should -Be $BeforeRight

            if ($Params.PassThru)
            {
                Should -BeOfType -ActualValue $JoindOutput -ExpectedType $BeforeLeftType
            }
            elseif ($Params.DataTable)
            {
                Should -BeOfType -ActualValue $JoindOutput -ExpectedType 'System.Data.DataTable'
                $JoindOutput | Should -BeOfType -ExpectedType 'System.Data.DataRow'
            }
            else
            {
                Should -BeOfType -ActualValue $JoindOutput -ExpectedType 'System.Array'
                $JoindOutput | Should -BeOfType -ExpectedType 'PSCustomObject'
            }

            if ($JoindOutput -is [System.Data.DataTable])
            {
                $JoindOutput.Rows.Count | Should -Be $Count
            }
            else
            {
                $JoindOutput.Count | Should -Be $Count
            }

            if ($ExtraTest)
            {
                . $ExtraTest
            }
        }
    }
}

Write-Verbose -Message 'Testing end'

<# Alternative testing method
using namespace System.Data
Add-Type -AssemblyName System.Data.DataSetExtensions

$DataTable2 = [Data.DataTable]::new('Test')
$null = $DataTable2.Columns.Add('IDD')
$null = $DataTable2.Columns.Add('Name')
$null = $DataTable2.Columns.Add('Junk')
$null = $DataTable2.Rows.Add(1,'A','AAA')
$null = $DataTable2.Rows.Add(3,'C',$null)


$DataTable = [Data.DataTable]::new('Test')
$null = $DataTable.Columns.Add('IDD')
$null = $DataTable.Columns.Add('Name')
$null = $DataTable.Columns.Add('Junk')
$null = $DataTable.Rows.Add(1,'A','AAA')
$null = $DataTable.Rows.Add(3,'C',$null)

[System.Linq.Enumerable]::SequenceEqual($DataTable.Rows.ItemArray, $DataTable2.Rows.ItemArray)

$PSCustomObjects= @(
    [PSCustomObject]@{ID = 1 ; Sub = 'S1'}
    [PSCustomObject]@{ID = 2 ; Sub = 'S2'}
    [PSCustomObject]@{ID = 3 ; Sub = 'S3'}
    )
$PSCustomObjects2= @(
    [PSCustomObject]@{ID = 1 ; Sub = 'S1'}
    [PSCustomObject]@{ID = 2 ; Sub = 'S2'}
    [PSCustomObject]@{ID = 3 ; Sub = 'S3'}
    )

[System.Linq.Enumerable]::SequenceEqual(($PSCustomObjects2 | ForEach-Object {$_.psobject.Properties.Value}), ($PSCustomObjects | ForEach-Object {$_.psobject.Properties.Value}))
#>