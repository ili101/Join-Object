using namespace System.Data
Add-Type -AssemblyName System.Data.DataSetExtensions
function Join-Object
{
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
            - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}.
                 Name is the output property name
                 Expression is the property value ($_ as the current object)
                
                 Alternatively, use the Suffix or Prefix parameter to avoid collisions
                 Each property using this hashtable syntax will be excluded from suffixes and prefixes

    .PARAMETER RightProperties
        One or more properties to keep from Right.  Default is to keep all Right properties (*).

        Each property can:
            - Be a plain property name like "Name"
            - Contain wildcards like "*"
            - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}.
                 Name is the output property name
                 Expression is the property value ($_ as the current object)
                
                 Alternatively, use the Suffix or Prefix parameter to avoid collisions
                 Each property using this hashtable syntax will be excluded from suffixes and prefixes

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
            [pscustomobject]@{
                Name = "jsmith$_"
                Birthday = (Get-Date).adddays(-1)
            }
        }

        $r = 4..7 | Foreach-Object{
            [pscustomobject]@{
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
            [pscustomobject]@{
                Name = "jsmith$_"
                Birthday = (Get-Date).adddays(-1)
            }
        }

        $r = 4..7 | Foreach-Object{
            [pscustomobject]@{
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

        #Get AD users, and match up by a common value, samaccountname in this case:
        Get-ADUser -Filter "samaccountname -like 'wframe*'" |
            Join-Object -LeftJoinProperty samaccountname -Right $SSNs `
                        -RightJoinProperty samaccountname -RightProperties ssn `
                        -LeftProperties samaccountname, enabled, objectclass

    .NOTES
        This borrows from:
            Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections/
            Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

        Changes:
            Always display full set of properties
            Display properties in order (left first, right second)
            If specified, add suffix or prefix to right object property names to avoid collisions
            Use a hashtable rather than ordereddictionary (avoid case sensitivity)

    .LINK
        http://ramblingcookiemonster.github.io/Join-Object/

    .FUNCTIONALITY
        PowerShell Language

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine = $true)]
        [ValidateScript({ $_ -is [PSCustomObject] -or $_ -is [Data.DataRow] })]
        $Left,

        # List to join with $Left
        [Parameter(Mandatory=$true)]
        [ValidateScript({ $_ -is [PSCustomObject] -or $_ -is [Data.DataRow] })]
        $Right,

        [Parameter(Mandatory = $true)]
        [string[]] $LeftJoinProperty,

        [Parameter(Mandatory = $true)]
        [string[]] $RightJoinProperty,

        [ScriptBlock]$RightJoinScript,
        [ScriptBlock]$LeftJoinScript,

        [ValidateScript({ $_ -is [Collections.Hashtable] -or $_ -is [string] -or $_ -is [Collections.Specialized.OrderedDictionary]})]
        $LeftProperties = '*',

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [ValidateScript({ $_ -is [Collections.Hashtable] -or $_ -is [string] -or $_ -is [Collections.Specialized.OrderedDictionary] })]
        $RightProperties = '*',

        [string[]]$ExcludeLeftProperties,
        [string[]]$ExcludeRightProperties,

        [validateset( 'AllInLeft', 'OnlyIfInBoth', 'AllInBoth')]
        [Parameter(Mandatory=$false)]
        [string]$Type = 'AllInLeft',

        [string]$Prefix,
        [string]$Suffix,
        [switch]$PassThru,
        [switch]$DataTable
    )
    if ($Left -is [PSCustomObject])
    {
        $Left = @($Left)
    }
    if ($Right -is [PSCustomObject])
    {
        $Right = @($Right)
    }
    
    function Get-Properties ($ObjectProperties,$SelectProperties,$ExcludeProperties,$Prefix,$Suffix)
    {
        $Properties = [ordered]@{}
        if ($SelectProperties -is [hashtable] -or $SelectProperties -is [Collections.Specialized.OrderedDictionary])
        {
            <#
            foreach ($ExcludeProperty in $ExcludeProperties)
            {
                $SelectProperties.Remove($ExcludeProperty)
            }
            [array]::Reverse($SelectProperties.Keys) | ForEach-Object {$SelectProperties[$_] = $Prefix + $SelectProperties[$_] + $Suffix}
            $SelectProperties
            #>
            $SelectProperties.GetEnumerator() | Where-Object {$_.Key -notin $ExcludeProperties} | ForEach-Object {$Properties.Add($_.Key,$Prefix + $_.Value + $Suffix)}
        }
        elseif ($SelectProperties -eq '*')
        {
            $ObjectProperties | Where-Object {$_ -notin $ExcludeProperties} | ForEach-Object {$Properties.Add($_,$Prefix + $_ + $Suffix)}
        }
        else
        {
            $SelectProperties | Where-Object {$_ -notin $ExcludeProperties} | ForEach-Object {$Properties.Add($_,$Prefix + $_ + $Suffix)}
        }
        $Properties
    }
    if ($Left -is [System.Data.DataTable])
    {
        $SelectedLeftProperties  = Get-Properties -ObjectProperties $Left.Columns.ColumnName  -SelectProperties $LeftProperties  -ExcludeProperties $ExcludeLeftProperties
    }
    else
    {
        $SelectedLeftProperties  = Get-Properties -ObjectProperties $Left[0].PSObject.Properties.Name  -SelectProperties $LeftProperties  -ExcludeProperties $ExcludeLeftProperties
    }
    if ($Right -is [System.Data.DataTable])
    {
        $SelectedRightProperties = Get-Properties -ObjectProperties $Right.Columns.ColumnName -SelectProperties $RightProperties -ExcludeProperties (@($ExcludeRightProperties)+@($RightJoinProperty) -ne $null) -Prefix $Prefix -Suffix $Suffix
    }
    else
    {
        $SelectedRightProperties = Get-Properties -ObjectProperties $Right[0].PSObject.Properties.Name -SelectProperties $RightProperties -ExcludeProperties (@($ExcludeRightProperties)+@($RightJoinProperty) -ne $null) -Prefix $Prefix -Suffix $Suffix
    }

    if ($Type -eq 'AllInBoth')
    {
        try
        {
            if (!$ScriptRoot)
            {
                $ScriptRoot = $PSScriptRoot
            }
            if(!('MoreLinq.MoreEnumerable' -as [type]))
            {
                Add-Type -Path (Resolve-Path -Path "$ScriptRoot\morelinq.3.0.0-beta-1\lib\net451\MoreLinq.dll")
            }
        }
        catch
        {
            throw '{0} Try running: "Install-Selenium"' -f $_
        }
    }

    if ($LeftJoinScript)
    {
        [System.Func[System.Object, string]]$LeftJoinFunction = $LeftJoinScript
    }
    elseif ($LeftJoinProperty.Count -gt 1)
    {
        [System.Func[System.Object, string]]$LeftJoinFunction = {
    	    param ($LeftLine) 
            $LeftLine | Select-Object -Property $LeftJoinProperty
        }
    }
    else
    {
        [System.Func[System.Object, string]]$LeftJoinFunction = {
    	    param ($LeftLine) 
    	    $LeftLine.$LeftJoinProperty
        }
    }

    if ($RightJoinScript)
    {
        [System.Func[System.Object, string]]$RightJoinFunction = $RightJoinScript
    }
    elseif ($RightJoinProperty.Count -gt 1)
    {
        [System.Func[System.Object, string]]$RightJoinFunction = {
    	    param ($RightLine) 
    	    $RightLine | Select-Object -Property $RightJoinProperty
        }
    }
    else
    {
        [System.Func[System.Object, string]]$RightJoinFunction = {
    	    param ($RightLine) 
    	    $RightLine.$RightJoinProperty
        }
    }

    if ($PassThru)
    {
        if ($Left -is [Data.DataTable])
        {
            # Remove LeftLine
            foreach ($ColumnName in $Left.Columns.ColumnName)
            {
                if ($ColumnName -notin $SelectedLeftProperties.Keys)
                {
                    $Left.Columns.Remove($ColumnName)
                }
            }
            # Rename LeftLine
            foreach ($item in $SelectedLeftProperties.GetEnumerator())
            {
                if ($item.Key -ne $item.value -and ($Column = $Left.Columns.Item($item.Key)))
                {
                    $Column.ColumnName = $item.value
                }
            }
            # Add RightLine to LeftLine
            foreach ($item in $SelectedRightProperties.GetEnumerator())
            {
                $null = $Left.Columns.Add($item.Value)
            }
        }

        if ($Type -eq 'OnlyIfInBoth')
        {
            [System.Func[System.Object, [System.Object], System.Object]]$query = {
        	    param(
        		    $LeftLine,
        		    $RightLine
        	    )

                if ($LeftLine -is [DataRow])
                {
                    # Add RightLine to LeftLine
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        $LeftLine.($item.Value) = $RightLine.($item.Key)
                    }
                }
                else # PSCustomObject
                {
                    # Add to LeftLine (Rename)
                    foreach ($item in $SelectedLeftProperties.GetEnumerator())
                    {
                        if ($item.Value -notin $LeftLine.PSObject.Properties.Name)
                        {
                            $LeftLine.PSObject.Properties.Add( [Management.Automation.PSNoteProperty]::new($item.Value,$LeftLine.($item.Key)) )
                        }
                    }
                    # Remove from LeftLine
                    foreach ($item in $LeftLine.PSObject.Properties.Name)
                    {
                        if ($item -notin $SelectedLeftProperties.Values)
                        {
                            $LeftLine.PSObject.Properties.Remove($item)
                        }
                    }
                    # Add RightLine to LeftLine
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        if (($Value = $RightLine.($item.Key)) -is [DBNull])
                        {
                            $Value = $null
                        }
                        $LeftLine.PSObject.Properties.Add( [Management.Automation.PSNoteProperty]::new($item.Value,$Value) )
                    }
                }
            }
        }
        elseif ($Type -eq 'AllInBoth')
        {
            [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], [Collections.Generic.IEnumerable[System.Object]], System.Object]]$query = {
        	    param(
                    $A,
        		    $LeftLineEnumerable,
        		    $RightLineEnumerable
        	    )
                $LeftLine = [System.Linq.Enumerable]::SingleOrDefault($LeftLineEnumerable)
                $RightLine = [System.Linq.Enumerable]::SingleOrDefault($RightLineEnumerable)

                if ($LeftLine -is [DataRow])
                {
                    # Add RightLine to LeftLine
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        $LeftLine.($item.Value) = $RightLine.($item.Key)
                    }
                }
                else # PSCustomObject
                {
                    # Add to LeftLine (Rename)
                    foreach ($item in $SelectedLeftProperties.GetEnumerator())
                    {
                        if ($item.Value -notin $LeftLine.PSObject.Properties.Name)
                        {
                            $LeftLine.PSObject.Properties.Add( [Management.Automation.PSNoteProperty]::new($item.Value,$LeftLine.($item.Key)) )
                        }
                    }
                    # Remove from LeftLine
                    foreach ($item in $LeftLine.PSObject.Properties.Name)
                    {
                        if ($item -notin $SelectedLeftProperties.Values)
                        {
                            $LeftLine.PSObject.Properties.Remove($item)
                        }
                    }
                    # Add RightLine to LeftLine
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        if (($Value = $RightLine.($item.Key)) -is [DBNull])
                        {
                            $Value = $null
                        }
                        $LeftLine.PSObject.Properties.Add( [Management.Automation.PSNoteProperty]::new($item.Value,$Value) )
                    }
                }
            }
        }
        else
        {
            [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], System.Object]]$query = {
        	    param(
        		    $LeftLine,
        		    $RightLineEnumerable
        	    )
                $RightLine = [System.Linq.Enumerable]::SingleOrDefault($RightLineEnumerable)

                if ($LeftLine -is [DataRow])
                {
                    # Add RightLine to LeftLine
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        $LeftLine.($item.Value) = $RightLine.($item.Key)
                    }
                }
                else # PSCustomObject
                {
                    # Add to LeftLine (Rename)
                    foreach ($item in $SelectedLeftProperties.GetEnumerator())
                    {
                        if ($item.Value -notin $LeftLine.PSObject.Properties.Name)
                        {
                            $LeftLine.PSObject.Properties.Add( [Management.Automation.PSNoteProperty]::new($item.Value,$LeftLine.($item.Key)) )
                        }
                    }
                    # Remove from LeftLine
                    foreach ($item in $LeftLine.PSObject.Properties.Name)
                    {
                        if ($item -notin $SelectedLeftProperties.Values)
                        {
                            $LeftLine.PSObject.Properties.Remove($item)
                        }
                    }
                    # Add RightLine to LeftLine
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        if (($Value = $RightLine.($item.Key)) -is [DBNull])
                        {
                            $Value = $null
                        }
                        $LeftLine.PSObject.Properties.Add( [Management.Automation.PSNoteProperty]::new($item.Value,$Value) )
                    }
                }
            }
        }
    }
    elseif ($DataTable)
    {
        $OutDataTable = [Data.DataTable]::new('Joined')
        # Create Columns
        foreach ($item in $SelectedLeftProperties.GetEnumerator())
        {
            if ($Left -is [Data.DataTable])
            {
                $null = $OutDataTable.Columns.Add($item.Value,$Left.Columns.Item($item.Name).DataType)
            }
            else
            {
                $null = $OutDataTable.Columns.Add($item.Value)
            }
        }
        foreach ($item in $SelectedRightProperties.GetEnumerator())
        {
            if ($Right -is [Data.DataTable])
            {
                $null = $OutDataTable.Columns.Add($item.Value,$Right.Columns.Item($item.Name).DataType)
            }
            else
            {
                $null = $OutDataTable.Columns.Add($item.Value)
            }
        }

        if ($Type -eq 'OnlyIfInBoth')
        {        
            [System.Func[System.Object, [System.Object], System.Object]]$query = {
        	    param(
        		    $LeftLine,
        		    $RightLine
        	    )
                $Row = $OutDataTable.Rows.Add()
                foreach ($item in $SelectedLeftProperties.GetEnumerator())
                {
                    $Row.($item.Value) = $LeftLine.($item.Key)
                }
                foreach ($item in $SelectedRightProperties.GetEnumerator())
                {
                    $Row.($item.Value) = $RightLine.($item.Key)
                }
            }
        }
        elseif ($Type -eq 'AllInBoth')
        {
            [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], [Collections.Generic.IEnumerable[System.Object]], System.Object]]$query = {
        	    param(
                    $A,
        		    $LeftLineEnumerable,
        		    $RightLineEnumerable
        	    )
                $LeftLine = [System.Linq.Enumerable]::SingleOrDefault($LeftLineEnumerable)
                $RightLine = [System.Linq.Enumerable]::SingleOrDefault($RightLineEnumerable)
                $Row = $OutDataTable.Rows.Add()
                if ($LeftLine)
                {  
                    foreach ($item in $SelectedLeftProperties.GetEnumerator())
                    {
                        $Row.($item.Value) = $LeftLine.($item.Key)
                    }
                }
                if ($RightLine)
                {              
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        $Row.($item.Value) = $RightLine.($item.Key)
                    }
                }
            }
        }
        else
        {
            [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], System.Object]]$query = {
        	    param(
        		    $LeftLine,
        		    $RightLineEnumerable
        	    )
                $RightLine = [System.Linq.Enumerable]::SingleOrDefault($RightLineEnumerable)
                $Row = $OutDataTable.Rows.Add()
                foreach ($item in $SelectedLeftProperties.GetEnumerator())
                {
                    $Row.($item.Value) = $LeftLine.($item.Key)
                }
                if ($RightLine)
                {              
                    foreach ($item in $SelectedRightProperties.GetEnumerator())
                    {
                        $Row.($item.Value) = $RightLine.($item.Key)
                    }
                }
            }
        }
    }
    else
    {
        if ($Type -eq 'OnlyIfInBoth')
        {        
            [System.Func[System.Object, [System.Object], System.Object]]$query = {
        	    param(
        		    $LeftLine,
        		    $RightLine
        	    )
                $Row = [ordered]@{}
                foreach ($item in $SelectedLeftProperties.GetEnumerator())
                {
                    if (($Value = $LeftLine.($item.Key)) -is [DBNull])
                    {
                        $Value = $null
                    }
                    $Row.Add($item.Value,$Value)
                }
                foreach ($item in $SelectedRightProperties.GetEnumerator())
                {
                    if (($Value = $RightLine.($item.Key)) -is [DBNull])
                    {
                        $Value = $null
                    }
                    $Row.Add($item.Value,$Value)
                }
                [PSCustomObject]$Row
            }
        }
        elseif ($Type -eq 'AllInBoth')
        {
            [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], [Collections.Generic.IEnumerable[System.Object]], System.Object]]$query = {
        	    param(
                    $A,
        		    $LeftLineEnumerable,
        		    $RightLineEnumerable
        	    )
                $LeftLine = [System.Linq.Enumerable]::SingleOrDefault($LeftLineEnumerable)
                $RightLine = [System.Linq.Enumerable]::SingleOrDefault($RightLineEnumerable)
                $Row = [ordered]@{}
                foreach ($item in $SelectedLeftProperties.GetEnumerator())
                {
                    if (($Value = $LeftLine.($item.Key)) -is [DBNull])
                    {
                        $Value = $null
                    }
                    $Row.Add($item.Value,$Value)
                }
                foreach ($item in $SelectedRightProperties.GetEnumerator())
                {
                    if (($Value = $RightLine.($item.Key)) -is [DBNull])
                    {
                        $Value = $null
                    }
                    $Row.Add($item.Value,$Value)
                }
                [PSCustomObject]$Row
            }
        }
        else
        {
            [System.Func[System.Object, [Collections.Generic.IEnumerable[System.Object]], System.Object]]$query = {
        	    param(
        		    $LeftLine,
        		    $RightLineEnumerable
        	    )
                $RightLine = [System.Linq.Enumerable]::SingleOrDefault($RightLineEnumerable)
                $Row = [ordered]@{}
                foreach ($item in $SelectedLeftProperties.GetEnumerator())
                {
                    if (($Value = $LeftLine.($item.Key)) -is [DBNull])
                    {
                        $Value = $null
                    }
                    $Row.Add($item.Value,$Value)
                }
                foreach ($item in $SelectedRightProperties.GetEnumerator())
                {
                    if (($Value = $RightLine.($item.Key)) -is [DBNull])
                    {
                        $Value = $null
                    }
                    $Row.Add($item.Value,$Value)
                }
                [PSCustomObject]$Row
            }
        }
    }

    if ($Left -is [Data.DataTable])
    {
        $LeftNew = [DataTableExtensions]::AsEnumerable($Left)
    }
    else
    {
        $LeftNew = $Left
    }
    if ($Right -is [Data.DataTable])
    {
        $RightNew = [DataTableExtensions]::AsEnumerable($Right)
    }
    else
    {
        $RightNew = $Right
    }

    if ($PassThru -or $DataTable)
    {
        if ($Type -eq 'OnlyIfInBoth')
        {
            $null = [System.Linq.Enumerable]::ToArray(
    	        [System.Linq.Enumerable]::Join($LeftNew, $RightNew, $LeftJoinFunction, $RightJoinFunction, $query)
            )
        }
        elseif ($Type -eq 'AllInBoth')
        {
            $null = [System.Linq.Enumerable]::ToArray(
    	        [MoreLinq.MoreEnumerable]::FullGroupJoin($LeftNew, $RightNew, $LeftJoinFunction, $RightJoinFunction, $query)
            )
        }
        else
        {
            $null = [System.Linq.Enumerable]::ToArray(
    	        [System.Linq.Enumerable]::GroupJoin($LeftNew, $RightNew, $LeftJoinFunction, $RightJoinFunction, $query)
            )
        }
        if ($PassThru)
        {
            ,$Left
        }
        else
        {
            ,$OutDataTable
        }
    }
    else
    {
        if ($Type -eq 'OnlyIfInBoth')
        {
            [System.Linq.Enumerable]::ToArray(
    	        [System.Linq.Enumerable]::Join($LeftNew, $RightNew, $LeftJoinFunction, $RightJoinFunction, $query)
            )
        }
        elseif ($Type -eq 'AllInBoth')
        {
            [System.Linq.Enumerable]::ToArray(
    	        [MoreLinq.MoreEnumerable]::FullGroupJoin($LeftNew, $RightNew, $LeftJoinFunction, $RightJoinFunction, $query)
            )
        }
        else
        {
            [System.Linq.Enumerable]::ToArray(
    	        [System.Linq.Enumerable]::GroupJoin($LeftNew, $RightNew, $LeftJoinFunction, $RightJoinFunction, $query)
            )
        }
    }
}