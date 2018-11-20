# Fix Could not create SSL/TLS secure channel
$SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Branch = 'Test' #'master'
$Repository = 'Assert'
Invoke-WebRequest "https://github.com/ili101/$Repository/archive/$Branch.zip" -OutFile "$env:TEMP\$Repository-$Branch.zip"
[Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol

Expand-Archive -Path "$env:TEMP\$Repository-$Branch.zip" -DestinationPath $env:TEMP

Import-Module -Name "$env:TEMP\$Repository-$Branch\$Repository.psd1"