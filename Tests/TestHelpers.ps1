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

    if ($Test.Params.Left -is [Hashtable]) { $Test.Params.Left = [PSCustomObject]$Test.Params.Left }
    if ($Test.Params.Right -is [Hashtable]) { $Test.Params.Right = [PSCustomObject]$Test.Params.Right }

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
    <#
        .SYNOPSIS
        Get Data to test.
        If not DbConnection Param is String containing variable name, It will be fetched and optionally converted and selected on.
        If DbConnection Param is Hashtable with "Table" to get and "As" to set output type.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        $Param,
        [System.Data.Common.DbConnection]
        $DbConnection
    )
    if ($DbConnection) {
        $Output = Invoke-SqliteQuery -SQLiteConnection $DbConnection -Query ('SELECT * FROM {0}' -f $Param.Table) -As $Param.As
        , $Output
    }
    else {
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
}