<#
.SYNOPSIS
	Updates IIS bindings on multiple servers.
.DESCRIPTION
	This script updates the IIS bindings on multiple servers.
.PARAMETER SiteName
	The name of the IIS site to update.
.PARAMETER Protocol
	The protocol to use for the IIS site (HTTP or HTTPS).
.PARAMETER Port
	The port to use for the IIS site.
.PARAMETER IPAddress
	The IP address to use for the IIS site.
.PARAMETER ComputerName
	A string specifying the name of a single server to update. If this parameter is provided, the script will update IIS bindings on the specified server.
.PARAMETER ServerList
	The path to a text file containing a list of servers to update. If this parameter is provided, the script will read the list of servers from the specified file and update IIS bindings on each server.
.NOTES
	Author: Kevin Bridges
	Last Updated: 12 APR 2023
	Version: 1.0
.EXAMPLE
	Update-IISBindings -SiteName "MySite" -Protocol "HTTPS" -Port "443" -IPAddress "10.0.0.1" -ComputerName "Server01"
	Updates the IIS bindings for the "MySite" site with HTTPS protocol and IP address 10.0.0.1 and port 443 on the server "Server01".
.EXAMPLE
	Update-IISBindings -SiteName "MySite" -Protocol "HTTP" -Port "80" -IPAddress "10.0.0.2" -ServerList "C:\servers.txt"
	Updates the IIS bindings for the "MySite" site with HTTP protocol and IP address 10.0.0.2 and port 80 on the servers listed in the "servers.txt" file.
#> 


param(
    [string]$SiteName,
    [string]$IPAddress,
    [string]$Port,
    [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
    [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
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
    $Computername = Get-Content -Path $Serverlist
}

# Loop through the list of computer names
foreach ($Computer in $ComputerName) {
    # Create a new session to the remote computer
    $Session = New-PSSession -ComputerName $Computer

    try {
        # Use the Invoke-Command cmdlet to run the script on the remote computer
        Invoke-Command -Session $Session -ScriptBlock {
            param(
                [string]$SiteName,
                [string]$IPAddress,
                [string]$Port
            )

            Import-Module WebAdministration

            # Get the site object
            $Site = Get-WebSite -Name $SiteName

            # Get the first binding (assuming only one exists)
            $Binding = $Site.Bindings[0]

            # Update the binding information
            $Binding.BindingInformation = "$IPAddress:$Port:"

            # Save the changes to the site object
            Set-Item -Path "IIS:\Sites\$SiteName" -Value $Site
        } -ArgumentList $SiteName, $IPAddress, $Port
    }
    catch {
        Write-Error "Error: $_"
    }
    finally {
        # Close the remote session
        Remove-PSSession $Session
    }
}
