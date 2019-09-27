<#
.SYNOPSIS
  Scheduled Task Maintenance Script
.DESCRIPTION
  Script used to view or modify Scheduled Task username and password. 
  Can be used locally or remotely. Script will run remotely if provided
  a machine list of server names.
.NOTES
 (your notes)
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  12 July 2019
 Purpose/Change: 
 Dependencies  :  PowerShell Version 5
.EXAMPLE 
PS:> .\Set-TaskSchedulerPasswordByUser.ps1 -UserName 'acme\JDoe' -ViewOnly

View Scheduled Tasks by owner locally

.EXAMPLE 
PS:> .\Set-TaskSchedulerPasswordByUser.ps1 -UserName 'acme\JDoe' -NewUserName -TaskPW 'P@ssword123'

Change/Modify Scheduled Tasks owner/password locally

.EXAMPLE 
PS:> .\Set-TaskSchedulerPasswordByUser.ps1 -UserName 'acme\JDoe' -MachineList '.\machine_list.txt' -ViewOnly

View Scheduled Tasks by owner remotely with a Machine List Text File
.EXAMPLE 
PS:> .\Set-TaskSchedulerPasswordByUser.ps1 -UserName 'acme\JDoe' -NewUserName 'acme\svc-account' -MachineList '.\machine_list.txt' -TaskPW 'p@ssword123'

Change/Modify Scheduled Tasks owner/password remotely with a Machine List Text File
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string] $UserName,
  [Parameter(Mandatory=$false)] [string] $NewUserName,
  [Parameter(Mandatory=$false)] [string] $TaskPW,
  [Parameter(Mandatory=$false)] [string] $MachineList= "none",
  [Parameter(Mandatory=$false)] [switch] $ViewOnly=$false
)

$TasksToUpdate = @()


#Custom object
$TaskObjectTemplate = New-Object -TypeName psobject
$TaskObjectTemplate | Add-Member -MemberType NoteProperty -Name TaskName -Value ""
$TaskObjectTemplate | Add-Member -MemberType NoteProperty -Name TaskAuthor -Value ""
$TaskObjectTemplate | Add-Member -MemberType NoteProperty -Name TaskUserID -Value ""
$TaskObjectTemplate | Add-Member -MemberType NoteProperty -Name TaskUserDN -Value ""
$TaskObjectTemplate | Add-Member -MemberType NoteProperty -Name ComputerName -Value ""



# Script Logic

if ($MachineList -ne "none"){
    $machines = Get-Content -Path $MachineList
}

if ($MachineList){
    foreach ($c in $machines){ 
        $PSSession = New-PSSession -ComputerName $c
        
        $Tasks = Invoke-Command -ScriptBlock {Get-ScheduledTask | 
            Where-Object {$_.TaskPath -eq "\"} } -Session $PSSession
        $PSSession | Remove-PSSession
        Foreach ($Task in $Tasks){
            if ($UserName.Contains("\")){
                $SplitName = $UserName.split("\")[1] 
            }

            if ($UserName.Contains("@")){
                $SplitName = $UserName.split('@')[1].split('.')[0] 
            }
                     
            if ($Task.Principal.UserId -eq $SplitName){
                $TaskObject = $TaskObjectTemplate.PSObject.Copy()
                $TaskObject.TaskName = $Task.TaskName
                $TaskObject.TaskAuthor = $Task.Author
                $TaskObject.TaskUserID = $Task.Principal.UserId
                $TaskObject.TaskUserDN = $UserName
                $TaskObject.ComputerName = $c
                $TasksToUpdate += , $TaskObject
            }
        }

        if (!$ViewOnly){
            if (!$TaskPW){
                Write-Output "Please provide a password"
                exit
            }
            if (!$NewUserName){
                Write-Output "Please provide a new username"
                exit
            }
            Foreach ($t in $TasksToUpdate) {
                $TaskToChange = $t.TaskName
                $PSSession = New-PSSession -ComputerName $t.ComputerName
                $SetTasks = Invoke-Command -ScriptBlock {Set-ScheduledTask -TaskName $Using:TaskToChange -TaskPath "\" -User $Using:NewUserName -Password $Using:TaskPW } -Session $PSSession
                $SetTasks
                $PSSession | Remove-PSSession
            }
        }
    }
}

# Update Password locally
if ($MachineList -eq "none"){
    $Tasks = Get-ScheduledTask | Where-Object {$_.TaskPath -eq "\"}
    Foreach ($Task in $Tasks){
        if ($UserName.Contains("\")){
            $SplitName = $UserName.split("\")[1] 
        }

        if ($UserName.Contains("@")){
            $SplitName = $UserName.split('@')[1].split('.')[0] 
        }
                     
        if ($Task.Principal.UserId -eq $SplitName){
            $TaskObject = $TaskObjectTemplate.PSObject.Copy()
            $TaskObject.TaskName = $Task.TaskName
            $TaskObject.TaskAuthor = $Task.Author
            $TaskObject.TaskUserID = $Task.Principal.UserId
            $TaskObject.TaskUserDN = $UserName
            $TaskObject.ComputerName = $Task.PSComputerName
            $TasksToUpdate += , $TaskObject
        }
    }

        if (!$ViewOnly){
            if (!$TaskPW){
                Write-Output "Please provide a password"
                exit
            }
            if (!$NewUserName){
                Write-Output "Please provide a new username"
                exit
            }
            Foreach ($t in $TasksToUpdate) {
                $TaskToChange = $t.TaskName
                $SetTasks = Set-ScheduledTask -TaskName $TaskToChange -TaskPath "\" `
                -User $NewUserName -Password $TaskPW
                $SetTasks
            }
        }
}

# Display the Tasks
if ($ViewOnly){
    $TasksToUpdate
    exit
}
