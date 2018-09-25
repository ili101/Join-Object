# Fix Could not create SSL/TLS secure channel
$SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest 'https://github.com/ili101/Assert/archive/master.zip' -OutFile "$env:TEMP\Assert-Master.zip"
[Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol

Expand-Archive -Path "$env:TEMP\Assert-Master.zip" -DestinationPath $env:TEMP

Import-Module -Name "$env:TEMP\Assert-master\Assert.psd1"