param(
    [string]$SiteName,
    [string]$IPAddress,
    [string]$Port,
    [string[]]$ComputerName
)

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
