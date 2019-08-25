# Join-Object
Join-Object LINQ Edition.
Aims to provide the exact functionality of https://github.com/RamblingCookieMonster/PowerShell/blob/master/Join-Object.ps1 with much better performance.
Initial testing shows at last 100 times faster.

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Join-Object.svg)](https://www.powershellgallery.com/packages/Join-Object/)
[![Downloads](https://img.shields.io/powershellgallery/dt/Join-Object.svg)](https://www.powershellgallery.com/packages/Join-Object/)

| CI System    | Environment                   | Master                                                                                                                                                                                                                             | Beta                                                                                                                                                                                                                           |
|--------------|-------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AppVeyor     | Windows, Core preview, Ubuntu | [![Build status](https://ci.appveyor.com/api/projects/status/sk2d54q6q85i1ejm/branch/master?svg=true)](https://ci.appveyor.com/project/ili101/Join-Object)                                                                         | [![Build status](https://ci.appveyor.com/api/projects/status/sk2d54q6q85i1ejm/branch/Beta?svg=true)](https://ci.appveyor.com/project/ili101/Join-Object)                                                                       |
| Azure DevOps | Windows                       | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=master&jobName=Windows)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=master)       | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=Beta&jobName=Windows)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=Beta)       |
| Azure DevOps | Windows (Core)                | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=master&jobName=WindowsPSCore)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=master) | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=Beta&jobName=WindowsPSCore)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=Beta) |
| Azure DevOps | Ubuntu                        | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=master&jobName=Ubuntu)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=master)        | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=Beta&jobName=Ubuntu)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=Beta)        |
| Azure DevOps | macOS                         | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=master&jobName=macOS)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=master)         | [![Build Status](https://dev.azure.com/ili101/Join-Object/_apis/build/status/ili101.Join-Object?branchName=Beta&jobName=macOS)](https://dev.azure.com/ili101/Join-Object/_build/latest?definitionId=1&branchName=Beta)         |

## Explanation and usage Examples
See RamblingCookieMonster guide http://ramblingcookiemonster.github.io/Join-Object/ and [Join-Object.Examples.ps1](https://github.com/ili101/Join-Object/blob/master/Examples/Join-Object.Examples.ps1).
And also [Join-Object.Tests.ps1](https://github.com/ili101/Join-Object/blob/master/Tests/Join-Object.Tests.ps1).

``` PowerShell
# Left Object Example
$PSCustomObject = @(
    [PSCustomObject]@{ID = 1 ; Sub = 'S1' ; IntO = 6}
    [PSCustomObject]@{ID = 2 ; Sub = 'S2' ; IntO = 7}
    [PSCustomObject]@{ID = 3 ; Sub = 'S3' ; IntO = $null}
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

# Join the 2 together ("Left Join" in this example)
Join-Object -Left $PSCustomObject -Right $DataTable -LeftJoinProperty 'ID' -RightJoinProperty 'IDD' -ExcludeRightProperties 'Junk' -Prefix 'R_' | Format-Table

<# Output
    ID Sub IntO R_Name R_IntT
    -- --- ---- ------ ------
    1 S1     6 foo    123456
    2 S2     7
    3 S3       Bar
#>
```

## Additional functionality
* Supports DataTable object type.
* Additional parameters **-ExcludeLeftProperties** and **-ExcludeRightProperties**.
* Additional parameter **-PassThru**, If added changes the original Left Object
* Converts DBNull to $null
* **-RightJoinScript** and **-LeftJoinScript** parameters to support custom joining scripts.
* -RightJoinProperty and -LeftJoinProperty supports multiple Properties (String Array) to **join on multiple columns**.
* **-DataTable** parameter to output as "DataTable".
* **-AddKey** can be used with "-Type AllInBoth" to add a column containing the joining key.
* **-AllowColumnsMerging** Allow duplicate columns in the Left and Right Objects, will overwrite the conflicting Left data with the Right data (Ignoring Nulls), Supported only on DataTable output for now.
* **-Comparer** allow use of custom [EqualityComparer].

## Missing functionality
* -Type "AllInRight".

## To do
* Noting for now, You can open an Issues if something is needed.

## Install
From repository (Recommended)
```PowerShell
Install-Module -Name Join-Object -Scope CurrentUser
```
From GitHub Branch (For testing)
```PowerShell
$Uri = 'https://raw.githubusercontent.com/ili101/Join-Object/master/Install.ps1'; & ([Scriptblock]::Create((irm $Uri))) -FromGitHub $Uri
```

## Contributing
If you fund a bug or added functionality or anything else just fork and send pull requests. Thank you!

##  Changelog
[CHANGELOG.md](https://github.com/ili101/Join-Object/blob/master/CHANGELOG.md)

## Default and supported join modes
| Join Type     | Linq mode     | LeftMultiMode supported                   | RightMultiMode supported                  | PassThru              |
|---------------|---------------|-------------------------------------------|-------------------------------------------|-----------------------|
| OnlyIfInBoth  | Join          | **DuplicateLines**                        | **DuplicateLines**                        | Not Supported         |
| **AllInLeft** | GroupJoin     | **DuplicateLines**                        | **SingleOnly**, DuplicateLines, SubGroups | SingleOnly, SubGroups |
| AllInBoth     | FullGroupJoin | **SingleOnly**, DuplicateLines, SubGroups | **SingleOnly**, DuplicateLines, SubGroups | Not Supported         |

\* **Bold** signifies the default setting.

# More PowerShell stuff
https://github.com/ili101/PowerShell