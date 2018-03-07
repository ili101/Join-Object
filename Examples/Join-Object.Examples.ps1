<# Notes
static System.Collections.Generic.IEnumerable[TResult]
	GroupJoin[TOuter, TInner, TKey, TResult]
		(
		System.Collections.Generic.IEnumerable[TOuter] outer,
		System.Collections.Generic.IEnumerable[TInner] inner,
		System.Func[TOuter,TKey] outerKeySelector,
		System.Func[TInner,TKey] innerKeySelector,
		System.Func[TOuter,System.Collections.Generic.IEnumerable[TInner],TResult] resultSelector
		),
static System.Collections.Generic.IEnumerable[TResult]
	GroupJoin[TOuter, TInner, TKey, TResult]
		(
		System.Collections.Generic.IEnumerable[TOuter] outer,
		System.Collections.Generic.IEnumerable[TInner] inner,
		System.Func[TOuter,TKey] outerKeySelector,
		System.Func[TInner,TKey] innerKeySelector,
		System.Func[TOuter,System.Collections.Generic.IEnumerable[TInner],TResult] resultSelector,
		System.Collections.Generic.IEqualityComparer[TKey] comparer
		)
#>

$TestData1 = {
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
. $TestData1

Join-Object -Left $PSCustomObjects -Right $DataTable -LeftJoinProperty ID -RightJoinProperty IDD -LeftProperties @{ID= 'ID' ; Sub = 'Subscription'} -ExcludeRightProperties Junk -Prefix 'R_' | Format-Table
Join-Object -Left $DataTable -Right $PSCustomObjects -LeftJoinProperty IDD -RightJoinProperty ID -RightProperties  @{ID= 'ID' ; Sub = 'Subscription'} -ExcludeLeftProperties Junk -Suffix '_R' | Format-Table
Join-Object -Left $PSCustomObjects -Right $DataTable -LeftJoinProperty ID -RightJoinProperty IDD -LeftProperties ([ordered]@{Sub = 'Subscription' ; ID= 'ID'}) -ExcludeRightProperties Junk -Prefix 'R_' | Format-Table
<# Output
ID Subscription R_Name
-- ------------ ------
 1 S1           A     
 2 S2                 
 3 S3           C     

IDD Name Subscription_R
--- ---- --------------
1   A    S1            
3   C    S3            

Subscription ID R_Name
------------ -- ------
S1            1 A     
S2            2       
S3            3 C              
#>

. $TestData1
$null = Join-Object -Left $PSCustomObjects -Right $DataTable -LeftJoinProperty ID -RightJoinProperty IDD -LeftProperties @{ID= 'ID' ; Sub = 'Subscription'} -ExcludeRightProperties Junk -Prefix 'R_' -PassThru
$PSCustomObjects
<# $PSCustomObjects changed to:
ID Subscription R_Name
-- ------------ ------
 1 S1           A     
 2 S2                 
 3 S3           C     
#>

. $TestData1
$null = Join-Object -Left $DataTable -Right $PSCustomObjects -LeftJoinProperty IDD -RightJoinProperty ID -LeftProperties @{IDD = 'IDD' ; Name = 'NewName'}-RightProperties  @{ID= 'ID' ; Sub = 'Subscription'} -ExcludeLeftProperties Junk -Suffix '_R' -PassThru
$DataTable
<# $DataTable changed to:
IDD NewName Subscription_R
--- ------- --------------
1   A       S1            
3   C       S3            
#>

'DBNull to $null test'
. $TestData1
Join-Object -Left $PSCustomObjects -Right $DataTable -LeftJoinProperty ID -RightJoinProperty IDD | Where-Object {$_.Junk} | Format-Table
. $TestData1
$null = Join-Object -Left $PSCustomObjects -Right $DataTable -LeftJoinProperty ID -RightJoinProperty IDD -PassThru
$PSCustomObjects | Where-Object {$_.Junk} | Format-Table
<# Output
ID Sub Name Junk
-- --- ---- ----
 1 S1  A    AAA 

ID Sub Name Junk
-- --- ---- ----
 1 S1  A    AAA      
#>