<#
.SYNOPSIS
  Measure Average CPU utilization remotely
.DESCRIPTION
  Measure Average CPU utilization remotely by either locally, by computername, or by serverlist. 
  Can specify SampleInterval (default:3) and MaxSamples (default:5)
.NOTES
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  3 AUG 2023
 Purpose/Change: 
 Dependencies  : 
.EXAMPLE 
PS:> .\measure-CpuRemotely.ps1 -Localhost
Run Locally
.EXAMPLE 
PS:> .\measure-CpuRemotely.ps1 -Computername "web1","web2"
Run by computername(s)
.EXAMPLE 
PS:> .\measure-CpuRemotely.ps1 -Computername "web1","web2" -SampleInterval 4 -MaxSamples 4
Run by computername(s) and specify SampleInterval and MaxSamples values
.EXAMPLE 
PS:> .\measure-CpuRemotely.ps1 -Computername "web1","web2" -AlterateCreds
Run by computername(s) as different user
.EXAMPLE 
PS:> .\measure-CpuRemotely.ps1 -Serverlist ".\serverlist.txt"
Run with serverlist
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
    [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
    [Parameter(Mandatory=$true,ParameterSetName='Localhost')] [switch] $Localhost,
    [Parameter(Mandatory=$false)] [int] $SampleInterval = 3,
    [Parameter(Mandatory=$false)] [int] $MaxSamples = 5,
    [Parameter(Mandatory=$false)] [Switch] $AlterateCreds=$false
)

#check to see if user is running script as administrator
Write-Progress -Activity "Checking for elevated permissions..."
Start-Sleep -Milliseconds 250
Write-Progress -Activity "Checking for elevated permissions..." -Completed
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Warning 'Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again.'
Break
} else {
Write-Progress -Activity "Script is running as administrator. Script can continue..."
Start-Sleep -Milliseconds 250
Write-Progress -Activity "Script is running as administrator. Script can continue..." -Completed
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

if ($Serverlist -ne ""){
    #Get-Content -Path $Serverlist
    $Computername = Get-Content -Path $Serverlist
}

# Is user using a serverlist or do they want to run the script locally
if ($Localhost -eq $true){
    $MeasurementsArray = @()
    #add cert to store
    $CPUPerformance = (GET-COUNTER -Counter "\Processor(_Total)\% Processor Time" -SampleInterval $SampleInterval -MaxSamples $MaxSamples |Select-Object -ExpandProperty countersamples | Select-Object -ExpandProperty cookedvalue )
    $CPUAveragePerformance = ($CPUPerformance | Measure-Object -Average).average
    $MaxCPU = ($CPUPerformance | Measure-Object -Maximum).Maximum
    
    $Row = "" | Select-Object Computer, AverageCPU, MaxCPU
    $Row.Computer = $env:COMPUTERNAME
    $Row.AverageCPU = [math]::Round($CPUAveragePerformance,2)
    $Row.MaxCPU = [math]::Round($MaxCPU,2)
    $MeasurementsArray += $Row
    $MeasurementsArray
    # $measurement = Get-CimInstance win32_processor | Measure-Object -Property LoadPercentage -Average
    # $measurement

    exit
} 

$TopMeasurementsArray = @()


foreach (${item} in ${Computername}) {
    
    if($AlterateCreds -eq $true){
        if (Test-Connection -ComputerName $item -Quiet) {
            $PSSession = New-PSSession -ComputerName $item -Credential $mypwd -ErrorAction SilentlyContinue

            if ($PSSession -is [System.Management.Automation.Runspaces.PSSession])
                {
                    Write-Progress -Activity "Scanning $item CPU"
                } else {
                    Write-Warning "Unable to connect to $item"
                    continue
                }
        } else {
            Write-Warning "Unable to connect to $item"
            continue
        }
	} else {
        if (Test-Connection -ComputerName $item -Quiet) {
            $PSSession = New-PSSession -ComputerName $item  -ErrorAction SilentlyContinue

            if ($PSSession -is [System.Management.Automation.Runspaces.PSSession])
                {
                    Write-Progress -Activity "Scanning $item CPU"
                } else {
                    Write-Warning "Unable to connect to $item"
                    continue
                }

        } else {
            Write-Warning "Unable to connect to $item"
            continue
        }
		
	} 
    
    # Measure CPU
    $measurement =  Invoke-Command -ScriptBlock {
        #Measure CPU
        #Get-CimInstance win32_processor | Measure-Object -Property LoadPercentage -Average;
        $MeasurementsArray = @()
        $CPUPerformance = (GET-COUNTER -Counter "\Processor(_Total)\% Processor Time" -SampleInterval $SampleInterval -MaxSamples $MaxSamples |Select-Object -ExpandProperty countersamples | Select-Object -ExpandProperty cookedvalue )
        $CPUAveragePerformance = ($CPUPerformance | Measure-Object -Average).average
        $MaxCPU = ($CPUPerformance | Measure-Object -Maximum).Maximum
        $Row = "" | Select-Object AverageCPU, MaxCPU
        $Row.AverageCPU = [math]::Round($CPUAveragePerformance,2)
        $Row.MaxCPU = [math]::Round($MaxCPU,2)
        $MeasurementsArray += $Row
        $MeasurementsArray
    } -Session $PSSession

    Write-Progress -Activity "Scanning $item CPU" -Completed
    
    $TopMeasurementsArray += $measurement

    $PSSession | Remove-PSSession
}

$TopMeasurementsArray | Format-Table -Property PSComputerName, MaxCPU, AverageCPU