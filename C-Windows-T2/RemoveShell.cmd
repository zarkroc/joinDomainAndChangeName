@echo off
>c:\setup\log_removeShell.txt (
REM %SystemRoot%\System32\WindowsPowershell\v1.0\powershell.exe -ExecutionPolicy Bypass -File C:\Windows\T2\RemoveShell.ps1
C:\Setup\PsExec64.exe -i -s -acceptEula powershell.exe -ExecutionPolicy Bypass -File C:\Windows\T2\RemoveShell.ps1
rmdir /S /Q C:\windows\T2
)