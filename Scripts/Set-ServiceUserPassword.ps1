<#
.SYNOPSIS
  Change the user and password for a service.
.DESCRIPTION
  Changes a services user and password by providing the username and a machine list text file.
  This script can also view all services that the user is currently set for. It can also check
  in different formats (i.e. acme\jdoe or jdoe@acme.com)
.NOTES
 (your notes)
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  16 July 2019
 Purpose/Change:  Initial
 Dependencies  :  Script uses WMI
.EXAMPLE 
PS:> .\Set-ServiceUserPassword.ps1 -UserName 'acme\jdoe' -ViewOnly

View all services in which acme\jdoe is the user
.EXAMPLE 
PS:> .\Set-ServiceUserPassword.ps1 -UserName 'acme\jdoe' -ViewOnly

View all services in which acme\jdoe is the user on the local machine
.EXAMPLE 
PS:> .\Set-ServiceUserPassword.ps1 -UserName 'acme\jdoe' -FindAllFormats

View all services in which acme\jdoe or jdoe@acme.com is the user on the local machine
.EXAMPLE 
PS:> .\Set-ServiceUserPassword.ps1 -UserName 'acme\jdoe' -ViewOnly -MachineList '.\comps.txt'

View all services in which acme\jdoe is the user on remote machines listed in .\comps.txt
.EXAMPLE 
PS:> .\Set-ServiceUserPassword.ps1 -UserName 'acme\jdoe' -FindAllFormats -MachineList '.\comps.txt'

View all services in which acme\jdoe or jdoe@acme.com is the user on remote machines listed in .\comps.txt
.EXAMPLE 
PS:> .\Set-ServiceUserPassword.ps1 -UserName 'acme\jdoe' -NewUserName 'acme\jsmith' -ServicePW 'p@ssword' -MachineList '.\comps.txt'

Update the username and password for all services in which acme\jdoe is the user on remote machines listed in .\comps.txt
.EXAMPLE 
PS:> .\Set-ServiceUserPassword.ps1 -UserName 'acme\jdoe' -NewUserName 'acme\jsmith' -ServicePW 'p@ssword'

Update the username and password for all services in which acme\jdoe is the user on the local machine

#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string] $UserName,
  [Parameter(Mandatory=$false)] [string] $NewUserName,
  [Parameter(Mandatory=$false)] [string] $ServicePW,
  [Parameter(Mandatory=$false)] [string] $MachineList= "none",
  [Parameter(Mandatory=$false)] [switch] $ViewOnly=$false,
  [Parameter(Mandatory=$false)] [switch] $FindAllFormats=$false
)

# if (($ViewOnly -ne $true) -or ($FindAllFormats -ne $true) -or ($MachineList -eq "none")){
#     $Cred = Get-Credential
# }

if (($ViewOnly -eq $true)-and ($FindAllFormats -eq $true)){
    Throw "Please use either -ViewOnly or -FindaAllFormats. Both cannot be used at once."
    exit
}

Function Set-ServicePassword {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [Object[]]$InputObject
    )
    if (!$ServicePW){
        Throw "Please provide a new password"
        exit
    }
    if ($NewUserName){
        $svcUser = $NewUserName
    } else {
        $svcUser = $UserName
    }

    foreach ($sp in $InputObject){
        # $sp
        $sp_name = $sp.name 
        $sp_system = $sp.SystemName
        ($svc_Obj= Get-WmiObject Win32_Service -ComputerName $sp_system | Where-Object {$_.Name -eq "$sp_name"}) | Out-Null # -Credential $cred
        $svc_Obj.StopService() | Out-Null
        ($ChangeStatus = $svc_Obj.change($null,$null,$null,$null,$null,$null,$svcUser,$ServicePW,$null,$null,$null)) | Out-Null
        If ($ChangeStatus.ReturnValue -eq "0")  
            {Write-host "User Name and password updated for the service '$sp_name' in $sp_system" -ForegroundColor 'Green'} 
        $svc_Obj.StartService() | Out-Null
    }
}


#Find all service username formats remoting
Function Find-AllUserNameFormatsRemote {
    if ($UserName.Contains("\")){
        $SplitName = $UserName.split("\")[1] 
    }elseif ($UserName.Contains("@")){
        $SplitName = $UserName.split('@')[1].split('.')[0] 
    } else {
        $SplitName = $UserName
    }
    
    if ($MachineList){
        foreach ($c in $machines){ 
            $Service = get-wmiobject win32_service -comp $c | 
                Select-Object name,startname, StartMode, State, Status, DisplayName, SystemName | 
                Where-Object {$_.startname -like "*$SplitName*"}
            return $Service
        }
    }
}

#Find all service username formats locally
Function Find-AllUserNameFormatsLocal {
    if ($UserName.Contains("\")){
        $SplitName = $UserName.split("\")[1] 
    }elseif ($UserName.Contains("@")){
        $SplitName = $UserName.split('@')[1].split('.')[0] 
    } else {
        $SplitName = $UserName
    }
    
    $Service = get-wmiobject win32_service | 
        Select-Object name,startname, StartMode, State, Status, DisplayName, SystemName | 
        Where-Object {$_.startname -like "*$SplitName*"}
    return $Service
}



#Find service username remoting 
Function Find-ServicesByUserRemote {
    if ($MachineList){
        foreach ($c in $machines){ 
            $Service = get-wmiobject win32_service -comp $c | 
                Select-Object name,startname, StartMode, State, Status, DisplayName, SystemName | 
                Where-Object {$_.startname -eq "$UserName"}
            return $Service
        }
    }
}

#Find service username locally 
Function Find-ServicesByUserLocal {
    $Service = get-wmiobject win32_service -comp $c | 
        Select-Object name,startname, StartMode, State, Status, DisplayName, SystemName | 
        Where-Object {$_.startname -eq "$UserName"}
    return $Service
}


# Main Logic

if ($MachineList -ne "none"){
    $machines = Get-Content -Path $MachineList
}


if($FindAllFormats -eq $true) {
    if ($MachineList -ne "none"){
        Find-AllUserNameFormatsRemote
        exit
    }
    if ($MachineList -eq "none"){
        Find-AllUserNameFormatsLocal
        exit
    }
}

if($FindAllFormats -ne $true) {
    if ($MachineList -ne "none"){
        if ($ViewOnly -eq $true){
            Find-ServicesByUserRemote
            exit
        } else {
            $ServicesToUpdate = Find-ServicesByUserRemote
            Set-ServicePassword -InputObject $ServicesToUpdate
        }
    }
    if ($MachineList -eq "none"){
        if ($ViewOnly -eq $true){
            Find-ServicesByUserLocal
            exit
        } else {
            $ServicesToUpdate = Find-ServicesByUserLocal
            Set-ServicePassword -InputObject $ServicesToUpdate
        }
    }
}

