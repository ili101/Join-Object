# Join-Object (Beta)
Join-Object LINQ Edition.
Aims to provide the exact functibility of https://github.com/RamblingCookieMonster/PowerShell/blob/master/Join-Object.ps1 with much better performance.
Initial testing shows at last 100 times faster.

| Master | PowerShell Gallery | Beta | Alpha |
|--------|--------------------|------|-------|
|[![Build status](https://ci.appveyor.com/api/projects/status/sk2d54q6q85i1ejm/branch/master?svg=true)](https://ci.appveyor.com/project/ili101/join-object)|[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Join-Object.svg)](https://www.powershellgallery.com/packages/Join-Object/) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/Join-Object.svg)](https://www.powershellgallery.com/packages/Join-Object/)|[![Build status](https://ci.appveyor.com/api/projects/status/sk2d54q6q85i1ejm/branch/Beta?svg=true)](https://ci.appveyor.com/project/ili101/join-object)|[![Build status](https://ci.appveyor.com/api/projects/status/sk2d54q6q85i1ejm/branch/Alpha?svg=true)](https://ci.appveyor.com/project/ili101/join-object)|

## Explanation and usage Examples
See RamblingCookieMonster guide http://ramblingcookiemonster.github.io/Join-Object/ and [Join-Object.Examples.ps1](https://github.com/ili101/Join-Object/blob/master/Examples/Join-Object.Examples.ps1)

## Additional functoriality
* Supports DataTable object type.
* Additional parameters **-ExcludeLeftProperties** and **-ExcludeRightProperties**.
* Additional parameter **-PassThru**, If added changes the original Left Object
* Converts DBNull to $null
* **-RightJoinScript** and **-LeftJoinScript** parameters to support custom joining scripts.
* -RightJoinProperty and -LeftJoinProperty supports multiple Properties (String Array) to join on multiple columns.
* **-DataTable** parameter to output as "DataTable".

## To do and missing functoriality
* -Type Parameter supports for "AllInBoth" ~~and "AllInRight"~~.
* Optimize performance

## Install
From repository
```PowerShell
Install-Module -Name Join-Object -Scope CurrentUser
```
From GitHub
```PowerShell
$Uri = 'https://raw.githubusercontent.com/ili101/Join-Object/master/Install.ps1'; & ([Scriptblock]::Create((irm $Uri))) -FromGitHub $Uri
```

## Contributing
If you fund a bug or added functionality or anything else just fork and send pull requests. Thank you!

##  Changelog
[CHANGELOG.md](https://github.com/ili101/Join-Object/blob/master/CHANGELOG.md)

# More PowerShell stuff
https://github.com/ili101/PowerShell