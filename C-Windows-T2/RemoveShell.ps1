$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\setup\remove_shell_transcript_output.txt -append

$bindingFlags = [Reflection.BindingFlags] “Instance,NonPublic,GetField”
$objectRef = $host.GetType().GetField(“externalHostRef”, $bindingFlags).GetValue($host) 

$bindingFlags = [Reflection.BindingFlags] “Instance,NonPublic,GetProperty”
$consoleHost = $objectRef.GetType().GetProperty(“Value”, $bindingFlags).GetValue($objectRef, @()) 

[void] $consoleHost.GetType().GetProperty(“IsStandardOutputRedirected”, $bindingFlags).GetValue($consoleHost, @())
$bindingFlags = [Reflection.BindingFlags] “Instance,NonPublic,GetField”
$field = $consoleHost.GetType().GetField(“standardOutputWriter”, $bindingFlags)
$field.SetValue($consoleHost, [Console]::Out)
$field2 = $consoleHost.GetType().GetField(“standardErrorWriter”, $bindingFlags)
$field2.SetValue($consoleHost, [Console]::Out)


reg load hku\defaulthive "C:\Users\Default\ntuser.dat"
#Maps a drive to HKEY_USERS
New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS


Push-Location
Set-Location HKU:

$Path = "HKU:\defaulthive\Software\Microsoft\Windows\CurrentVersion\Policies\System"
Test-Path -Path $Path
if (Test-Path -Path $Path)
{
	$Exists = -Not ((Get-ItemProperty $Path).DisableTaskMgr -eq $null)
    if ($Exists)
	{
		Remove-ItemProperty -Path $Path -Name  DisableTaskMgr
	}
}
$Path = "HKU:\defaulthive\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Test-Path -Path $Path
if (Test-Path -Path $Path)
{
	$Exists = -Not ((Get-ItemProperty $Path).shell -eq $null)
    if ($Exists)
	{
		Remove-ItemProperty -Path $Path -Name  shell
	}
}

$Path = ""
Pop-Location
Remove-PSDrive HKU #Removes the drive mapping to HKEY_USERS
[gc]::collect()
reg unload hku\defaulthive #Attempts to unload the Default User hive

$Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
Test-Path -Path $Path
if (Test-Path -Path $Path)
{
	$Exists = -Not ((Get-ItemProperty $Path).DisableTaskMgr -eq $null)
    if ($Exists)
	{
		Remove-ItemProperty -Path $Path -Name  DisableTaskMgr
	}
}
$Path = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Test-Path -Path $Path
if (Test-Path -Path $Path)
{
	$Exists = -Not ((Get-ItemProperty $Path).shell -eq $null)
    if ($Exists)
	{
		Remove-ItemProperty -Path $Path -Name  shell
	}
}

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell -PropertyType String -Value "C:\Windows\explorer.exe"
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name  DisableTaskMgr -PropertyType DWord -Value 00000000
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell -PropertyType String -Value "C:\Windows\explorer.exe"
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name  DisableTaskMgr -PropertyType DWord -Value 00000000
Stop-Transcript