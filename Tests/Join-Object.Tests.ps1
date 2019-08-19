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
. "$ScriptRoot\TestHelpers.ps1"

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
                Params      = @{
                    Left              = 'PSCustomObjectMulti'
                    Right             = 'DataTable'
                    LeftJoinProperty  = 'ID'
                    RightJoinProperty = 'IDD'
                    Prefix            = 'R_'
                }
            }
            Format-Test @{
                Description = 'SubArray'
                #RunScript   = { Set-ItResult -Pending -Because 'Bug?' }
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
        It -Name "Testing: <TestName>" -TestCases $TestCases -Test {
            param (
                $Params,
                $DataSet,
                $TestName,
                $RunScript,
                $ExpectedErrorMessage,
                [ValidateSet('Test', 'Run')]
                $ExpectedErrorOn
            )
            if ($RunScript) {
                . $RunScript
            }

            # Load Data
            . $DataSet
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
                Write-Host ("{0}`nLeft:{1}Right:{2}Params:{3}Result:{4}" -f $TestName,
                    ($Params.Left | Format-Table | Out-String), ($Params.Right | Format-Table | Out-String),
                    (([PSCustomObject]$Params) | Select-Object -ExcludeProperty 'Left', 'Right' -Property '*' | Format-List | Out-String),
                    ($JoinedOutput | Format-Table | Out-String))

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