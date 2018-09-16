#Get-ChildItem -Path $PSScriptRoot | Unblock-File
Get-ChildItem -Path '.\*.ps1' -Exclude 'Class.ps1', 'Install.ps1' | Foreach-Object {. $_.FullName}