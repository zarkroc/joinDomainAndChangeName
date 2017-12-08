# Function to join domain as 
function JoinDomain([string]$user, [string]$password) {
    $domain = (Get-WmiObject Win32_NetworkAdapterConfiguration -filter "IPEnabled=True and DNSDomain!=null").DNSDomain
    $username ="$domain\$user"
    $securePassword = ConvertTo-SecureString $password  -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username,$securePassword)
    Add-Computer -DomainName $domain -Credential $credential 
    if ((gwmi win32_computersystem).partofdomain -eq $True) {
        write-host -fore green "Gick med i en domän!"
        return $True
    } 
    else 
    {
        Write-Host -ForegroundColor red "Har inte gått med i domänen"
        return $False
    }
}


function JoinDomainWithAnslut {
    $domain = (Get-WmiObject Win32_NetworkAdapterConfiguration -filter "IPEnabled=True and DNSDomain!=null").DNSDomain
    $user = "username"
    $username ="$domain\$user"
    # try to prompt for password.
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    $title = 'Lösenord'
    $msg   = 'Skriv in lösenordet till anslut:'
    $password = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
    $securePassword = ConvertTo-SecureString $password  -AsPlainText -Force
    # end prompt for password
    $credential = New-Object System.Management.Automation.PSCredential($username,$securePassword)
    # Join the computer to doman.
    Add-Computer -DomainName $domain -Credential $credential
    if ((gwmi win32_computersystem).partofdomain -eq $True) {
        write-host -fore green "Gick med i en domän!"
        return $True
    } 
    else 
    {
        [System.Windows.Forms.MessageBox]::Show("Kunde inte gå med i domänen som anslut. Skrev du rätt lösenord till anslut?") 
        return $False
    }
}



function Finalize {
    ipconfig /renew >> "C:\Setup\ipconfig_post_join.txt"
    schtasks /delete /TN joinDomain /F
    # Do we need to run this every time just to make sure?
    net time /SET /Y
    gpupdate /force  
    schtasks /create /tn TimeSync /sc onstart /rl highest /ru system /tr "net time \\srv1 /SET /Y"
    schtasks /create /tn gpoSync /sc onstart /rl highest /delay 0000:10 /ru system /tr "gpupdate /force" 
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 
    Set-ItemProperty $RegPath "AutoAdminLogon" -Value "0" -type String 
    }



function SetFixedIp {
    $nic = (Get-WmiObject Win32_NetworkAdapterConfiguration -filter "IPEnabled=True and DNSDomain!=null")
    $dynamicip = ((Get-WmiObject Win32_NetworkAdapterConfiguration -filter "IPEnabled=True and DNSDomain!=null").IPAddress)[0]
    $dynamicipobj = [System.Net.IPAddress]::parse($dynamicip)
    # Read last octet of IP from file.
    $customIP = Get-Content C:\Setup\lastPartOfIP.ini
    # Default DNS server used in TKT
    $customDNSServer = ".76"
    # Default GW used in TKT
    $customGW = ".1"
    # Get the last part of the FSRV ip address.
    # This will set the IP address....
    if([System.Net.IPAddress]::tryparse([string]$dynamicip, [ref]$dynamicipobj))
    {
	    $dynamiciparray = $dynamicip -split "\."
	    #T2 I2 Server uses 192.168.x.71
	    $newip = $dynamiciparray[0] + "." + $dynamiciparray[1] + "." + $dynamiciparray[2] +"." + $customIP
	    #T2 Gateway is at 192.168.x.1
	    $newgw = $dynamiciparray[0] + "." + $dynamiciparray[1] + "." + $dynamiciparray[2] + $customGW
	    #T2 DNS is at 192.168.x.76
	    $newdns = $dynamiciparray[0] + "." + $dynamiciparray[1] + "." + $dynamiciparray[2] + $customDNSServer
	    $newipobj = [System.Net.IPAddress]::parse($newip)
	    $newgwobj = [System.Net.IPAddress]::parse($newgw)
	    $newdnsobj = [System.Net.IPAddress]::parse($newdns)
	    if(([System.Net.IPAddress]::tryparse([string]$newip, [ref]$newipobj)) -and ([System.Net.IPAddress]::tryparse([string]$newgw, [ref]$newgwobj)) -and ([System.Net.IPAddress]::tryparse([string]$newdns, [ref]$newdnsobj)))
	    {
    		"NewIP: " + $newip
		    "NewGW: " + $newgw
		    "NewDNS: " + $newdns
		    netsh interface ip set address "Local Area Connection" static $newip "255.255.255.0" $newgw
		    netsh interface ip set dns "Local Area Connection" static $newdns
	    }
    }
}

ipconfig /renew >> "C:\Setup\ipconfig_pre_join.txt"

$user = "username1"
$password = "password1"
# Call function with username and password.
if (JoinDomain $user $password ) {
}
else {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    [System.Windows.Forms.MessageBox]::Show("Kunde inte gå med i en domän som grundkonf. Skriv in lösenordet för anslut") 
    while ((gwmi win32_computersystem).partofdomain -eq $False)
    {
    JoinDomainWithAnslut
    }
}


if ((gwmi win32_computersystem).partofdomain -eq $True) {
    $fsrvName = Get-Content C:\Setup\fsrvType.ini
    if ($fsrvName -ne "Klient") {
        SetFixedIP
    }
    Finalize
} 
else {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    [System.Windows.Forms.MessageBox]::Show("Någonting har gått fel. Installera om allt.") 
}