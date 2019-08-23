$ExampleData = {
    # Left Object Example
    $PSCustomObject = @(
        [PSCustomObject]@{ ID = 1 ; Sub = 'S1' ; IntO = 6 }
        [PSCustomObject]@{ ID = 2 ; Sub = 'S2' ; IntO = 7 }
        [PSCustomObject]@{ ID = 3 ; Sub = 'S3' ; IntO = $null }
    )
    # Right Object Example (DataTable)
    $DataTable = [Data.DataTable]::new('Test')
    $null = $DataTable.Columns.Add('IDD', [System.Int32])
    $null = $DataTable.Columns.Add('Name')
    $null = $DataTable.Columns.Add('Junk')
    $null = $DataTable.Columns.Add('IntT', [System.Int32])
    $null = $DataTable.Rows.Add(1, 'foo', 'AAA', 123456)
    $null = $DataTable.Rows.Add(3, 'Bar', 'S3', $null)
    $null = $DataTable.Rows.Add(4, 'D', $null, $null)
}

. $ExampleData
# Example 1: Join the 2 together ("Left Join" in this case).
Join-Object -Left $PSCustomObject -Right $DataTable -LeftJoinProperty 'ID' -RightJoinProperty 'IDD' | Format-Table
<# Output
	ID Sub IntO Name Junk   IntT
	-- --- ---- ---- ----   ----
	1 S1     6 foo  AAA  123456
	2 S2     7
	3 S3       Bar  S3
#>

. $ExampleData
# Example 2A: Filtering columns.
$Params = @{
    Left                   = $PSCustomObject
    Right                  = $DataTable
    LeftJoinProperty       = 'ID'
    RightJoinProperty      = 'IDD'
    ExcludeRightProperties = 'Junk'      # Exclude column "Junk" from the right columns.
    Prefix                 = 'R_'        # Add Prefix to the right columns.
    LeftProperties         = 'ID', 'Sub' # Select columns to include from the right.
}
Join-Object @Params | Format-Table
<# Output
	ID Sub R_Name R_IntT
	-- --- ------ ------
	1 S1  foo    123456
	2 S2
	3 S3  Bar
#>

# Example 2B: Filtering renaming and reordering columns.
$Params['LeftProperties'] = [ordered]@{ Sub = 'Subscription' ; ID = 'ID' } # Select columns to include from the right, rename and reorder them.
Join-Object @Params | Format-Table
<# Output
	Subscription ID R_Name R_IntT
	------------ -- ------ ------
	S1            1 foo    123456
	S2            2
	S3            3 Bar
#>

. $ExampleData
# Example 3: -Type. Options: AllInLeft (default), OnlyIfInBoth, AllInBoth.
$Params = @{
    Left              = $PSCustomObject
    Right             = $DataTable
    LeftJoinProperty  = 'ID'
    RightJoinProperty = 'IDD'
    Type              = 'OnlyIfInBoth'
}
Join-Object @Params | Format-Table
<# Output
	ID Sub IntO Name Junk   IntT
	-- --- ---- ---- ----   ----
	1 S1     6 foo  AAA  123456
	3 S3       Bar  S3
#>

. $ExampleData
# Example 4: Output format. (When input is [DataTable] containing [DBNull]s if output is [PSCustomObject] they will be converted to $null).
$Params = @{
    Left              = $PSCustomObject
    Right             = $DataTable
    LeftJoinProperty  = 'ID'
    RightJoinProperty = 'IDD'
    DataTable         = $true # By default output format is PSCustomObject this changes it to DataTable.
}
Join-Object @Params | Format-Table
<# This is a DataTable
	ID Sub IntO Name Junk   IntT
	-- --- ---- ---- ----   ----
	1  S1  6    foo  AAA  123456
	2  S2  7
	3  S3       Bar  S3
#>

. $ExampleData
# Example 5: -PassThru. Editing the existing left object preserving it's existing type PSCustomObject/DataTable.
$Params = @{
    Left              = $PSCustomObject
    Right             = $DataTable
    LeftJoinProperty  = 'ID'
    RightJoinProperty = 'IDD'
    PassThru          = $true
}
$null = Join-Object @Params
$PSCustomObject | Format-Table
<# $PSCustomObject changed to:
ID Sub IntO Name Junk   IntT
-- --- ---- ---- ----   ----
 1 S1     6 foo  AAA  123456
 2 S2     7
 3 S3       Bar  S3
#>

. $ExampleData
# Example 6: JoinScript. Manipulate the JoinProperty for the comparison with a Scriptblock.
$Params = @{
    Left              = $PSCustomObject
    Right             = $DataTable
    LeftJoinProperty  = 'Sub'
    RightJoinProperty = 'IDD'
	LeftJoinScript    = { param ($Line) $Line.Sub.Replace('S', '')} # For example change "Sub" column value from "S1" to "1" to compare to "IDD" column "1".
}
Join-Object @Params | Format-Table
<# Output
	ID Sub IntO Name Junk   IntT
	-- --- ---- ---- ----   ----
	1 S1     6 foo  AAA  123456
	2 S2     7
	3 S3       Bar  S3
#>

. $ExampleData
# Example 7: -AddKey. can be used with "-Type AllInBoth" to add a column containing the joining key.
$Params = @{
    Left              = $PSCustomObject
    Right             = $DataTable
    LeftJoinProperty  = 'ID'
    RightJoinProperty = 'IDD'
	LeftProperties    = 'Sub'
	Type              = 'AllInBoth'
	AddKey            = 'Index'
}
Join-Object @Params | Format-Table
<# Output
    Index Sub Name Junk   IntT
    ----- --- ---- ----   ----
    1     S1  foo  AAA  123456
    2     S2
    3     S3  Bar  S3
    4         D
#>