<#
.SYNOPSIS
  Remotely Deploy Pfx or P12 Certificates to servers on network.
.DESCRIPTION
  Remotely Deploy Pfx or P12 Certificates to servers on network. Uses interactive password window for creds.

  Params:
    -Certfile
        Description:    Certificate to be installed. Use either a full or relative path to the file.
        Tpes:           *.pfx, *.p12
    -Storetype
        Description:    Where in the cert store you want the cert
        Types:          "Personal", "Trusted Root", "Intermediate"
    -Exportable
        Description     Specifies whether the imported private key can be exported. 
                        If this parameter is not specified, then the private key cannot be exported.
    -Serverlist
        Description:    Text file which contains the list of servers to deploy to.
                        If ommitted, script will run locally.
        Types:          *.txt
    -Computername
        Description     Server or Servers to install certificates to
    -Localhost
        Description     Flag used to run the script locally.
                        You can also use Import-PfxCertificate instead of this script
    -AlternateCreds
        Description     Supply alternate credentials when running script
.NOTES
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  
 Purpose/Change:   
 Dependencies  :  Must run PowerShell as Administrator
.EXAMPLE 
PS:> .\Add-PfxCert.ps1 -Certfile ".\cert.pfx" -Storetype "Personal" -Exportable -Serverlist ".\servers.txt" -Exportable
Store pfx cert remotely to Personal store using a server list text file as exportable
.EXAMPLE 
PS:> .\Add-PfxCert.ps1 -Certfile ".\cert.pfx" -Storetype "Intermediate" -Computername "web1"
Store pfx cert remotely to Intermediate store using the computername param (not exportable)
.EXAMPLE 
PS:> .\Add-PfxCert.ps1 -Certfile ".\cert.pfx" -Storetype "Intermediate" -Computername "web1", "web2"
Store pfx cert remotely to Intermediate store on 2 servers using the computername param (not exportable)
.EXAMPLE 
PS:> .\Add-PfxCert.ps1 -Certfile ".\cert.p12" -Storetype "Personal" -Exportable -Localhost
Store p12 cert locally to Trusted Root store as Exportable (You can also use Import-PfxCertificate for this)
.EXAMPLE 
PS:> .\Add-PfxCert.ps1 -Certfile ".\cert.p12" -Storetype "Personal" -Computername "web1" -AlternateCreds
Store p12 cert to server using alternate credentials
#>
[CmdletBinding(DefaultParameterSetName="Hostname")]
param(
    [Parameter(Mandatory=$true)] [string] $Certfile,
    [Parameter(Mandatory=$true)][ValidateSet("Personal", "Trusted Root", "Intermediate")] [string] $Storetype,
    [Parameter(Mandatory=$false)] [Switch] $Exportable=$false,
    [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
    [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
    [Parameter(Mandatory=$true,ParameterSetName='Localhost')] [switch] $Localhost,
    [Parameter(Mandatory=$false)] [Switch] $AlterateCreds=$false   
)

#check to see if user is running script as administrator
Write-Host "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Warning 'Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again.'
Break
} else {
Write-Host 'Script is running as administrator. Script can continue...' -ForegroundColor Green
}

# Get altername credentials if switch is selected
if($AlterateCreds -eq $true){
    $error.Clear()
    $mypwd = Get-Credential
    if ($error.Count -gt 0) {
        Write-Error "User canceled"
        exit
    }
}

# If serverlist file has content, populate $Computername array with contents
if ($Serverlist -ne ""){
    #Get-Content -Path $Serverlist
    $Computername = Get-Content -Path $Serverlist
}

# Get Secure Password String from user
$mypfxpwd = Get-Credential -UserName 'Enter Pfx password below' -Message 'Enter Pfx password below'
$token = $mypfxpwd.Password

# Map friendly names to actual cert store objects
if ($Storetype -eq 'Personal'){
    $st = 'cert:\LocalMachine\My'
} elseif ($Storetype -eq 'Trusted Root'){
    $st = 'Cert:\LocalMachine\Root'
} elseif ($Storetype -eq 'Intermediate'){
    $st = 'cert:\LocalMachine\ca'
}

# Separate filename from filepath
$Certfilename = Split-Path $Certfile -leaf

# Is user using a serverlist or do they want to run the script locally
if ($Localhost -eq $true){
    #add cert to store
    if($Exportable -eq $true){
        Import-PfxCertificate -FilePath $Certfile -CertStoreLocation $st -Password $token -Exportable
    } else {
        Import-PfxCertificate -FilePath $Certfile -CertStoreLocation $st -Password $token
    }
    exit
} 
    
foreach (${item} in ${Computername}) {
    $myCertDir = 'C:\Temp\mycert'
    $certDest = "$myCertDir\\$Certfilename"
    if($AlterateCreds -eq $true){
        if (Test-Connection -ComputerName $item -Quiet) {
            $PSSession = New-PSSession -ComputerName $item -Credential $mypwd 
        } else {
            Write-Host "Unable to connect to $item" -ForegroundColor 'red'
			exit
        }
	} else {
        if (Test-Connection -ComputerName $item -Quiet) {
            $PSSession = New-PSSession -ComputerName $item
        } else {
            Write-Host "Unable to connect to $item" -ForegroundColor 'red'
			exit
        }
		
	}
    
    # Make sure C:\Temp exists
    $result = Invoke-Command -ScriptBlock {
        #test to make sure temp dir exists
        If (test-path $Using:myCertDir){return $true}else{return $false};
                
    } -Session $PSSession

    # Create C:\Temp\mycert if it doesn't exist
    if ($result -eq $false){
        Invoke-Command -ScriptBlock {New-Item -Path $Using:myCertDir -ItemType DIR | Out-Null} -Session $PSSession
    }

    # Copy certificate to remote server
    Copy-Item -Recurse $Certfile -Destination $certDest -ToSession $PSSession
    
    # Import the cert
    if($Exportable -eq $true){
        $importCert = Invoke-Command -ScriptBlock {
            #add cert to store as exportable
            Import-PfxCertificate -FilePath $Using:certDest -CertStoreLocation $Using:st -Password $Using:token -Exportable;           
        } -Session $PSSession
    } else {
        #add cert to store as not exportable
        $importCert = Invoke-Command -ScriptBlock {
            Import-PfxCertificate -FilePath $Using:certDest -CertStoreLocation $Using:st -Password $Using:token;
        } -Session $PSSession
    }
    # Remove cert from C:\Temp\mycert
    Invoke-Command -ScriptBlock {
        #remove cert from temp
        if (Test-Path $Using:myCertDir) {Remove-Item -Recurse -Force $Using:myCertDir};
    } -Session $PSSession

    # Display result
    $importCert

    $PSSession | Remove-PSSession
}
