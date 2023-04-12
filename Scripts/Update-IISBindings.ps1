<#
.SYNOPSIS
Updates the binding information for a website in IIS on one or more remote servers.

.DESCRIPTION
This script updates the binding information for a website in IIS on one or more remote servers. The script accepts the following parameters:
- SiteName: The name of the website to update.
- IPAddress: The new IP address to use for the binding.
- Port: The new port to use for the binding.
- ComputerName: An optional list of remote server names to update. If not specified, the script will run locally.

.PARAMETER SiteName
The name of the website to update.

.PARAMETER IPAddress
The new IP address to use for the binding.

.PARAMETER Port
The new port to use for the binding.

.PARAMETER ComputerName
An optional list of remote server names to update. If not specified, the script will run locally.

.EXAMPLE
Update-IISBinding -SiteName "MySite" -IPAddress "10.0.0.1" -Port "80" -ComputerName "Server01", "Server02"

This example updates the binding information for the website named "MySite" to use the IP address "10.0.0.1" and port "80" on the servers "Server01" and "Server02".

.NOTES
This script requires the WebAdministration module to be installed on the server(s) being updated.

#>

param(
    [string]$SiteName,
    [string]$IPAddress,
    [string]$Port,
    [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
    [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
)

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
