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
