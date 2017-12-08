@echo off
>c:\setup\log_removeShell.txt (
REM %SystemRoot%\System32\WindowsPowershell\v1.0\powershell.exe -ExecutionPolicy Bypass -File C:\Windows\T2\RemoveShell.ps1
C:\Setup\PsExec64.exe -i -s -acceptEula powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Windows\T2\RemoveShell.ps1
)

@echo off
>c:\setup\log_joinDomain.txt (
C:\Setup\PsExec64.exe -i -s -acceptEula powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -file C:\setup\joinDomain.ps1
REM Raden ovan kommer att starta om datorn, lägg till saker som skall utföras innan vi går med i domänen ovan den.
REM C:\Setup\PsExec64.exe -i -s -acceptEula powershell.exe -ExecutionPolicy Bypass -file C:\setup\joinDomain.ps1 
)

(
REM Utför saker efter att vi har gått med i domän. Special saker. Lägg till dessa här.
call c:\setup\postJoin.bat
)
