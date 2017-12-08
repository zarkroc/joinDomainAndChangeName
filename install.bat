%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy Unrestricted -Force"
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe "%~dp0\placeGeneralDeployScripts.ps1"

cd \windows\system32\sysprep
Sysprep.exe /unattend:Unattend.xml /generalize /oobe /reboot