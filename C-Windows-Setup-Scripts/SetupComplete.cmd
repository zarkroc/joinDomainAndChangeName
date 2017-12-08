@echo off
>c:\setup\log_setshell.txt (
  %SystemRoot%\System32\WindowsPowershell\v1.0\powershell.exe -ExecutionPolicy Bypass -File C:\Setup\SetShell.ps1
)

CALL C:\Setup\accounts.bat
CALL C:\Setup\activateWindows\installera.bat 
rmdir /S /Q C:\Setup\activateWindows 

REM Begär tidssynk från SRV1
net time \\srv1 /SET /Y 


@echo off
>c:\setup\log_changename.txt (
REM Gå med i domänen och sätt korrekt IP.
REM %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy Unrestricted -Force"
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File C:\Setup\changeComputerName.ps1
)


shutdown -f -r