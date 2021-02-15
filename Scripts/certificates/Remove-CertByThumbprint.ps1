<#
.SYNOPSIS
 Remove expired certificates on machines by thumbprint.
.DESCRIPTION
 Remove expired certificates on machines (remote or local) by thumbprint.
 
 Params:
    -Thumbprint
        Description:    Thumbprint of cert you are searching for
    -Storetype
        Description:    Where in the cert store you want the cert
        Types:          "Personal", "Trusted Root", "Intermediate"
    -Computername
        Description     One or more (comma separated) computernames to search
    -Serverlist
        Description:    Text file which contains the list of servers to deploy to.
        Types:          *.txt
    -Localhost
        Description     Flag used if you want to run the command locally

.NOTES
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  15 February 2021
 Purpose/Change:  
 Dependencies  :  
.EXAMPLE 
PS:> .\Remove-CertByThumbprint.ps1 -Storetype "Personal" -Thumbprint "BA6FC1BC6544F6B656A74FD2244001CA35441425" -Serverlist ".\servers.txt"
Find certificate by thumbprint from personal store using a serverlist.
.EXAMPLE 
PS:> .\Remove-CertByThumbprint.ps1 -Storetype "Intermediate" -Thumbprint "BA6FC1BC6544F6B656A74FD2244001CA35441425" -Computername "web1"
Find certificate by thumbprint from intermediate store using a computername.
.EXAMPLE 
PS:> .\Remove-CertByThumbprint.ps1 -Storetype "Trusted Root" -Thumbprint "BA6FC1BC6544F6B656A74FD2244001CA35441425" -Localhost
Find certificate by thumbprint from trusted root store on localhost.
.EXAMPLE 
PS:> .\Remove-CertByThumbprint.ps1 -Storetype "Personal" -Thumbprint "BA6FC1BC6544F6B656A74FD2244001CA35441425" -Computername "web1", "Web2"
Find certificate by thumbprint from personal store using 2 computernames.
#>
[CmdletBinding(DefaultParameterSetName="Hostname")]
param(
  [Parameter(Mandatory=$true)][ValidateSet("Personal", "Trusted Root", "Intermediate")] [string] $Storetype,
  [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
  [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
  [Parameter(Mandatory=$true,ParameterSetName='Localhost')] [switch] $Localhost,
  [Parameter(Mandatory=$true)] [string] $Thumbprint
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

# Map friendly names to actual cert store objects
if ($storetype -eq 'Personal'){
    $st = 'cert:\LocalMachine\My'
} elseif ($storetype -eq 'Trusted Root'){
    $st = 'Cert:\LocalMachine\Root'
} elseif ($storetype -eq 'Intermediate'){
    $st = 'cert:\LocalMachine\ca'
}

# If localhost flag is provided, run the script locally
if ($Localhost -eq $true){
    $CertObj = Get-ChildItem -Path $st
    $FilteredCertObj = $CertObj | Where-Object {$_.Thumbprint -eq $Thumbprint}
    if ($FilteredCertObj.Thumbprint -eq $Thumbprint){
        Get-ChildItem "$st\$Thumbprint" | Remove-Item
        Write-Host "Thumbprint ($Thumbprint) removed from $env:COMPUTERNAME"  -ForegroundColor "green"
    } else {
        Write-Host "Thumbprint ($Thumbprint) is not on $env:COMPUTERNAME" -ForegroundColor "red"
    }
    exit
}

if ($Serverlist -ne ""){
    #Get-Content -Path $Serverlist
    $Computername = Get-Content -Path $Serverlist
}

foreach (${item} in ${Computername}) {
    $PSSession = New-PSSession -ComputerName $item
    $CertObj = Invoke-Command -ScriptBlock {Get-ChildItem -Path $Using:st } -Session $PSSession
    $FilteredCertObj = $CertObj | Where-Object {$_.Thumbprint -eq $Thumbprint}
    $ifString = $FilteredCertObj.Thumbprint
    if ($null -ne $ifString){
        Invoke-Command {Get-ChildItem $Using:st"\"$Using:Thumbprint | Remove-Item } -Session $PSSession
        Write-Host "Thumbprint ($Thumbprint) removed from $item" -ForegroundColor "green"
    } else {
        Write-Host "Thumbprint ($Thumbprint) is not on $item" -ForegroundColor "red"
    }
    $PSSession | Remove-PSSession
}
