#Get-ChildItem -Path $PSScriptRoot | Unblock-File
Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Exclude 'Class.ps1', 'Install.ps1' | ForEach-Object { . $_.FullName }