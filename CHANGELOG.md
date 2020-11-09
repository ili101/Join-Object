## 2.0.2 - 2020/11/09 (Stable)
### New
* Add support for [ArrayList] input in addition for [Array] And [DataTable].

## 2.0.1 - 2019/08/24 (Stable)
### Documentation
* Updated Description and Tags.

## 2.0.0 - 2019/08/22 (Stable)
### New
* PowerShell Core 7 is now supported!
* `-LeftJoinScript` and `-RightJoinScript` now support non string output (String is still used if scriptblock provided and not Func\`2).
* `-Comparer` allow use of custom [EqualityComparer].
### Fixed
* Fixed DuplicateLines with non DataTable output can create output with "hidden" sub arrays. Linq Join seems to not unroll the output so for example you can get this output:
```
IDD Name Junk IntT R_Sub R_IntO
--- ---- ---- ---- ----- ------
  1 A    AAA     5 S1         6
  1 A    AAA     5 S12       62
  3 C    S3
  4 D
```
It looks like an array with 4 lines of PSCustomObjects but it's actually an array with 3 lines as the first line is actually an array containing the first 2 lines. This will be unrolled in the new version to an array with 4 PSCustomObjects. :warning: breaking change.
* PowerShell Core 7: Join-Object SubGroups [EmptyPartition`1] Fix.
* `-PassThru` will now throw an error when used with `-Type OnlyIfInBoth` as lines cannot be removed, and with `-Type AllInLeft` + `-RightMultiMode DuplicateLines` as lines cannot be duplicated. :warning: breaking change.
### Changed
`-AddKey` is now a String that takes the name of the key column to create. :warning: breaking change.
### Improved
* `/Examples/Join-Object.Examples.ps1` was updated.
### Updated
* MoreLinq Updated to 3.2.0.
### Testing
* Update To Module.Template 2.0.1, Test now use Azure pipeline Windows 2019 and AppVeyor on Ubuntu1804 and Windows 2019 (PowerShell Framework and core 7.0.0 Preview 3).
* Update to custom version of Assert 0.9.5.
* PowerShell Core 7: Test 1 ExpectedErrorMessage Fix.
* PowerShell Core 7: Tests PSCustomObject.Count -eq 1 Fix.
### Code Cleanup
* Change format to VSCode default on all files.
* cSpell.words updated and spelling corrections.
* Refactor Tests.
* Refactor Join-Object.

## 1.0.1 - 2018/12/17 (Stable)
### Added
* **-AllowColumnsMerging** Allow duplicate columns in the Left and Right Objects, will overwrite the conflicting Left data with the Right data (Ignoring Nulls), Supported only on DataTable output for now.

## 1.0.0 - 2018/11/20 (Stable)
### Improved
* Major rewrite of the code, The main Scriptblock is now dynamically constructed.
* Error handling with $PSCmdlet.ThrowTerminatingError.
### Fixed
* Undo "Fix JoinFunction scope to support JoinProperty" (Unnecessary feature).
### Added
* **-LeftMultiMode** and **-RightMultiMode** with options ('SingleOnly', 'DuplicateLines', 'SubGroups').
* **-AddKey** can be used with "-Type AllInBoth" to add a column named "Key" containing the joining key.
### Removed
* **-MultiLeft** replaced by MultiMode.
* **-RightAsGroup** replaced by MultiMode.

:warning: if you used the GitHub (Beta branch) version there are breaking changes.

## 0.1.8 - 2018/11/07 (Beta branch)
### Updated
* MoreLinq updated to 3.0.0.
### Fixed
* Fix Multi JoinProperty comparing column name.
* Fix JoinFunction scope to support JoinProperty.
* Minor bug fixes and improvements.

## 0.1.7 - 2018/03/13 (Beta branch)
### Added
* **-Type AllInBoth** option.
* **-DataTableTypes [Hashtable]** allow Overwrite of DataTable columns types.
* **-RightAsGroup [String]** Join the right side as sub table in column with the selected name.
* **-MultiLeft** allow multiple rows on the left side.
* **-KeepRightJoinProperty** don't remove the right join property.
### Fixed
* Remove unused parameter option **-Type AllInRight**

## 0.1.6 - 2018/03/13 (Beta)
### Fixed
* Error "Cannot set Column 'foo' to be null. Please use DBNull instead." when using -DataTable and -AllInLeft and some Left lines don't have Right lines to join to.

## 0.1.5 - 2018/03/11 (Beta)
### Fixed
* Error "Cannot set Column 'foo' to be null. Please use DBNull instead." when using -DataTable on DataTable data with nulls in it.

## 0.1.4 - 2018/03/08 (Beta)
### Added
* **-DataTable** parameter to output as "DataTable".
### Fixed
* Output when using PassThru on "-Left DataTable" was returning "Array" with "DataRow"s instead of "DataTable" with "DataRow"s Object.

## 0.1.2 - 2018/03/05 (Beta)
### Added
* **-Type** parameter that supports "AllInLeft" and "OnlyIfInBoth".
* **-RightJoinScript** and **-LeftJoinScript** parameters to support custom joining scripts.
* **-RightJoinProperty** and **-LeftJoinProperty** now supports multiple Properties (String Array) to join on multiple columns.

## 0.1.1 - 2017-09-19 (Beta)
### Added
* Convert DBNull to $null when going from DataTable to PSCustomObject.

## 0.1.0 - 2017-09-19 (Beta)
* Join-Object initial release.

## 0.0.0 - 2017-07-28 (Alpha)
* Join-Object LINQ Edition concept code.