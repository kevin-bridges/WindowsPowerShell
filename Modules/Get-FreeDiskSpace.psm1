<#
# AUTHOR  : Victor Ashiedu
# WEBSITE : iTechguides.com
# BLOG    : iTechguides.com/blog
# CREATED : 08-08-2014
# UPDATED : 05-05-2015
# COMMENT: Get-FreeDiskSpace is an Advanced PowerShell function that reports free disk space
    	   for servers. To Get a detailed description, import module and run Get-Help Get-FreeDiskSpace 
Change Log

05/05/2015:
1. Changed the parameter RunAsCred to Credential and made it an optional parameter
2. Changed the parameter ServerName to an optional parameter for the ServerName parameter set. It is still a required parameter for the Serverfile parameter set name. 
3. Included the functionality that allows the function to run on the local computer without any parameter 
#>

Function Get-FreeDiskSpace 
{

<#

.SYNOPSIS
	Get-FreeDiskSpace is an Advanced PowerShell function that reports free disk space
    for servers.  

.DESCRIPTION
	Get-FreeDiskSpace Advanced PowerShell function may report on a single server
	if the -Servername parameter is specified; It may report on servers from a text file if the
	-Serverfile parameter is specified. Report for a single server is displayed on the console;
	report for servers from a text file is stored on a CSV file located in \CSVReports folder.
	
	Get-FreeDiskSpace function comes with error logging. Any server that is offline or with wrong name
	will be logged in the \logs folder. All other errors are displayed on the console. 
   
.PARAMETER Servername
    Specifies a single server to report free disk space on.
	
.PARAMETER Serverfile
	Specifies a text file containing the list of servers to report on.
	
.PARAMETER Credential
	Specifies the credential to run as: account MUST have admin privileges on all
    servers in the list. This parameter is not required if you are running the function on the local computer

.PARAMETER  PerCentageFree
	Specifies the % free space to report on. If this parameter is not specified, Get-FreeDiskSpace reports 
	on drives with less than or equal to 10% free space. 20 will return servers with %Free space less than
    or equal to 20%. When reporting on a single server, if console is blank, it may be one of two things:
	1. Server name is wrong or server is offline: Check the \logs folder for more info
	2. Free space on the specified server is greater than PerCentageFree specified: Specify a higher value

.EXAMPLE
    To run disk report for the local computer and report all all disk spaces, enter the following commands:
	Get-FreeDiskSpace

.EXAMPLE
    To run disk report for a single server with the default PerCentageFree parameter (10%), enter the following commands:
	Get-FreeDiskSpace -ServerName 70411SRV1 -RunAsCred 70411Lab\administrator
	
	Server Name Drive Letter Total Capacity (GB) Free Space (GB) Free Space (%)
	----------- ------------ ------------------- --------------- --------------
	70411SRV1    M:           12.0                0.9             8 %

Report Completed, thank you for using Get-FreeDiskSpace by iTechguides.com; If console report is blank, check error logs
 at \logs or specify a higher PerCentageFree value
PS C:\Users\VictorA>

.EXAMPLE
    To run disk report for a single server with a higher PerCentageFree (reports free space for all drives less than or equal to 30% free space) parameter, enter the following commands: 
	Get-FreeDiskSpace -ServerName CITRIX10 -RunAsCred intranet\victorad2 -PerCentageFree 30
	
	PS C:\Users\VictorA> Get-FreeDiskSpace -ServerName CITRIX10 -RunAsCred intranet\victorad2 -PerCentageFree 30

	Server Name Drive Letter Total Capacity (GB) Free Space (GB) Free Space (%)
	----------- ------------ ------------------- --------------- --------------
	70411SRV1    M:           12.0                0.9             8 %
	70411SRV1    N:           15.6                3.9             25 %
	70411SRV1    O:           6.2                 0.7             11 %


Report Completed, thank you for using Get-FreeDiskSpace by iTechguides.com; If console report is blank, check error logs
 at \logs or specify a higher PerCentageFree value
PS C:\Users\VictorA>

.EXAMPLE
    To run a report from a text file as input and return free space on all drives, enter the commands below:
	Get-FreeDiskSpace -Serverfile 'E:\Imput\Servers.txt' -RunAsCred 70411lab\administrator  -PerCentageFree 100

	PS C:\Users\Administrator.70411SRV> Get-FreeDiskSpace -Serverfile 'E:\Imput\Servers.txt' -RunAsCred 70411lab\administrat
	or -PerCentageFree 100
	Report Completed, thank you for using Get-FreeDiskSpace by iTechguides.com; check error logs at \logs; CSV report is loc
	ated in \CSVReports folder
	PS C:\Users\Administrator.70411SRV>
	
	As indicated in the console, a CSV report has been created in the location:
	C:\Program Files\WindowsPowerShell\Modules\Get-FreeDiskSpace\CSVReports:
	
	Server Name	Drive Letter	Total Capacity (GB)	Free Space (GB)	Free Space (%)
	70411SRV1	C:				40					29.9			75%
	70411SRV1	E:				50					43.7			87%
	

.EXAMPLE
    If you enter a folder path instead of a text file path, the following errors will be returned:
	
	PS C:\Users\Administrator.70411SRV> Get-FreeDiskSpace -Serverfile 'E:\Imput\' -RunAsCred 70411lab\administrator -PerCent
	ageFree 100
	The specified file is not a valid text file, please specify a valid file and try again
	PS C:\Users\Administrator.70411SRV>

	See The document guide for further examples.	
	
#>

[CmdletBinding(DefaultParameterSetName='server')]
PARAM
(
        [Parameter(Mandatory=$false,Position=0,ParameterSetName='server')]
        [String[]]$ServerName,
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='file')]
        [String]$Serverfile,
		[Parameter(Mandatory=$true,Position=1,ParameterSetName='file')]
        [Parameter(Mandatory=$false,Position=1,ParameterSetName='server')]
		[String]$Credential,
        [Parameter(Mandatory=$false,Position=2,ParameterSetName='server')]
        [Parameter(Mandatory=$false,Position=2,ParameterSetName='file')]
		[String]$PerCentageFree=100	
)

BEGIN 
{

		#Define variables
		#Determine current module location
		$Scriptpath = (Split-Path $script:MyInvocation.MyCommand.Path) + "\"
		#Define logfile location
		$logpath = $Scriptpath + "\logs"
		Try {$logpathexists = Test-Path $logpath}
		Catch {}
		If ($logpathexists -eq $false)
		{New-Item -ItemType Directory -Path $logpath | Out-Null} #Out-Null suppreses console info
		$Logfiletime = Get-Date -Format ddmmyyyy
		$logfile = $logpath + "\logfile_$Logfiletime.txt"
		#Define CSVReport location
		$CSVReportPath = $Scriptpath + "\CSVReports"
		Try {$CSVReportPathexists = Test-Path $CSVReportPath}
		Catch {}
		If ($CSVReportPathexists -eq $false)
		{New-Item -ItemType Directory -Path $CSVReportPath | Out-Null} #Out-Null suppreses console info
		$CSVReportDate = Get-Date -Format sshhmmyyyy
        $CSVReportfile = $CSVReportPath + "\ServerDiskReport_$CSVReportDate.csv" #Use this variable in Export-CSV
		#Define variable for Get-WMIObject cred
		$Cred = If ($Credential) {Get-Credential -Credential $Credential}
		#Define variable to conver $PerCentageFree to %
        $PercFree = 0.01 * "$PerCentageFree"
		#Determine location to get server list to report on
		$querylist = # ($ServerFile) -or ($Servername)
		If ($ServerFile) 
		{#Check that the specified is a valid text file
			Try {$FileContent = Get-Content $ServerFile -ErrorAction SilentlyContinue}
			Catch {}
			If ($FileContent)
			{$FileContent}
			Else #If the path is not valid or the specified path is not a text file, return the error below and exit
			{Write-Host "The specified file is not a valid text file, please specify a valid file and try again" -ForegroundColor Red
			Break 
			}
		} 
		ElseIf ($Servername) 
		{$Servername}
		Else
		{$env:COMPUTERNAME}
		
}

PROCESS 

{
	#Run the GetFreeDiskSpace function
	$DiskReport =
	ForEach ($Server in $querylist)
         {#Check if the server is online
		 Write-Host "Generating disk report for $Server " -ForegroundColor Cyan
		 If ($Server -eq $env:COMPUTERNAME) {
		 	
		Get-WmiObject win32_logicaldisk -Filter "Drivetype=3" -ErrorAction SilentlyContinue |
		#Report servers with free disk space less than or equal to $PercFree
		Where-Object { ($_.freespace/$_.size) -le $PercFree} | 
		Select-Object @{Label = "Server Name";Expression = {$_.SystemName}},
		@{Label = "Drive Letter";Expression = {$_.DeviceID}},
		@{Label = "Total Capacity (GB)";Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
		@{Label = "Free Space (GB)";Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) }},
		@{Label = 'Free Space (%)'; Expression = {"{0:P0}" -f ($_.freespace/$_.size)}}
		 }
		 
		 Else {
		  Try {$pingresult = Test-Connection -ComputerName $Server -BufferSize 16 -Count 1 -Quiet}
		 	Catch {}
		 	If ($pingresult -eq 'TRUE')
		 	{   Get-WmiObject win32_logicaldisk -credential $Cred `
		 	-ComputerName $Server -Filter "Drivetype=3" -ErrorAction SilentlyContinue |
			#Report servers with free disk space less than or equal to $PercFree
			Where-Object { ($_.freespace/$_.size) -le $PercFree} | 
			Select-Object @{Label = "Server Name";Expression = {$_.SystemName}},
			@{Label = "Drive Letter";Expression = {$_.DeviceID}},
			@{Label = "Total Capacity (GB)";Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
			@{Label = "Free Space (GB)";Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) }},
			@{Label = 'Free Space (%)'; Expression = {"{0:P0}" -f ($_.freespace/$_.size)}}
			
			} 
			
		 	Else 
			{	#If server is offline, log error in logfile 
			$Server + " is offline or does not exist" | Out-File -FilePath $logfile -Append
			}
		
		}
		 }		
	
		If ($DiskReport) {
			If ($Servername) {$DiskReport | Format-Table -AutoSize} #displays reposrt on console
			ElseIf ($ServerFile) #Add text file check here for error handling
			{$DiskReport | Export-Csv -Path $CSVReportfile -NoTypeInformation}
			Else {
			$DiskReport | Format-Table -AutoSize
			}
	Write-Host "Disk report completed successfully. If you specified a text file, get report from \CSVReports folder " -ForegroundColor Yellow
		}
	Else
	{
	Write-Host "No disk appears to have a free space less than or equal to $PerCentageFree%. Please specify a higher disk space %. To report all free spaces, do not use the -PerCentageFree parameter " -ForegroundColor Red
	
	
	}
}
END {}

}
