Write-Verbose -Message 'Testing start'

$TestDataSetSmall = {
    $PSCustomObjects= @(
        [PSCustomObject]@{ID = 1 ; Sub = 'S1'}
        [PSCustomObject]@{ID = 2 ; Sub = 'S2'}
        [PSCustomObject]@{ID = 3 ; Sub = 'S3'}
    )
    
    $DataTable = [Data.DataTable]::new('Test')
    $null = $DataTable.Columns.Add('IDD')
    $null = $DataTable.Columns.Add('Name')
    $null = $DataTable.Columns.Add('Junk')
    $null = $DataTable.Rows.Add(1,'A','AAA')
    $null = $DataTable.Rows.Add(3,'C',$null)
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

ID Subscription R_Name
-- ------------ ------
 1 S1           A     
 2 S2                 
 3 S3           C     



"@
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

Subscription ID R_Name
------------ -- ------
S1            1 A     
S2            2       
S3            3 C     



"@
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

IDD Name Subscription_R
--- ---- --------------
1   A    S1            
3   C    S3            



"@
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

ID Subscription R_Name
-- ------------ ------
 1 S1           A     
 2 S2                 
 3 S3           C     



"@
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
1   A       S1            
3   C       S3            



"@
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

ID Sub Name Junk
-- --- ---- ----
 1 S1  A    AAA 
 2 S2           
 3 S3  C        



"@
                ExtraTest = {$JoindOutput | Where-Object {$_.Junk} | Out-String | Should -Be @"

ID Sub Name Junk
-- --- ---- ----
 1 S1  A    AAA 



"@}
            }
        ) -test {
            param ($TestDataSet, $Params, $Expected, $ExtraTest)

            . $TestDataSet
            $Params.Left  = (Get-Variable -Name $Params.Left).Value
            $Params.Right = (Get-Variable -Name $Params.Right).Value

            $BeforeLeft =  $Params.Left | Out-String
            $BeforeRight =  $Params.Right | Out-String

            $JoindOutput = Join-Object @Params
            Write-Verbose -Message ('Start' + ($JoindOutput | Out-String ) + 'End')

            $JoindOutput | Out-String | Should -Be $Expected
            if ($Params.PassThru)
            {
                ($Params.Left | Out-String) | Should -Be $Expected
            }
            else
            {
                ($Params.Left | Out-String) | Should -Be $BeforeLeft
            }
            ($Params.Right | Out-String) | Should -Be $BeforeRight

            if ($ExtraTest)
            {
                . $ExtraTest
            }
        }
    }
}

Write-Verbose -Message 'Testing end'