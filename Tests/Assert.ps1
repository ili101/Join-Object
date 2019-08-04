# Fix Could not create SSL/TLS secure channel
#$SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Branch = 'Test' #'master'
$Repository = 'Assert'
$PathZip = (Join-Path $env:TEMP "$Repository-$Branch.zip")
Invoke-WebRequest "https://github.com/ili101/$Repository/archive/$Branch.zip" -OutFile $PathZip
#[Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol

Expand-Archive -Path $PathZip -DestinationPath $env:TEMP

Import-Module -Name (Join-Path $env:TEMP "$Repository-$Branch" | Join-Path -ChildPath "$Repository.psd1")