# Join-Object (Beta)
Join-Object LINQ Edition.
Aims to provide the exact functibility of https://github.com/RamblingCookieMonster/PowerShell/blob/master/Join-Object.ps1 with much better performance.
Initial testing shows at last 100 times faster.

## Explanation and usage Examples
See RamblingCookieMonster guide http://ramblingcookiemonster.github.io/Join-Object/ and [Join-Object.Examples.ps1](https://github.com/ili101/PowerShell/blob/master/Examples/Join-Object.Examples.ps1)

## Additional functoriality
* Supports DataTable object type.
* Additional parameters **-ExcludeLeftProperties** and **-ExcludeRightProperties**.
* Additional parameter **-PassThru**, If added changes the original Left Object
* Converts DBNull to $null

## To do and missing functoriality
* -Type Parameter supports for "AllInBoth" ~~and "AllInRight"~~.
* Optimize performance
* Option to output as "DataTable"

## Install
From repository
```PowerShell
Install-Module -Name Join-Object -Scope CurrentUser
```
From GitHub
```PowerShell
$Uri = 'https://github.com/ili101/Join-Object/raw/master/Install.ps1'; . ([Scriptblock]::Create((iwr $Uri).Content)) -FromGitHub $Uri
```

## Contributing
If you fund a bug or added functionality or anything else just fork and send pull requests. Thank you!

##  Changelog
[CHANGELOG.md](https://github.com/ili101/Join-Object/blob/master/CHANGELOG.md)
