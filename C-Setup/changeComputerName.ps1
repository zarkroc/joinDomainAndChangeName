# Turn on logging:
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\setup\output_changeName.txt -append
#

# Read first part of hostname from file.
$fsrvName = Get-Content C:\Setup\fsrvType.ini
if ($fsrvName -eq "Klient") {
    $fsrvName = "PC"
}


# Create a random hostname
# With letters:
# $randomString = -join ((48..57) + (97..122) | Get-Random -Count 5 | % {[char]$_})
# With date and time format: HourMinSecond
$randomString = Get-Date -Format ddHHmmss
$hostname = $fsrvName + "-" + $randomString

# Rename the computer
Rename-Computer -NewName $hostname -Force

# Create a scheduled task that will run on the next start
# Hidden window
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty $RegPath "DefaultUsername" -Value "Administrator" -type String  
Set-ItemProperty $RegPath "DefaultPassword" -Value "!1!1qqweGerT1567asdf34fasd5jdkgf" -type String 
schtasks /create /tn "joinDomain" /sc onlogon /rl highest /ru administrator /tr  'wscript.exe "C:\Setup\invisible.vbs" "C:\Setup\joinDomain.bat"'
#schtasks /create /tn "joinDomain" /sc onlogon /rl highest /ru administrator /tr  "C:\Setup\joinDomain.bat" 

# Set time
net time \\srv1 /SET /Y
# Stop logging
Stop-Transcript