#Get-ChildItem -Path $PSScriptRoot | Unblock-File
Get-ChildItem -Path $PSScriptRoot\*.ps1 -Exclude Class.ps1 | Foreach-Object{ . $_.FullName }