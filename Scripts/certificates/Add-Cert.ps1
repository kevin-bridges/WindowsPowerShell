<#
.SYNOPSIS
  Remotely Deploy Certificates to our servers
.DESCRIPTION
  Remotely Deploy Certificates to our servers
  Does not deploy Pfx Certs (Use Add-PfxCert.ps1 instead)

  Params:
    -certfile
        Description:    Certificate to be installed. Use either a full or relative path to the file.
        Tpes:           *.cer, *.crt, *.pem
    -storetype
        Description:    Where in the cert store you want the cert
        Types:          "Personal", "Trusted Root", "Intermediate"
    -serverlist
        Description:    Text file which contains the list of servers to deploy to.
                        If ommitted, script will run locally.
        Types:          *.txt
    -Computername
        Description     Server or Servers to install certificates to
    -Localhost
        Description     Flag used to run the script locally.
                        You can also use Import-Certificate instead of this script
.NOTES
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  
 Purpose/Change:   
 Dependencies  :  Must run PowerShell as Administrator
.EXAMPLE
PS:> .\Add-Cert.ps1 -certfile ".\cert.cer" -storetype "Personal" -Serverlist ".\servers.txt"
Store cert remotely to Personal store using a server list text file
.EXAMPLE 
PS:> .\Add-Cert.ps1 -certfile ".\cert.crt" -storetype "Intermediate" -Localhost
Store cert locally to Intermediate store. (You can also use Import-Certificate for this)
.EXAMPLE
PS:> .\Add-Cert.ps1 -certfile ".\cert.pem" -storetype "Trusted Root" -Computername "web1"
Store cert remotely to Trusted Root store using a server list text file
.EXAMPLE
PS:> .\Add-Cert.ps1 -certfile ".\cert.cer" -storetype "Personal" -Computername "web1", "web2"
Store cert remotely to Trusted Root store using a server list text file
#>
[CmdletBinding(DefaultParameterSetName="Hostname")]
param(
    [Parameter(Mandatory=$true)] [string] $certfile,
    [Parameter(Mandatory=$true)][ValidateSet("Personal", "Trusted Root", "Intermediate")] [string] $storetype,
    [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
    [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
    [Parameter(Mandatory=$true,ParameterSetName='Localhost')] [switch] $Localhost
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

if ($Serverlist -ne ""){
    #Get-Content -Path $Serverlist
    $Computername = Get-Content -Path $Serverlist
}

# Map friendly names to actual cert store objects
if ($storetype -eq 'Personal'){
    $st = 'cert:\LocalMachine\My'
} elseif ($storetype -eq 'Trusted Root'){
    $st = 'Cert:\LocalMachine\Root'
} elseif ($storetype -eq 'Intermediate'){
    $st = 'cert:\LocalMachine\ca'
}

# Separate filename from filepath
$certfilename = Split-Path $certfile -leaf

# Is user using a serverlist or do they want to run the script locally
if ($Localhost -eq $true){
    #add cert to store
    Import-Certificate -FilePath $certfile -CertStoreLocation $st
    exit
} 
    
 
foreach (${item} in ${Computername}) {
    $myCertDir = 'C:\Temp\mycert'
    $certDest = "$myCertDir\\$certfilename"
    $PSSession = New-PSSession -ComputerName $item

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
    Copy-Item -Recurse $certfile -Destination $certDest -ToSession $PSSession
        
    # Import the cert
    $importCert = Invoke-Command -ScriptBlock {
        #add cert to store
        Import-Certificate -FilePath $Using:certDest -CertStoreLocation $Using:st;
    } -Session $PSSession

    # Remove cert from C:\Temp
    Invoke-Command -ScriptBlock {
        #remove cert from temp
        if (Test-Path $Using:myCertDir) {Remove-Item -Recurse -Force $Using:myCertDir};
    } -Session $PSSession

    # Display result
    $importCert

    $PSSession | Remove-PSSession
}






