
# Create the path specefied if it doesn't exist.
function CreateDirectorySTructure( $pathToCreate)
{
    Write-Host "Verifying if $pathToCreate has been created"
	If(!(test-path $pathToCreate))
	{
	New-Item -ItemType Directory -Force -Path $pathToCreate
	}
}

function ConvertFrom-Json20([object] $item){ 
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer

    #The comma operator is the array construction operator in PowerShell
    return ,$ps_js.DeserializeObject($item)
}
# Ask the user for what type of FSRV will this be? 
# Edit the JSON file SupportedFSRV.json to add more FSRVs.

# JSON file should be stored with the script.
$jsonConfigFile = "$PSScriptRoot/SupportedFSRV.json"

if (([string]::IsNullOrEmpty($PSScriptRoot)))
{
    $path = split-path -parent $MyInvocation.MyCommand.Definition
    $jsonConfigFile = $path + "/SupportedFSRV.json"
}
# Read the JSON file and convert.

# CovertFrom-Json only exist in powershell 3.0+ :( 
if (Get-Command $ConvertFrom-Json -errorAction SilentlyContinue)
{
    $json = Get-Content $jsonConfigFile | Out-String | ConvertFrom-Json
}
else {
    $temp = Get-Content $jsonConfigFile | Out-String
    $json = ConvertFrom-Json20($temp)
}

# Read the FSRVType part of the JSON file.
$FSRVs = $json.FSRVType

# Create a forms listBox input for selecting 
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form 
$FONT = New-Object System.Drawing.Font("Courier New",10)
$form.Text = "Select an FSRV type and IP number"
$form.Font = $FONT
$form.Size = New-Object System.Drawing.Size(300,200) 
$form.StartPosition = "CenterScreen"

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20) 
$label.Size = New-Object System.Drawing.Size(280,20) 
$label.Text = [string]::Format("{0,-15} {1,15}","FSRV Type", "Last part of IP")
$form.Controls.Add($label) 

$listBox = New-Object System.Windows.Forms.ListBox 
$listBox.Location = New-Object System.Drawing.Point(10,40) 
$listBox.Size = New-Object System.Drawing.Size(260,20) 
$listBox.Height = 80
$listBox.Font = $FONT


$tempFSRVs = $FSRVs

for ($i=0;$i -le $tempFSRVs.count -1 ; $i++) {
    [void] $listBox.Items.Add([string]::Format("{0,-20} {1,10}",$($tempFSRVs[$i].Name),$($tempFSRVs[$i].IP)))
    }

$form.Controls.Add($listBox) 
$form.Topmost = $True
$result = $form.ShowDialog()
$x = $listBox.SelectedIndex
if ($x -eq -1)
{
    Write-Host " You didn't select an item"
    Exit
}

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $fsrv = $FSRVs.Item($x)
    Write-Host "You selected:" $fsrv.Name "IP:" $fsrv.IP
}
if ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
{
    Write-Host "Nothing has been done"
}
Write-Host "Chance to cancel. Press Enter if all is OK"
Read-Host 

Remove-Item C:\Setup\ -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item C:\Windows\T2\ -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item C:\Windows\Setup\Scripts\SetupComplete.cmd -Force -ErrorAction SilentlyContinue
Remove-Item C:\Windows\System32\sysprep\unattend.xml -Force -ErrorAction SilentlyContinue

$fsrvType = $fsrv.Name
$lastPartOfIP = $fsrv.IP

Write-Host "Copying files"
# Create C:\Setup folder
CreateDirectorySTructure "C:\Setup"                                                                      
# Move C-Setup to C:\Setup and write the variables to ini files that will be used after sysprep.
Move-Item C-Setup\* C:\Setup\ -force
$fsrvType | Out-File C:\Setup\fsrvType.ini
$lastPartOfIP | Out-File C:\Setup\lastPartOfIP.ini

# Server or klient, how to handle more versions?
if ($fsrv.Name -eq "Klient") {
    Move-Item -Force Win7_Ent C:\Setup\activateWindows
}
else {
    Move-Item -Force 2008R2_Std C:\Setup\activateWindows
}

CreateDirectorySTructure "C:\Windows\Setup\Scripts"
Move-Item C-Windows-Setup-Scripts\* C:\Windows\Setup\Scripts\ -force

CreateDirectorySTructure "C:\Windows\System32\Sysprep"
Move-Item  C-Windows-System32-Sysprep\* C:\Windows\System32\Sysprep\ -force

CreateDirectorySTructure "C:\Windows\T2"
Move-Item C-Windows-T2\* C:\Windows\T2\ -force
 
# Make sure we can remove files when done and execute scripts :)
Write-Host -ForegroundColor Green "There will be two error messages here because we don't know if it is Everyone or Alla"
$Path = 'C:\Setup'
$Acl = Get-Acl $Path
#$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrator", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Alla", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow") -erroraction 'silentlycontinue'
$Acl.AddAccessRule($Ar)
Set-Acl "$Path\*" $Acl -erroraction 'silentlycontinue'
Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue | Get-Acl |
ForEach-Object {  
 Set-Acl -Path $_.PSPath $_ -erroraction 'silentlycontinue'
 }
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow") -erroraction 'silentlycontinue'
$Acl.AddAccessRule($Ar)
Set-Acl "$Path*" $Acl -erroraction 'silentlycontinue'
Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue | Get-Acl |
ForEach-Object {  
 Set-Acl -Path $_.PSPath $_ -erroraction 'silentlycontinue'
 }

$Path = 'C:\Windows\T2'
$Acl = Get-Acl $Path
#$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrator", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Alla", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow") -erroraction 'silentlycontinue'
$Acl.AddAccessRule($Ar)
Set-Acl "$Path\*" $Acl -erroraction 'silentlycontinue'
Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue | Get-Acl |
ForEach-Object {  
 Set-Acl -Path $_.PSPath $_ -erroraction 'silentlycontinue'
 }
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow") -erroraction 'silentlycontinue'
$Acl.AddAccessRule($Ar)
Set-Acl "$Path*" $Acl -erroraction 'silentlycontinue'
Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue | Get-Acl |
ForEach-Object {  
 Set-Acl -Path $_.PSPath $_ -erroraction 'silentlycontinue'
 }

Write-Host -ForegroundColor Green "No expected error messages after this."

Read-Host -Prompt "Chance to interrupt"

# Temp fix for sysprep after Management Framework 5.0
Write-Host "Fix for broken sysprep with Management Framework 5.0"
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\StreamProvider" -Name LastFullPayloadTime -Value 0 -PropertyType DWord -Force -erroraction 'silentlycontinue'