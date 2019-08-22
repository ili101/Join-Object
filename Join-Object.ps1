using namespace System.Data
Add-Type -AssemblyName System.Data.DataSetExtensions
function Join-Object {
    <#
    .SYNOPSIS
        Join data from two sets of objects based on a common value

    .DESCRIPTION
        Join data from two sets of objects based on a common value

        For more details, see the accompanying blog post:
            http://ramblingcookiemonster.github.io/Join-Object/

        For even more details,  see the original code and discussions that this borrows from:
            Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections
            Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

    .PARAMETER Left
        'Left' collection of objects to join.  You can use the pipeline for Left.

        The objects in this collection should be consistent.
        We look at the properties on the first object for a baseline.

    .PARAMETER Right
        'Right' collection of objects to join.

        The objects in this collection should be consistent.
        We look at the properties on the first object for a baseline.

    .PARAMETER LeftJoinProperty
        Property on Left collection objects that we match up with RightJoinProperty on the Right collection

    .PARAMETER RightJoinProperty
        Property on Right collection objects that we match up with LeftJoinProperty on the Left collection

    .PARAMETER LeftProperties
        One or more properties to keep from Left.  Default is to keep all Left properties (*).

        Each property can:
            - Be a plain property name like "Name"
            - Contain wildcards like "*"
            - Be a Hashtable like @{Name="Product Name";Expression={$_.Name}}.
                 Name is the output property name
                 Expression is the property value ($_ as the current object)

                 Alternatively, use the Suffix or Prefix parameter to avoid collisions
                 Each property using this Hashtable syntax will be excluded from suffixes and prefixes

    .PARAMETER RightProperties
        One or more properties to keep from Right.  Default is to keep all Right properties (*).

        Each property can:
            - Be a plain property name like "Name"
            - Contain wildcards like "*"
            - Be a Hashtable like @{Name="Product Name";Expression={$_.Name}}.
                 Name is the output property name
                 Expression is the property value ($_ as the current object)

                 Alternatively, use the Suffix or Prefix parameter to avoid collisions
                 Each property using this Hashtable syntax will be excluded from suffixes and prefixes

    .PARAMETER Prefix
        If specified, prepend Right object property names with this prefix to avoid collisions

        Example:
            Property Name                   = 'Name'
            Suffix                          = 'j_'
            Resulting Joined Property Name  = 'j_Name'

    .PARAMETER Suffix
        If specified, append Right object property names with this suffix to avoid collisions

        Example:
            Property Name                   = 'Name'
            Suffix                          = '_j'
            Resulting Joined Property Name  = 'Name_j'

    .PARAMETER Type
        Type of join.  Default is AllInLeft.

        AllInLeft will have all elements from Left at least once in the output, and might appear more than once
          if the where clause is true for more than one element in right, Left elements with matches in Right are
          preceded by elements with no matches.
          SQL equivalent: outer left join (or simply left join)

        AllInRight is similar to AllInLeft.

        OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
          match in Right.
          SQL equivalent: inner join (or simply join)

        AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
          in right with at least one match in left, followed by all entries in Right with no matches in left,
          followed by all entries in Left with no matches in Right.
          SQL equivalent: full join

    .EXAMPLE
        #
        #Define some input data.

        $l = 1..5 | Foreach-Object {
            [PSCustomObject]@{
                Name = "jsmith$_"
                Birthday = (Get-Date).adddays(-1)
            }
        }

        $r = 4..7 | Foreach-Object{
            [PSCustomObject]@{
                Department = "Department $_"
                Name = "Department $_"
                Manager = "jsmith$_"
            }
        }

        #We have a name and Birthday for each manager, how do we find their department, using an inner join?
        Join-Object -Left $l -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type OnlyIfInBoth -RightProperties Department


            # Name    Birthday             Department
            # ----    --------             ----------
            # jsmith4 4/14/2015 3:27:22 PM Department 4
            # jsmith5 4/14/2015 3:27:22 PM Department 5

    .EXAMPLE
        #
        #Define some input data.

        $l = 1..5 | Foreach-Object {
            [PSCustomObject]@{
                Name = "jsmith$_"
                Birthday = (Get-Date).adddays(-1)
            }
        }

        $r = 4..7 | Foreach-Object{
            [PSCustomObject]@{
                Department = "Department $_"
                Name = "Department $_"
                Manager = "jsmith$_"
            }
        }

        #We have a name and Birthday for each manager, how do we find all related department data, even if there are conflicting properties?
        $l | Join-Object -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type AllInLeft -Prefix j_

            # Name    Birthday             j_Department j_Name       j_Manager
            # ----    --------             ------------ ------       ---------
            # jsmith1 4/14/2015 3:27:22 PM
            # jsmith2 4/14/2015 3:27:22 PM
            # jsmith3 4/14/2015 3:27:22 PM
            # jsmith4 4/14/2015 3:27:22 PM Department 4 Department 4 jsmith4
            # jsmith5 4/14/2015 3:27:22 PM Department 5 Department 5 jsmith5

    .EXAMPLE
        #
        #Hey!  You know how to script right?  Can you merge these two CSVs, where Path1's IP is equal to Path2's IP_ADDRESS?

        #Get CSV data
        $s1 = Import-CSV $Path1
        $s2 = Import-CSV $Path2

        #Merge the data, using a full outer join to avoid omitting anything, and export it
        Join-Object -Left $s1 -Right $s2 -LeftJoinProperty IP_ADDRESS -RightJoinProperty IP -Prefix 'j_' -Type AllInBoth |
            Export-CSV $MergePath -NoTypeInformation

    .EXAMPLE
        #
        # "Hey Warren, we need to match up SSNs to Active Directory users, and check if they are enabled or not.
        #  I'll e-mail you an unencrypted CSV with all the SSNs from gmail, what could go wrong?"

        # Import some SSNs.
        $SSNs = Import-CSV -Path D:\SSNs.csv

        #Get AD users, and match up by a common value, SamAccountName in this case:
        Get-ADUser -Filter "SamAccountName -like 'WFrame*'" |
            Join-Object -LeftJoinProperty SamAccountName -Right $SSNs `
                        -RightJoinProperty SamAccountName -RightProperties ssn `
                        -LeftProperties SamAccountName, enabled, ObjectClass

    .NOTES
        This borrows from:
            Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections/
            Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

        Changes:
            Always display full set of properties
            Display properties in order (left first, right second)
            If specified, add suffix or prefix to right object property names to avoid collisions
            Use a Hashtable rather than OrderedDictionary (avoid case sensitivity)

    .LINK
        http://ramblingcookiemonster.github.io/Join-Object/

    .FUNCTIONALITY
        PowerShell Language

    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        $Left,
        [Parameter(Mandatory = $true)]
        $Right,

        [Parameter(Mandatory = $true)]
        [string[]]$LeftJoinProperty,
        [Parameter(Mandatory = $true)]
        [string[]]$RightJoinProperty,

        $LeftJoinScript,
        $RightJoinScript,

        [ValidateScript( { $_ -is [Collections.Hashtable] -or $_ -is [string] -or $_ -is [Collections.Specialized.OrderedDictionary] } )]
        $LeftProperties = '*',
        [ValidateScript( { $_ -is [Collections.Hashtable] -or $_ -is [string] -or $_ -is [Collections.Specialized.OrderedDictionary] } )]
        $RightProperties = '*',

        [string[]]$ExcludeLeftProperties,
        [string[]]$ExcludeRightProperties,

        [switch]$KeepRightJoinProperty,

        [ValidateSet('AllInLeft', 'OnlyIfInBoth', 'AllInBoth')]
        [Parameter(Mandatory = $false)]
        [string]$Type = 'AllInLeft',

        [string]$Prefix,
        [string]$Suffix,

        [Parameter(Mandatory, ParameterSetName = 'PassThru')]
        [switch]$PassThru,
        [Parameter(Mandatory, ParameterSetName = 'DataTable')]
        [switch]$DataTable,
        [Parameter(ParameterSetName = 'PassThru')]
        [Parameter(ParameterSetName = 'DataTable')]
        [Hashtable]$DataTableTypes,

        [ValidateSet('SingleOnly', 'DuplicateLines', 'SubGroups')]
        [string]$LeftMultiMode = 'SingleOnly',
        [ValidateSet('SingleOnly', 'DuplicateLines', 'SubGroups')]
        [string]$RightMultiMode = 'SingleOnly',

        [String]$AddKey,
        [switch]$AllowColumnsMerging,
        [Collections.Generic.IEqualityComparer[Object]]$Comparer
    )
    #region Validate Params
    if ($PassThru -and ($Type -in ('AllInBoth', 'OnlyIfInBoth') -or ($Type -eq 'AllInLeft' -and $RightMultiMode -eq 'DuplicateLines'))) {
        $PSCmdlet.ThrowTerminatingError(
            [Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new('"-PassThru" compatible only with "-Type AllInLeft" with "-RightMultiMode" "SingleOnly" or "SubGroups"'),
                'Incompatible Arguments',
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $Type
            )
        )
    }

    if ($AddKey -and $Type -ne 'AllInBoth') {
        $PSCmdlet.ThrowTerminatingError(
            [Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new('"-AddKey" support only "-Type AllInBoth"'),
                'Incompatible Arguments',
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $AddKey
            )
        )
    }

    if ($Type -in 'AllInLeft', 'OnlyIfInBoth') {
        if ($PSBoundParameters['LeftMultiMode'] -ne 'DuplicateLines' -and $null -ne $PSBoundParameters['LeftMultiMode']) {
            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [ArgumentException]::new('"-Type AllInLeft" and "-Type OnlyIfInBoth" support only "-LeftMultiMode DuplicateLines"'),
                    'Incompatible Arguments',
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $Type
                )
            )
        }
        $Attributes = (Get-Variable 'LeftMultiMode').Attributes
        $null = $Attributes.Remove($Attributes.Where( { $_.TypeId.Name -eq 'ValidateSetAttribute' } )[0])
        $ValidateSetAttribute = [System.Management.Automation.ValidateSetAttribute]::new('SingleOnly', 'DuplicateLines', 'SubGroups', $null)
        $Attributes.Add($ValidateSetAttribute)
        $LeftMultiMode = $null
    }
    if ($Type -in 'OnlyIfInBoth') {
        if ($PSBoundParameters['RightMultiMode'] -ne 'DuplicateLines' -and $null -ne $PSBoundParameters['RightMultiMode']) {
            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [ArgumentException]::new('"-Type OnlyIfInBoth" support only "-RightMultiMode DuplicateLines"'),
                    'Incompatible Arguments',
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $Type
                )
            )
        }
        $Attributes = (Get-Variable 'RightMultiMode').Attributes
        $null = $Attributes.Remove($Attributes.Where( { $_.TypeId.Name -eq 'ValidateSetAttribute' } )[0])
        $ValidateSetAttribute = [System.Management.Automation.ValidateSetAttribute]::new('SingleOnly', 'DuplicateLines', 'SubGroups', $null)
        $Attributes.Add($ValidateSetAttribute)
        $RightMultiMode = $null
    }

    if ($AllowColumnsMerging -and !$DataTable -and !($PassThru -and $Left -is [DataTable])) {
        $PSCmdlet.ThrowTerminatingError(
            [Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new('"-AllowColumnsMerging" support only on DataTable output'),
                'Incompatible Arguments',
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $AllowColumnsMerging
            )
        )
    }
    #endregion Validate Params
    #region Set $SelectedLeftProperties and $SelectedRightProperties
    function Get-Properties {
        [CmdletBinding()]
        param
        (
            $Object,
            $SelectProperties,
            $ExcludeProperties,
            $Prefix,
            $Suffix
        )
        $Properties = [ordered]@{ }
        if ($Object -is [System.Data.DataTable]) {
            $ObjectProperties = $Object.Columns.ColumnName
        }
        else {
            $ObjectProperties = $Object[0].PSObject.Properties.Name
        }
        if ($SelectProperties -is [Hashtable] -or $SelectProperties -is [Collections.Specialized.OrderedDictionary]) {
            $SelectProperties.GetEnumerator() | Where-Object { $_.Key -notin $ExcludeProperties } | ForEach-Object { $Properties.Add($_.Key, $Prefix + $_.Value + $Suffix) }
        }
        elseif ($SelectProperties -eq '*') {
            $ObjectProperties | Where-Object { $_ -notin $ExcludeProperties } | ForEach-Object { $Properties.Add($_, $Prefix + $_ + $Suffix) }
        }
        else {
            $SelectProperties | Where-Object { $_ -notin $ExcludeProperties } | ForEach-Object { $Properties.Add($_, $Prefix + $_ + $Suffix) }
        }
        $Properties
    }

    $SelectedLeftProperties = Get-Properties -Object $Left  -SelectProperties $LeftProperties  -ExcludeProperties $ExcludeLeftProperties
    if (!$KeepRightJoinProperty) {
        $ExcludeRightProperties = @($ExcludeRightProperties) + @($RightJoinProperty) -ne $null
    }
    $SelectedRightProperties = Get-Properties -Object $Right -SelectProperties $RightProperties -ExcludeProperties $ExcludeRightProperties -Prefix $Prefix -Suffix $Suffix
    #endregion Set $SelectedLeftProperties and $SelectedRightProperties
    #region Importing package MoreLinq
    if ($Type -eq 'AllInBoth') {
        try {
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
            if (!('MoreLinq.MoreEnumerable' -as [type])) {
                Add-Type -Path (Resolve-Path -Path "$ScriptRoot\morelinq.*\lib\netstandard2.0\MoreLinq.dll")
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError(
                [Management.Automation.ErrorRecord]::new(
                    [TypeLoadException]::new('Importing package MoreLinq failed: {0}' -f $_.Exception.Message, $_.Exception),
                    'Importing package',
                    [Management.Automation.ErrorCategory]::NotInstalled,
                    $null
                )
            )
        }
    }
    #endregion Importing package MoreLinq
    #region Set $RightJoinScript and $LeftJoinScript
    function Get-JoinScript {
        [CmdletBinding()]
        param
        (
            $JoinScript,
            $JoinProperty,
            $Side,
            $Object
        )
        if ($JoinScript) {
            if ($JoinScript.GetType().Name -eq 'Func`2') {
                $JoinScript #.GetNewClosure()
            }
            else {
                [System.Func[Object, String]]$JoinScript
            }
        }
        else {
            $JoinScript = if ($JoinProperty.Count -gt 1) {
                {
                    param ($_Side_Line)
                    ($_Side_Line | Select-Object -Property $_Side_JoinProperty).PSObject.Properties.Value
                }
            }
            else {
                if ($Object -is [Data.DataTable]) {
                    {
                        param ($_Side_Line)
                        $_Side_Line[$_Side_JoinProperty]
                    }
                }
                else {
                    {
                        param ($_Side_Line)
                        $_Side_Line.$_Side_JoinProperty
                    }
                }
            }
            [System.Func[Object, String]][Scriptblock]::Create($JoinScript.ToString().Replace('_Side_', $Side))
        }
    }
    $LeftJoinScript = Get-JoinScript -JoinScript $LeftJoinScript -JoinProperty $LeftJoinProperty -Side 'Left' -Object $Left
    $RightJoinScript = Get-JoinScript -JoinScript $RightJoinScript -JoinProperty $RightJoinProperty -Side 'Right' -Object $Right
    #endregion Set $RightJoinScript and $LeftJoinScript
    #region Prepare Data
    function Set-OutDataTable {
        param
        (
            $OutDataTable,
            $Object,
            $SelectedProperties,
            $AllowColumnsMerging
        )
        # Create Columns
        foreach ($item in $SelectedProperties.GetEnumerator()) {
            if (!$AllowColumnsMerging -or !$OutDataTable.Columns.Item($item.Value)) {
                if ($Object -is [Data.DataTable]) {
                    $null = $OutDataTable.Columns.Add($item.Value, $Object.Columns.Item($item.Name).DataType)
                }
                else {
                    if ($null -ne $DataTableTypes.($item.Value)) {
                        $null = $OutDataTable.Columns.Add($item.Value, $DataTableTypes.($item.Value))
                    }
                    else {
                        $null = $OutDataTable.Columns.Add($item.Value)
                    }
                }
            }
        }
    }
    if ($DataTable) {
        $OutDataTable = [Data.DataTable]::new('Joined')
        if ($AddKey) {
            $null = $OutDataTable.Columns.Add($AddKey)
        }
        if ($LeftMultiMode -eq 'SubGroups') {
            $OutDataTableSubGroupTemplateLeft = [Data.DataTable]::new('LeftGroup')
            Set-OutDataTable -OutDataTable $OutDataTableSubGroupTemplateLeft -Object $Left -SelectedProperties $SelectedLeftProperties
            $null = $OutDataTable.Columns.Add('LeftGroup', [Object])
        }
        else {
            Set-OutDataTable -OutDataTable $OutDataTable -Object $Left -SelectedProperties $SelectedLeftProperties
        }
        if ($RightMultiMode -eq 'SubGroups') {
            $OutDataTableSubGroupTemplateRight = [Data.DataTable]::new('RightGroup')
            Set-OutDataTable -OutDataTable $OutDataTableSubGroupTemplateRight -Object $Right -SelectedProperties $SelectedRightProperties
            $null = $OutDataTable.Columns.Add('RightGroup', [Object])
        }
        else {
            Set-OutDataTable -OutDataTable $OutDataTable -Object $Right -SelectedProperties $SelectedRightProperties -AllowColumnsMerging $AllowColumnsMerging
        }
    }
    elseif ($PassThru) {
        if ($Left -is [Data.DataTable]) {
            # Remove LeftLine
            foreach ($ColumnName in $Left.Columns.ColumnName) {
                if ($ColumnName -notin $SelectedLeftProperties.Keys) {
                    $Left.Columns.Remove($ColumnName)
                }
            }
            # Rename LeftLine
            foreach ($item in $SelectedLeftProperties.GetEnumerator()) {
                if ($item.Key -ne $item.value -and ($Column = $Left.Columns.Item($item.Key))) {
                    $Column.ColumnName = $item.value
                }
            }
            if ($RightMultiMode -eq 'SubGroups') {
                $null = $Left.Columns.Add('RightGroup', [Object])
            }
            else {
                # Add RightLine to LeftLine
                foreach ($item in $SelectedRightProperties.GetEnumerator()) {
                    if (!$AllowColumnsMerging -or !$Left.Columns.Item($item.Value)) {
                        if ($null -ne $DataTableTypes.($item.Value)) {
                            $null = $Left.Columns.Add($item.Value, $DataTableTypes.($item.Value))
                        }
                        else {
                            $null = $Left.Columns.Add($item.Value)
                        }
                    }
                }
            }
        }
        if ($Right -is [Data.DataTable] -and $RightMultiMode -eq 'SubGroups') {
            $OutDataTableSubGroupTemplateRight = [Data.DataTable]::new('RightGroup')
            Set-OutDataTable -OutDataTable $OutDataTableSubGroupTemplateRight -Object $Right -SelectedProperties $SelectedRightProperties
        }
    }
    #endregion Prepare Data
    #region Main
    #region Main: Set $QueryParts
    $QueryParts = @{
        'IfSideLine'                       = {
            if ($_Side_Line) {
                _SideScript_
            }
        }
        'DataTableFromAny'                 = {
            foreach ($item in $Selected_Side_Properties.GetEnumerator()) {
                if ($null -ne ($Value = $_Side_Line.($item.Key))) {
                    $_Row_[$item.Value] = $Value
                }
            }
        }
        'DataTableFromDataTable'           = {
            foreach ($item in $Selected_Side_Properties.GetEnumerator()) {
                if (($Value = $_Side_Line[$item.Key]) -isnot [DBNull]) {
                    $_Row_[$item.Value] = $Value
                }
            }
        }
        'DataTableFromSubGroup'            = {
            if ($_Side_Lines) {
                _SubGroup_
                $_Row_['_Side_Group'] = $OutSubGroup_Side_
            }
        }
        'SubGroupFromDataTable'            = {
            $OutSubGroup_Side_ = $OutDataTableSubGroupTemplate_Side_.Clone()
            foreach ($_Side_Line in $_Side_Lines) {
                $RowSubGroup = $OutSubGroup_Side_.Rows.Add()
                _DataTable_
            }
        }
        'SubGroupFromPSCustomObject'       = {
            $OutSubGroup_Side_ = @()
            foreach ($_Side_Line in $_Side_Lines) {
                $RowSubGroup = [ordered]@{ }
                _PSCustomObject_
                $OutSubGroup_Side_ += [PSCustomObject]$RowSubGroup
            }
        }
        'PSCustomObjectFromPSCustomObject' = {
            foreach ($item in $Selected_Side_Properties.GetEnumerator()) {
                $_Row_.Add($item.Value, $_Side_Line.($item.Key))
            }
        }
        'PSCustomObjectFromAny'            = {
            foreach ($item in $Selected_Side_Properties.GetEnumerator()) {
                if (($Value = $_Side_Line.($item.Key)) -is [DBNull]) {
                    $Value = $null
                }
                $_Row_.Add($item.Value, $Value)
            }
        }
        'PSCustomObjectFromSubGroup'       = {
            if ($_Side_Lines) {
                _SubGroup_
                $_Row_.Add('_Side_Group', $OutSubGroup_Side_)
            }
            else {
                $_Row_.Add('_Side_Group', $null)
            }
        }
    }

    foreach ($Item in @($QueryParts.GetEnumerator())) {
        $QueryParts[$Item.Key] = $Item.Value.ToString()
    }
    #endregion Main: Set $QueryParts
    #region Main: Set $Query
    $Query = if ($PassThru) {
        if ($Left -is [Data.DataTable]) {
            $QueryTemp = @{
                Main        = { _SidesScript_ }
                SideReplace = '_Row_', 'LeftLine'
            }
            if ($RightMultiMode -eq 'SubGroups') {
                $QueryTemp['SideSubGroupBase'] = $QueryParts['DataTableFromSubGroup']
                if ($Right -is [Data.DataTable]) {
                    $QueryTemp['SideSubGroup'] = $QueryParts['SubGroupFromDataTable']
                }
                else {
                    $QueryTemp['SideSubGroup'] = $QueryParts['SubGroupFromPSCustomObject']
                }
            }
            else {
                $QueryTemp['Right'] = { _DataTable_ }
            }
            $QueryTemp
        }
        else {
            # Left is PSCustomObject
            $QueryTemp = @{
                # Edit PSCustomObject
                Main        = {
                    # Add to LeftLine (Rename)
                    foreach ($item in $SelectedLeftProperties.GetEnumerator()) {
                        if ($item.Value -notin $LeftLine.PSObject.Properties.Name) {
                            $LeftLine.PSObject.Properties.Add([Management.Automation.PSNoteProperty]::new($item.Value, $LeftLine.($item.Key)))
                        }
                    }
                    # Remove from LeftLine
                    foreach ($item in $LeftLine.PSObject.Properties.Name) {
                        if ($item -notin $SelectedLeftProperties.Values) {
                            $LeftLine.PSObject.Properties.Remove($item)
                        }
                    }
                    _SidesScript_
                }
                SideReplace = '_Row_\.Add([^\r\n]*)', 'LeftLine.PSObject.Properties.Add([Management.Automation.PSNoteProperty]::new$1)'
            }
            if ($RightMultiMode -eq 'SubGroups') {
                $QueryTemp['SideSubGroupBase'] = $QueryParts['PSCustomObjectFromSubGroup']
                if ($Right -is [Data.DataTable]) {
                    $QueryTemp['SideSubGroup'] = $QueryParts['SubGroupFromDataTable']
                }
                else {
                    $QueryTemp['SideSubGroup'] = $QueryParts['SubGroupFromPSCustomObject']
                }
            }
            else {
                $QueryTemp['Right'] = { _PSCustomObject_ }
            }
            $QueryTemp
        }
    }
    elseif ($DataTable) {
        $QueryTemp = @{
            Main        = {
                $RowMain = $OutDataTable.Rows.Add()
                _SidesScript_
            }
            SideReplace = '_Row_', 'RowMain'
        }
        if ($LeftMultiMode -eq 'SubGroups' -or $RightMultiMode -eq 'SubGroups') {
            $QueryTemp['SideSubGroupBase'] = $QueryParts['DataTableFromSubGroup']
            $QueryTemp['SideSubGroup'] = $QueryParts['SubGroupFromDataTable']
        }
        if ($LeftMultiMode -ne 'SubGroups' -or $RightMultiMode -ne 'SubGroups') {
            $QueryTemp['Side'] = { _DataTable_ }
        }
        $QueryTemp
    }
    else {
        # PSCustomObject
        $QueryTemp = @{
            Main        = {
                $RowMain = [ordered]@{ }
                _SidesScript_
                [PSCustomObject]$RowMain
            }
            SideReplace = '_Row_', 'RowMain'
        }
        if ($LeftMultiMode -eq 'SubGroups' -or $RightMultiMode -eq 'SubGroups') {
            $QueryTemp['SideSubGroupBase'] = $QueryParts['PSCustomObjectFromSubGroup']
            $QueryTemp['SideSubGroup'] = $QueryParts['SubGroupFromPSCustomObject']
        }
        if ($LeftMultiMode -ne 'SubGroups' -or $RightMultiMode -ne 'SubGroups') {
            $QueryTemp['Side'] = { _PSCustomObject_ }
        }
        $QueryTemp
    }

    $Query['Base'] = {
        param(
            #_$Key_,
            $LeftLine,
            $RightLine
        )
    }

    foreach ($Item in @($Query.GetEnumerator())) {
        if ($Item.Value -is [Scriptblock]) {
            $Query[$Item.Key] = $Item.Value.ToString()
        }
    }
    #endregion Main: Set $Query
    #region Main: Assemble $Query
    function Invoke-AssembledQuery {
        param (
            $MultiMode,
            $Side,
            $Object
        )
        if ($MultiMode -eq 'SingleOnly') {
            $Query[$Side + 'Enumerable'] = { $_Side_Line = [System.Linq.Enumerable]::SingleOrDefault($_Side_Line) }
        }
        elseif ($MultiMode -eq 'DuplicateLines') {
            $Query[$Side + 'Enumerable'] = { $_Side_Lines = [System.Linq.Enumerable]::DefaultIfEmpty($_Side_Line) }
            $Query['Main'] = {
                foreach ($_Side_Line in $_Side_Lines) {
                    _MainScript_
                }
            }.ToString().Replace('_Side_', $Side).Replace('_MainScript_', $Query['Main'])
        }
        if ($MultiMode -eq 'SubGroups') {
            $Query[$Side + 'Enumerable'] = { $_Side_Lines = if ($_Side_Line.Count) { $_Side_Line } }
            $Query[$Side] = if ($Object -is [Data.DataTable]) {
                ($Query['SideSubGroupBase'] -Replace $Query['SideReplace']).Replace('_SubGroup_', $Query['SideSubGroup']).Replace('_DataTable_', $QueryParts['DataTableFromDataTable']).Replace('_PSCustomObject_', $QueryParts['PSCustomObjectFromAny'])
            }
            else {
                ($Query['SideSubGroupBase'] -Replace $Query['SideReplace']).Replace('_SubGroup_', $Query['SideSubGroup']).Replace('_DataTable_', $QueryParts['DataTableFromAny']).Replace('_PSCustomObject_', $QueryParts['PSCustomObjectFromPSCustomObject'])
            }
            $Query[$Side] = $Query[$Side].Replace('_Row_', 'RowSubGroup')
        }
        else {
            if ($Query[$Side] -or $Query['Side']) {
                if ($null -eq $Query[$Side]) {
                    $Query[$Side] = $Query['Side']
                }
                if ($null -ne $MultiMode -and $Query[$Side] -like '*_DataTable_*') {
                    $Query[$Side] = $QueryParts['IfSideLine'].Replace('_SideScript_', $Query[$Side])
                }
                $Query[$Side] = if ($Object -is [Data.DataTable]) {
                    $Query[$Side].Replace('_DataTable_', $QueryParts['DataTableFromDataTable']).Replace('_PSCustomObject_', $QueryParts['PSCustomObjectFromAny'])
                }
                else {
                    $Query[$Side].Replace('_DataTable_', $QueryParts['DataTableFromAny']).Replace('_PSCustomObject_', $QueryParts['PSCustomObjectFromPSCustomObject'])
                }
                $Query[$Side] = $Query[$Side] -Replace $Query['SideReplace']
            }
        }
        if ($Query[$Side]) {
            $Query[$Side] = $Query[$Side].Replace('_Side_', $Side)
        }
        if ($Query[$Side + 'Enumerable']) {
            $Query[$Side + 'Enumerable'] = $Query[$Side + 'Enumerable'].ToString().Replace('_Side_', $Side)
        }
    }
    Invoke-AssembledQuery -MultiMode $LeftMultiMode -Side 'Left' -Object $Left
    Invoke-AssembledQuery -MultiMode $RightMultiMode -Side 'Right' -Object $Right

    if ($AddKey) {
        $KeyScript = {
            $RowMain._Key_ = $Key
            _SidesScript_
        }.ToString()
        $KeyScript = if ($DataTable) {
            $KeyScript.Replace('._Key_', "['$AddKey']")
        }
        else {
            $KeyScript.Replace('_Key_', $AddKey)
        }
        $Query['Main'] = $Query['Main'].Replace('_SidesScript_', $KeyScript)
    }

    $Query['Main'] = $Query['Main'].Replace('_SidesScript_', $Query['Left'] + $Query['Right'])

    if ($Type -eq 'OnlyIfInBoth') {
        [System.Func[System.Object, System.Object, System.Object]]$Query = [Scriptblock]::Create($Query['Base'] + $Query['Main'])
    }
    elseif ($Type -eq 'AllInLeft') {
        [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], System.Object]]$Query = [Scriptblock]::Create($Query['Base'] + $Query['RightEnumerable'] + $Query['Main'])
    }
    elseif ($Type -eq 'AllInBoth') {
        [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], [Collections.Generic.IEnumerable[System.Object]], System.Object]]$Query = [Scriptblock]::Create($Query['Base'].Replace('#_$Key_', '$Key') + $Query['LeftEnumerable'] + "`n" + $Query['RightEnumerable'] + $Query['Main'])
    }
    #endregion Main: Assemble $Query
    #endregion Main
    #region Execute
    if ($Left -is [Data.DataTable]) {
        $LeftNew = [DataTableExtensions]::AsEnumerable($Left)
    }
    elseif ($Left -is [PSCustomObject]) {
        $LeftNew = @($Left)
    }
    else {
        $LeftNew = $Left
    }
    if ($Right -is [Data.DataTable]) {
        $RightNew = [DataTableExtensions]::AsEnumerable($Right)
    }
    elseif ($Right -is [PSCustomObject]) {
        $RightNew = @($Right)
    }
    else {
        $RightNew = $Right
    }

    try {
        $Result = if ($Type -eq 'OnlyIfInBoth') {
            [System.Linq.Enumerable]::ToArray(
                [System.Linq.Enumerable]::Join($LeftNew, $RightNew, $LeftJoinScript, $RightJoinScript, $query, $Comparer)
            )
        }
        elseif ($Type -eq 'AllInBoth') {
            [System.Linq.Enumerable]::ToArray(
                [MoreLinq.MoreEnumerable]::FullGroupJoin($LeftNew, $RightNew, $LeftJoinScript, $RightJoinScript, $query, $Comparer)
            )
        }
        else {
            [System.Linq.Enumerable]::ToArray(
                [System.Linq.Enumerable]::GroupJoin($LeftNew, $RightNew, $LeftJoinScript, $RightJoinScript, $query, $Comparer)
            )
        }

        if ($PassThru) {
            , $Left
        }
        elseif ($DataTable) {
            , $OutDataTable
        }
        elseif ($LeftMultiMode -eq 'DuplicateLines' -or $RightMultiMode -eq 'DuplicateLines') {
            $Result.ForEach( { $_ } )
        }
        else {
            $Result
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    #endregion Execute
}