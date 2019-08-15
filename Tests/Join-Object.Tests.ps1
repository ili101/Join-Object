#Requires -Modules Pester
#Requires -Modules @{ ModuleName = 'Assert' ; ModuleVersion = '999.9.5' }
[CmdletBinding()]
Param
(
    [Switch]$SaveMode,
    [String[]]$FilterTests
)
$EquivalencyOption = Get-EquivalencyOption -Comparator 'StrictEquality'-StrictOrder

if ($PSScriptRoot) {
    $ScriptRoot = $PSScriptRoot
}
elseif ($psISE.CurrentFile.IsUntitled -eq $false) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
}
elseif ($null -ne $psEditor.GetEditorContext().CurrentFile.Path -and $psEditor.GetEditorContext().CurrentFile.Path -notlike 'untitled:*') {
    $ScriptRoot = Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path
}
else {
    $ScriptRoot = '.'
}

$DataSetSmall = {
    $PSCustomObject = @(
        [PSCustomObject]@{ ID = 1 ; Sub = 'S1' ; IntO = 6 }
        [PSCustomObject]@{ ID = 2 ; Sub = 'S2' ; IntO = 7 }
        [PSCustomObject]@{ ID = 3 ; Sub = 'S3' ; IntO = $null }
    )

    $PSCustomObjectJunk = @(
        [PSCustomObject]@{ ID = 1 ; Sub = 'S1' ; IntO = 6     ; Junk = 'New1' }
        [PSCustomObject]@{ ID = 2 ; Sub = 'S2' ; IntO = 7     ; Junk = $null }
        [PSCustomObject]@{ ID = 3 ; Sub = 'S3' ; IntO = $null ; Junk = $null }
    )

    $PSCustomObjectKeyArray = @(
        [PSCustomObject]@{ID = 1, 2, 3 ; Sub = 'S1' ; IntO = 6 }
        [PSCustomObject]@{ID = 4 ; Sub = 'S4' ; IntO = $null }
    )

    $DataTable = [Data.DataTable]::new('Test')
    $null = $DataTable.Columns.Add('IDD', [System.Int32])
    $null = $DataTable.Columns.Add('Name')
    $null = $DataTable.Columns.Add('Junk')
    $null = $DataTable.Columns.Add('IntT', [System.Int32])
    $null = $DataTable.Rows.Add(1, 'A', 'AAA', 5)
    $null = $DataTable.Rows.Add(3, 'C', 'S3', $null)
    $null = $DataTable.Rows.Add(4, 'D', $null, $null)

    $PSCustomObjectMulti = @(
        [PSCustomObject]@{ ID = 1 ; Sub = 'S1' ; IntO = 6 }
        [PSCustomObject]@{ ID = 1 ; Sub = 'S12' ; IntO = 62 }
        [PSCustomObject]@{ ID = 2 ; Sub = 'S2' ; IntO = 7 }
        [PSCustomObject]@{ ID = 2 ; Sub = 'S22' ; IntO = 72 }
    )

    $DataTableMulti = [Data.DataTable]::new('Test')
    $null = $DataTableMulti.Columns.Add('IDD', [System.Int32])
    $null = $DataTableMulti.Columns.Add('Name')
    $null = $DataTableMulti.Columns.Add('Junk')
    $null = $DataTableMulti.Columns.Add('IntT', [System.Int32])
    $null = $DataTableMulti.Rows.Add(1, 'A', 'AAA', 5)
    $null = $DataTableMulti.Rows.Add(1, 'A2', 'AAA2', 52)
    $null = $DataTableMulti.Rows.Add(3, 'C', 'S3', $null)
    $null = $DataTableMulti.Rows.Add(3, 'C2', 'S32', $null)
}
#. $DataSetSmall

function ConvertFrom-DataTable {
    <#
        .SYNOPSIS
        Convert DataTable to PSCustomObject, Support Deserialized DataTable.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript( { $_ -is [System.Data.DataRow] } )]
        $InputObject
    )
    begin {
        $First = $true
    }
    process {
        if ($First) {
            $First = $false
            $Properties = if ($InputObject -is [System.Data.DataTable]) {
                $InputObject.Columns.ColumnName
            }
            else {
                $InputObject.PSObject.Properties.Name | Where-Object { $_ -notin ('RowError', 'RowState', 'Table', 'ItemArray', 'HasErrors') }
            }
        }
        foreach ($DataRow in $InputObject) {
            $RowHash = [ordered]@{ }
            foreach ($Property in $Properties) {
                if ($DataRow.$Property -is [DBNull]) {
                    $RowHash[$Property] = $null
                }
                else {
                    $RowHash[$Property] = $DataRow.$Property
                }
            }
            [PSCustomObject]$RowHash
        }
    }
}
function ConvertTo-DataTable {
    <#
        .SYNOPSIS
        Convert PSCustomObject to DataTable.
        Warning: Column type taken from firs line, null will be [Object].
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject
    )
    begin {
        $OutputDataTable = [Data.DataTable]::new()
        $First = $true
    }
    process {
        foreach ($PSCustomObject in $InputObject) {
            if ($First) {
                $First = $false
                foreach ($Property in $PSCustomObject.PSObject.Properties) {
                    $null = $OutputDataTable.Columns.Add($Property.Name, $Property.TypeNameOfValue)
                }
            }
            $null = $OutputDataTable.Rows.Add($PSCustomObject.PSObject.Properties.Value)
        }
    }
    end {
        , $OutputDataTable
    }
}


function Format-Test {
    <#
        .SYNOPSIS
        Adds "TestName" and "DataSet" to the test.
        Assumes $DataSetName and its value exists.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [Hashtable]$Test
    )
    if ($DataSetName, $Test.Params.Left, $Test.Params.Right -contains $null) {
        Throw 'Missing param'
    }

    $Data = '{0}, {1} - {2}' -f $DataSetName, $Test.Params.Left, $Test.Params.Right
    $OutputType = switch ($Test.Params) {
        { $_.DataTable } { 'DataTable' }
        { $_.PassThru } { 'PassThru' }
    }
    $OutputType = if ($OutputType) {
        '{0}' -f ($OutputType -join '&')
    }
    $Description = if ($Test.Description) {
        '({0})' -f $Test.Description
    }



    $Test.TestName = (($Data, $Test.Params.Type, $OutputType, $Description) -ne $null) -join '. '
    $Test.DataSet = Get-Variable -Name $DataSetName -ValueOnly
    $Test
}
function Get-Params {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String]$Param
    )
    $ParamSplit = $Param -split '(?<=\])(?<!$)|(?=\[)(?!^)'
    if ($ParamSplit[0] -eq '[PSCustomObject]') {
        $Output = (Get-Variable -Name $ParamSplit[1]).Value | ConvertFrom-DataTable
    }
    elseif ($ParamSplit[0] -eq '[DataTable]') {
        $Output = (Get-Variable -Name $ParamSplit[1]).Value | ConvertTo-DataTable
    }
    else {
        $Output = (Get-Variable -Name $ParamSplit[0]).Value
    }
    if ($ParamSplit[-1] -like '`[*]') {
        , $Output.Item($ParamSplit[-1].Trim('[]'))
    }
    else {
        , $Output
    }
}

Describe -Name 'Join-Object' -Fixture {
    Context -Name ($DataSetName = 'DataSetSmall') -Fixture {
        Class EqualityComparerMy : Collections.Generic.EqualityComparer[Object] {
            [bool] Equals([Object]$Object1 , [Object]$Object2) {
                if ($Object1 -contains $Object2 -or $Object1 -in $Object2) {
                    return $true
                }
                else {
                    return $false
                }
            }
            [int] GetHashCode([Object]$Object) {
                return 1
            }
        }
        $TestCases = @(
            Format-Test @{
                Description          = 'Error, Mismatch'
                ExpectedErrorOn      = 'Test'
                ExpectedErrorMessage = "Object{ID=3; R_IntT=; R_Name=X; Subscription=S3}'."
                Params               = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description          = 'Error, Mismatch'
                ExpectedErrorOn      = 'Test'
                ExpectedErrorMessage = "but some values were missing: 'PSObject{IDD=3; IntT=; Junk=S3; Name=X; R_IntO=; R_Sub=S3}"
                Params               = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObject'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }

            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Params = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObject'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    RightProperties       = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                }
            }
            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Params = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObject'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    RightProperties       = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    Type                  = 'AllInBoth'
                }
            }
            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'OnlyIfInBoth'
                }
            }
            Format-Test @{
                Params = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObject'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    RightProperties       = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    Type                  = 'OnlyIfInBoth'
                }
            }

            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                }
            }
            Format-Test @{
                Params = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObject'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    LeftProperties        = @{ IDD = 'IDD' ; Name = 'NewName' }
                    RightProperties       = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    PassThru              = $true
                }
            }
            Format-Test @{
                Description          = 'Error, PassThru+AllInBoth'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-PassThru" and "-Type AllInBoth" are not compatible'
                Params               = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Description          = 'Error, PassThru+AllInBoth'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-PassThru" and "-Type AllInBoth" are not compatible'
                Params               = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObject'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    LeftProperties        = @{ IDD = 'IDD' ; Name = 'NewName' }
                    RightProperties       = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    PassThru              = $true
                    Type                  = 'AllInBoth'
                }
            }
            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                    Type                   = 'OnlyIfInBoth'
                }
            }
            Format-Test @{
                Params = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObject'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    LeftProperties        = @{ IDD = 'IDD' ; Name = 'NewName' }
                    RightProperties       = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    PassThru              = $true
                    Type                  = 'OnlyIfInBoth'
                }
            }

            Format-Test @{
                Params = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObject'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }
            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }
            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
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
                Params = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObject'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Params = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'OnlyIfInBoth'
                }
            }
            Format-Test @{
                Params = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObject'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'OnlyIfInBoth'
                }
            }

            Format-Test @{
                Description = 'Ordered'
                Params      = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = [Ordered]@{ Sub = 'Subscription' ; ID = 'ID' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'DBNull to $null'
                Params      = @{
                    Left              = 'PSCustomObject'
                    Right             = 'DataTable'
                    LeftJoinProperty  = 'ID'
                    RightJoinProperty = 'IDD'
                }
            }
            Format-Test @{
                Description = 'Single'
                Params      = @{
                    Left                   = 'PSCustomObject[0]'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'KeepRightJoinProperty'
                Params      = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    KeepRightJoinProperty  = $true
                }
            }
            Format-Test @{
                Description = 'Multi Join'
                Params      = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID', 'Sub'
                    RightJoinProperty      = 'IDD', 'Junk'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'JoinScript'
                Params      = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'Sub'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    LeftJoinScript         = { param ($Line) ($Line.Sub).Replace('S', 'X') }
                    RightJoinScript        = { param ($Line) 'X' + $Line.IDD }
                }
            }
            Format-Test @{
                Description = 'JoinScript String'
                Params      = @{
                    Left                   = 'PSCustomObject'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'Sub'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ ID = 'ID' ; Sub = 'Subscription' }
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    LeftJoinScript         = { param ($Line) ($Line.Sub).Replace('S', '') }
                }
            }
            Format-Test @{
                Description = 'DataTableTypes'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObject'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    DataTableTypes         = @{ R_IntO = [Int] }
                }
            }
            Format-Test @{
                Description = 'DataTableTypes'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObject'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                    DataTableTypes         = @{ R_IntO = [Int] }
                }
            }
            Format-Test @{
                Description          = 'Error, No AllowColumnsMerging'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = "Item has already been added. Key in dictionary: 'Junk'"
                Params               = @{
                    Left              = 'DataTable'
                    Right             = 'PSCustomObjectJunk'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                }
            }
            Format-Test @{
                Description          = 'Error, AllowColumnsMerging-DataTable'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-AllowColumnsMerging" support only on DataTable output'
                Params               = @{
                    Left                = 'DataTable'
                    Right               = 'PSCustomObjectJunk'
                    LeftJoinProperty    = 'IDD'
                    RightJoinProperty   = 'ID'
                    AllowColumnsMerging = $true
                }
            }
            Format-Test @{
                Description = 'AllowColumnsMerging'
                Params      = @{
                    Left                = 'DataTable'
                    Right               = 'PSCustomObjectJunk'
                    LeftJoinProperty    = 'IDD'
                    RightJoinProperty   = 'ID'
                    AllowColumnsMerging = $true
                    DataTable           = $true
                }
            }
            Format-Test @{
                Description          = 'Error, AllowColumnsMerging-OutDataTable'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-AllowColumnsMerging" support only on DataTable output'
                Params               = @{
                    Left                = 'PSCustomObjectJunk'
                    Right               = 'DataTable'
                    LeftJoinProperty    = 'IDD'
                    RightJoinProperty   = 'ID'
                    AllowColumnsMerging = $true
                    PassThru            = $true
                }
            }
            Format-Test @{
                Description = 'AllowColumnsMerging'
                Params      = @{
                    Left                = 'DataTable'
                    Right               = 'PSCustomObjectJunk'
                    LeftJoinProperty    = 'IDD'
                    RightJoinProperty   = 'ID'
                    AllowColumnsMerging = $true
                    PassThru            = $true
                }
            }
            Format-Test @{
                Description = 'AllowColumnsMerging'
                Params      = @{
                    Left                = 'DataTable'
                    Right               = '[DataTable]PSCustomObjectJunk'
                    LeftJoinProperty    = 'IDD'
                    RightJoinProperty   = 'ID'
                    AllowColumnsMerging = $true
                    PassThru            = $true
                }
            }
            Format-Test @{
                Description = 'Comparer'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjectKeyArray'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    RightJoinScript        = [System.Func[Object, Object]] { param ($Line) $Line.ID }
                    Comparer               = [EqualityComparerMy]::new()
                }
            }

            Format-Test @{
                Description          = 'Error, SingleOnly+BasicJoin'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-Type AllInLeft" and "-Type OnlyIfInBoth" support only "-LeftMultiMode DuplicateLines"'
                Params               = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInLeft'
                    LeftMultiMode          = 'SingleOnly'
                }
            }
            Format-Test @{
                Description          = 'Error, SingleOnly+BasicJoin'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-Type OnlyIfInBoth" support only "-RightMultiMode DuplicateLines"'
                Params               = @{
                    Left              = 'DataTableMulti'
                    Right             = 'PSCustomObjectMulti'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                    Prefix            = 'R_'
                    DataTable         = $true
                    Type              = 'OnlyIfInBoth'
                    RightMultiMode    = 'SingleOnly'
                }
            }
            Format-Test @{
                Description          = 'Error, SingleOnly'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = 'Sequence contains more than one element'
                Params               = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInLeft'
                    RightMultiMode         = 'SingleOnly'
                }
            }
            Format-Test @{
                Description          = 'Error, SingleOnly'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = 'Sequence contains more than one element'
                Params               = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                    LeftMultiMode          = 'SingleOnly'
                }
            }
            Format-Test @{
                Description = 'DuplicateLines'
                Params      = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                    LeftMultiMode          = 'DuplicateLines'
                    RightMultiMode         = 'DuplicateLines'
                }
            }
            Format-Test @{
                Description = 'DuplicateLines'
                Params      = @{
                    Left              = 'DataTableMulti'
                    Right             = 'PSCustomObjectMulti'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                    Prefix            = 'R_'
                    DataTable         = $true
                    Type              = 'AllInBoth'
                    LeftMultiMode     = 'DuplicateLines'
                    RightMultiMode    = 'DuplicateLines'
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                    LeftMultiMode          = 'SubGroups'
                    RightMultiMode         = 'SubGroups'
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left              = 'DataTableMulti'
                    Right             = 'PSCustomObjectMulti'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                    Prefix            = 'R_'
                    DataTable         = $true
                    Type              = 'AllInBoth'
                    LeftMultiMode     = 'SubGroups'
                    RightMultiMode    = 'SubGroups'
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'AllInBoth'
                    LeftMultiMode          = 'SubGroups'
                    RightMultiMode         = 'SubGroups'
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left              = 'DataTableMulti'
                    Right             = 'PSCustomObjectMulti'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                    Prefix            = 'R_'
                    Type              = 'AllInBoth'
                    LeftMultiMode     = 'SubGroups'
                    RightMultiMode    = 'SubGroups'
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'AllInLeft'
                    RightMultiMode         = 'SubGroups'
                    PassThru               = $true
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = '[PSCustomObject]DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'AllInLeft'
                    RightMultiMode         = 'SubGroups'
                    PassThru               = $true
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left              = 'DataTableMulti'
                    Right             = 'PSCustomObjectMulti'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                    Prefix            = 'R_'
                    Type              = 'AllInLeft'
                    RightMultiMode    = 'SubGroups'
                    PassThru          = $true
                }
            }
            Format-Test @{
                Description = 'SubGroups'
                Params      = @{
                    Left              = 'DataTableMulti'
                    Right             = '[DataTable]PSCustomObjectMulti'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                    Prefix            = 'R_'
                    Type              = 'AllInLeft'
                    RightMultiMode    = 'SubGroups'
                    PassThru          = $true
                }
            }
            Format-Test @{
                Description = 'SubGroups Key'
                Params      = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'AllInBoth'
                    LeftMultiMode          = 'SubGroups'
                    RightMultiMode         = 'SubGroups'
                    AddKey                 = $true
                }
            }
            Format-Test @{
                Description          = 'Error, AddKey-AllInBoth'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-AddKey" support only "-Type AllInBoth"'
                Params               = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    LeftMultiMode          = 'SubGroups'
                    RightMultiMode         = 'SubGroups'
                    AddKey                 = $true
                }
            }
            Format-Test @{
                Description = 'SubGroups Key'
                Params      = @{
                    Left                   = 'PSCustomObjectMulti'
                    Right                  = 'DataTableMulti'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    ExcludeLeftProperties  = 'ID'
                    Prefix                 = 'R_'
                    Type                   = 'AllInBoth'
                    LeftMultiMode          = 'DuplicateLines'
                    RightMultiMode         = 'SubGroups'
                    AddKey                 = $true
                    DataTable              = $true
                    KeepRightJoinProperty  = $true
                }
            }
            Format-Test @{
                Description = 'SubArray'
                RunScript   = { Set-ItResult -Pending -Because 'Bug?' }
                Params      = @{
                    Left              = 'DataTable'
                    Right             = 'PSCustomObjectMulti'
                    LeftJoinProperty  = 'IDD'
                    RightJoinProperty = 'ID'
                    Prefix            = 'R_'
                    RightMultiMode    = 'DuplicateLines'
                }
            }
        )
        if ($FilterTests) {
            $TestCases = $TestCases | Where-Object TestName -In $FilterTests
        }
        It -name "Testing <TestName>" -TestCases $TestCases -test {
            param (
                $Params,
                $DataSet,
                $TestName,
                $RunScript,
                $ExpectedErrorMessage,
                [ValidateSet('Test', 'Run')]
                $ExpectedErrorOn
            )
            # Load Data
            . $DataSet
            if ($RunScript) {
                . $RunScript
            }
            $Params.Left = Get-Params -Param $Params.Left
            $Params.Right = Get-Params -Param $Params.Right

            # Save Before Data Copy
            $BeforeLeft = [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($Params.Left, 3))
            $BeforeRight = [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($Params.Right, 3))

            # Execute Cmdlet
            if ($ExpectedErrorOn -eq 'Run') {
                { $JoinedOutput = Join-Object @Params } | Should -Throw -ExpectedMessage $ExpectedErrorMessage
                Continue
            }
            else {
                $JoinedOutput = Join-Object @Params
            }
            Write-Verbose ('it returns:' + ($JoinedOutput | Format-Table | Out-String))

            # Save CompareData (Xml)
            if ($SaveMode) {
                Write-Host ($TestName + ($JoinedOutput | Format-Table | Out-String))

                if ($JoinedOutput -is [Array] -and ($SubArrayTest = $JoinedOutput | ForEach-Object { $_ -is [Array] }) -contains $true) {
                    Write-Warning ("SubArrayTest $SubArrayTest")
                }
                Export-Clixml -LiteralPath "$ScriptRoot\CompareData\$TestName.xml" -InputObject $JoinedOutput -Depth 3 -Confirm
            }

            # Get CompareData
            $CompareDataXml = (Get-Content -LiteralPath "$ScriptRoot\CompareData\$TestName.xml") -join [Environment]::NewLine
            $CompareDataNew = [System.Management.Automation.PSSerializer]::Deserialize($CompareDataXml)
            Write-Verbose ('it should return:' + ($CompareDataNew | Format-Table | Out-String))

            # Test
            if ($ExpectedErrorOn -eq 'Test') {
                { Assert-Equivalent -Actual $JoinedOutput -Expected $CompareDataNew -Options $EquivalencyOption } | Should -Throw -ExpectedMessage $ExpectedErrorMessage
            }
            else {
                Assert-Equivalent -Actual $JoinedOutput -Expected $CompareDataNew -Options $EquivalencyOption
            }

            if ($Params.PassThru) {
                Assert-Equivalent -Actual $Params.Left -Expected $CompareDataNew -Options $EquivalencyOption
            }
            else {
                Assert-Equivalent -Actual $Params.Left -Expected $BeforeLeft -Options $EquivalencyOption
            }
            Assert-Equivalent -Actual $Params.Right -Expected $BeforeRight -Options $EquivalencyOption

            if (!$Params.PassThru) {
                if ($Params.DataTable) {
                    Should -BeOfType -ActualValue $JoinedOutput -ExpectedType 'System.Data.DataTable'
                    $JoinedOutput | Should -BeOfType -ExpectedType 'System.Data.DataRow'
                }
                else {
                    if ($JoinedOutput.Count -gt 1) {
                        Should -BeOfType -ActualValue $JoinedOutput -ExpectedType 'System.Array'
                    }
                    else {
                        Should -BeOfType -ActualValue $JoinedOutput -ExpectedType 'PSCustomObject'
                    }
                    $JoinedOutput | Should -BeOfType -ExpectedType 'PSCustomObject'
                }
            }
        }
    }
}