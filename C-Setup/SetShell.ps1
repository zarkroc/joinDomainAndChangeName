$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\setup\set_shell_transcript_output.txt -append

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

#Loads the default user registry hive which is used to create new users
reg load hku\defaulthive "C:\Users\default\ntuser.dat"
#Maps a drive to HKEY_USERS
New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS

#Store location so that we can return to it afterwards (must exit registry hive to be able to unload it)
Push-Location
Set-Location HKU:

echo "-----------------Testing if the default users registry is popoulated up to and including the system directory"
$Path = "HKU:\defaulthive\Software\Microsoft\Windows\CurrentVersion\Policies\System"
Test-Path -Path $Path
if (Test-Path -Path $Path)
{
    echo "-----------------Registry Key exists, creating DisableTaskMgr Value"
    Set-ItemProperty -Path $Path -Name DisableTaskMgr -Type DWord -Value 00000001
}
elseif (Test-Path -Path "HKU:\defaulthive")
{
	echo "-----------------HKU defaulthive accessed"
	echo "-----------------Testing Software directory existence"
	$NewPath = "HKU:\defaulthive\Software"
	Test-Path -Path $NewPath
	if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name Software
	}
	$Path = $NewPath 
	echo "-----------------Testing Microsoft directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft"
	Test-Path -Path $NewPath
	if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name Microsoft
	}
	$Path = $NewPath    
	echo "-----------------Testing Windows directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft\Windows"
	Test-Path -Path $NewPath
	if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name Windows
	}
	$Path = $NewPath
	echo "-----------------Testing CurrentVersion directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft\Windows\CurrentVersion"
	Test-Path -Path $NewPath
		if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name CurrentVersion
	}
	$Path = $NewPath
	echo "-----------------Testing Policies directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft\Windows\CurrentVersion\Policies"
	Test-Path -Path $NewPath
		if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name Policies
	}
	$Path = $NewPath
	echo "-----------------Testing System directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft\Windows\CurrentVersion\Policies\System"
	Test-Path -Path $NewPath
	if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name System
	}
	$Path = $NewPath
	if (Test-Path -Path $Path)
	{
		echo "-----------------Registry Key(s) created, creating DisableTaskMgr Value"
		New-ItemProperty -Path $Path -Name DisableTaskMgr -PropertyType DWord -Value 00000001
	}
	else
	{
		echo "-----------------Could not create registry key(s), exiting with errors"
	}
}

echo "-----------------Testing if the default users registry hive is populated up to and including the Winlogon key"
$Path = "HKU:\defaulthive\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Test-Path -Path $Path
if (Test-Path -Path $Path)
{
    echo "-----------------Registry Key exists, creating shell Value"
	#Set-ItemProperty -Path $Path -Name Shell -Type String -Value C:\Windows\system32\SystemPropertiesComputerName.exe
    Set-ItemProperty -Path $Path -Name Shell -Type String -Value "C:\Windows\hh.exe"
}
elseif (Test-Path -Path "HKU:\defaulthive")
{
	echo "-----------------HKU defaulthive accessed"
	echo "-----------------Testing Software directory existence"
	$NewPath = "HKU:\defaulthive\Software"
	Test-Path -Path $NewPath
	if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name Software
	}
	$Path = $NewPath 
	echo "-----------------Testing Microsoft directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft"
	Test-Path -Path $NewPath
	if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name Microsoft
	}
	$Path = $NewPath    
	echo "-----------------Testing Windows NT directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft\Windows NT"
	Test-Path -Path $NewPath
	if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name "Windows NT"
	}
	$Path = $NewPath
	echo "-----------------Testing CurrentVersion directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft\Windows NT\CurrentVersion"
	Test-Path -Path $NewPath
		if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name CurrentVersion
	}
	$Path = $NewPath
	echo "-----------------Testing Winlogon directory existence"
	$NewPath = "HKU:\defaulthive\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
	Test-Path -Path $NewPath
		if (-Not (Test-Path -Path $NewPath))
	{
		New-Item -Path $Path -Name Winlogon
	}
	$Path = $NewPath
	if (Test-Path -Path $Path)
	{
		echo "-----------------Registry Key(s) created, creating shell Value"
		#New-ItemProperty -Path $Path -Name Shell -PropertyType String -Value C:\Windows\system32\SystemPropertiesComputerName.exe
        New-ItemProperty -Path $Path -Name Shell -PropertyType String -Value "C:\Windows\hh.exe"
	}
	else
	{
		echo "-----------------Could not create registry key(s), exiting with errors"
	}
}

#Releasing references to default registry hive and unloading it so that it can be used to create the Administrator user
$SID = ""
$Path = ""
$NewPath = ""
Pop-Location
Remove-PSDrive HKU #Removes the drive mapping to HKEY_USERS
[gc]::collect()
reg unload hku\defaulthive #Attempts to unload the defaulthive User hive

reg load hku\Admin "C:\Users\Administrator\ntuser.dat"
#Loads the default users registry Hive
New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
#Maps a drive to HKEY_USERS
#New-ItemProperty -Path "HKU:\Admin\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell -PropertyType String -Value C:\Windows\system32\SystemPropertiesComputerName.exe
# Remove the shell.
New-ItemProperty -Path "HKU:\Admin\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell -PropertyType String -Value "C:\Windows\hh.exe"
New-ItemProperty -Path "HKU:\Admin\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name  DisableTaskMgr -PropertyType DWord -Value 00000001
New-ItemProperty -Path "HKU:\Admin\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell -PropertyType String -Value "C:\Windows\hh.exe"
New-ItemProperty -Path "HKU:\Admin\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name  DisableTaskMgr -PropertyType DWord -Value 00000001
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell -PropertyType String -Value "C:\Windows\hh.exe"
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name  DisableTaskMgr -PropertyType DWord -Value 00000001
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name Shell -PropertyType String -Value "C:\Windows\hh.exe"
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name  DisableTaskMgr -PropertyType DWord -Value 00000001
#Creates a new value in the new key
Remove-PSDrive HKU #Removes the drive mapping to HKEY_USERS
reg unload hku\Admin #Attempts to unload the Default User hive

# do some stuff
Stop-Transcript