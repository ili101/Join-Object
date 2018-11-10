## 0.1.X - 2018/11/10 (Alpha branch)
* Major rewrite of main code.
### Fixed
* Undo "Fix JoinFunction scope to support JoinProperty".
### Added
* **-LeftMultiMode** and **-RightMultiMode** with options ('SingleOnly', 'DuplicateLines', 'SubGroups')
### Removed
* **-MultiLeft** replaced by MultiMode
* **-RightAsGroup** replaced by MultiMode

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
* **-MultiLeft** allow multyple rows on the left side.
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