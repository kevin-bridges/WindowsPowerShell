<#
.SYNOPSIS
  Find expired certificates on remote machines by date.
.DESCRIPTION
 Find expired certificates on remote machines by date.
 
 Params:
    -Date
        Description:    If the Date param is specified, please use this format: 
                        MM/DD/YYYY (example: 2/12/2021)
                        If the Date parameter isn't specified, a date picker 
                        will be used to determine the date.
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
    -AsList
        Description:    Specify if you want the output as list format instead 
                        if table format
.NOTES
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  February 11, 2021
 Purpose/Change: 
 Dependencies  : 
.EXAMPLE 
PS:> .\Find-CertByDate.ps1 -Storetype "Personal" -Computername "web1"
Find expired certs on remote server. Since the Date param isn't 
specified, the date picker will be used.
.EXAMPLE 
PS:> .\Find-CertByDate.ps1 -Storetype "Personal" -Computername "web1,web2" -Date "12/21/2022"
Find expired certs on 2 servers. Since the Date is specified, the date picker will not be used.
.EXAMPLE 
PS:> .\Find-CertByDate.ps1 -Storetype "Personal" -Serverlist ".\servers.txt" -Date "12/21/2022"
Find expired certs on 2 servers using a server list. Since the Date is specified, the date picker will not be used.
.EXAMPLE 
PS:> .\Find-CertByDate.ps1 -Storetype "Intermediate" -Serverlist ".\servers.txt" -AsList
Find expired certs on 2 servers using a server list. Since the Date is specified, the date picker will not be used.
The output will be displayed as a list since the AsList param is used.
.EXAMPLE 
PS:> .\Find-CertByDate.ps1 -Localhost -Storetype "Personal"
Find expired certs local server. The date picker be used.
#>
[CmdletBinding(DefaultParameterSetName="Hostname")]
param(
  [Parameter(Mandatory=$true)][ValidateSet("Personal", "Trusted Root", "Intermediate")] [string] $Storetype,
  [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
  [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
  [Parameter(Mandatory=$true,ParameterSetName='Localhost')] [switch] $Localhost,
  [Parameter(Mandatory=$false)] [datetime] $Date,
  [Parameter(Mandatory=$false)] [switch] $AsList
)

# Map friendly names to actual cert store objects
if ($Storetype -eq 'Personal'){
    $st = 'cert:\LocalMachine\My'
} elseif ($Storetype -eq 'Trusted Root'){
    $st = 'Cert:\LocalMachine\Root'
} elseif ($Storetype -eq 'Intermediate'){
    $st = 'cert:\LocalMachine\ca'
}



function Get-ExpiredByDate{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object Windows.Forms.Form -Property @{
        StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
        Size          = New-Object Drawing.Size 243, 230
        Text          = 'Select an Expired-By Date'
        Topmost       = $true
    }

    $calendar = New-Object Windows.Forms.MonthCalendar -Property @{
        ShowTodayCircle   = $false
        MaxSelectionCount = 1
    }
    $form.Controls.Add($calendar)

    $okButton = New-Object Windows.Forms.Button -Property @{
        Location     = New-Object Drawing.Point 38, 165
        Size         = New-Object Drawing.Size 75, 23
        Text         = 'OK'
        DialogResult = [Windows.Forms.DialogResult]::OK
    }
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object Windows.Forms.Button -Property @{
        Location     = New-Object Drawing.Point 113, 165
        Size         = New-Object Drawing.Size 75, 23
        Text         = 'Cancel'
        DialogResult = [Windows.Forms.DialogResult]::Cancel
    }
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $result = $form.ShowDialog()

    if ($result -eq [Windows.Forms.DialogResult]::OK) {
        $expiredByDate = $calendar.SelectionStart
        Return $expiredByDate
    }

    if ($result -eq [Windows.Forms.DialogResult]::Cancel) {
        Write-Host "Cancelled Script" -ForegroundColor "Red" -BackgroundColor "Gray"
        exit
    }
}

if ([string]::IsNullOrEmpty($Date)){
    $Date = Get-ExpiredByDate
}

# If localhost flag is provided, run the script locally
if ($Localhost -eq $true){
    $CertObj = Get-ChildItem -Path $st
    $FilteredCertObj = $CertObj | Where-Object {$_.NotAfter -lt $Date}
    if ($AsList -eq $true){
        $FilteredCertObj | Format-List
    } else {
        $FilteredCertObj | Format-Table -Property Thumbprint,NotAfter,Issuer -AutoSize -Wrap
    }
    exit
}

if ($Serverlist -ne ""){
    #Get-Content -Path $Serverlist
    $Computername = Get-Content -Path $Serverlist
}

$CertArray = $()

foreach (${item} in ${Computername}) {
    $PSSession = New-PSSession -ComputerName $item
    $CertObj = Invoke-Command -ScriptBlock {Get-ChildItem -Path $Using:st } -Session $PSSession
    $FilteredCertObj = $CertObj | Where-Object {$_.NotAfter -lt $Date}
    $ifString = $FilteredCertObj.Thumbprint
    if ($null -ne $ifString){
        $CertArray += $FilteredCertObj
    }
    $PSSession | Remove-PSSession
}


if ($AsList -eq $true){
    $CertArray | Format-List
} else {
    $CertArray | Format-Table -Property PSComputerName,Thumbprint,NotAfter,Issuer -AutoSize -Wrap
}




