<#
.SYNOPSIS
  Password management script for IIS App Pools
.DESCRIPTION
  Password management script for IIS App Pools. 
  View App Pools owned by user, change App Pool user password, 
  or change App Pool ownership.
.NOTES
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  20 JUN 2019
 Purpose/Change:  Password Change
 Dependencies  :  None

.EXAMPLE
.\Set-AppPoolUserPassword.ps1 -UserName "domain\username" -NewPWString "p@ssW0rd"
<Run this to change the user's password for the app pool on a local session>

.EXAMPLE
.\Set-AppPoolUserPassword.ps1 -UserName "domain\username" -NewPWString "p@ssW0rd" -NewUserName "domain\newusername"
<Run this to change ownership of the app pool to a new user on a local session>

.EXAMPLE
.\Set-AppPoolUserPassword.ps1 -UserName "domain\username" -NewPWString "p@ssW0rd" -ViewOnly
<Run this to view the user's app pools on a local session>

.EXAMPLE
.\Set-AppPoolUserPassword.ps1 -UserName "domain\username" -NewPWString "p@ssW0rd" -MachineList ".\servers.txt"
<Run this to change the user's password for the app pool on a remote session with a text file containing the server names>

.EXAMPLE
.\Set-AppPoolUserPassword.ps1 -UserName "domain\username" -NewPWString "p@ssW0rd" -NewUserName "domain\newusername" -MachineList ".\servers.txt"
<Run this to change ownership of the app pool to a new user on a remote session with a text file containing the server names>

.EXAMPLE
.\Set-AppPoolUserPassword.ps1 -UserName "domain\username" -NewPWString "p@ssW0rd" -ViewOnly -MachineList ".\servers.txt"
<Run this to view the user's app pools on a remote session with a text file containing the server names>

#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string] $UserName,
  [Parameter(Mandatory=$false)] [string] $NewPWString,
  [Parameter(Mandatory=$false)] [string] $NewUserName = "none",
  [Parameter(Mandatory=$false)] [switch] $ViewOnly=$false,
  [Parameter(Mandatory=$false)] [string] $MachineList = "none"
)
# Set-ExecutionPolicy RemoteSigned
Import-Module WebAdministration
$applicationPools = ""
$Info = @()

if ($MachineList -ne "none"){
  $cmp_list = (get-content $MachineList)
}

# View the app pool's owner on local server
if (($ViewOnly) -and ($MachineList -eq "none")) {
    Import-Module WebAdministration
    $applicationPools = Get-ChildItem IIS:\AppPools | 
    Where-Object { $_.processModel.userName -eq $UserName }
    # Write-Host "[ComputerName: $env:COMPUTERNAME]"
    # $applicationPools
    Foreach ($pool in $applicationPools){
      $objInfo = New-Object psobject -Property @{
        'Name' = $pool.Name
        'State' = $pool.state
        'UserName' = $pool.processModel.userName
        'Password' = $pool.processModel.password -Join ", "
      }
      $Info += $objInfo
    } 
    $Info | Format-Table -Property Name,State, UserName,Password
    exit
}

# View the app pool's owner on remote servers using machinelist
if (($ViewOnly) -and ($MachineList -ne "none")) {
  foreach ($c in $cmp_list){
    if ($c -ne "localhost") {
      $PSSession = New-PSSession -ComputerName $c
      Invoke-Command -ScriptBlock {Import-Module WebAdministration} -Session $PSSession
      $applicationPools = Invoke-Command -ScriptBlock {Get-ChildItem IIS:\AppPools | 
        Where-Object {$_.processModel.userName -eq $Using:UserName}} -Session $PSSession
      $PSSession | Remove-PSSession
    } else {
      $applicationPools = Get-ChildItem IIS:\AppPools | 
      Where-Object {$_.processModel.userName -eq $UserName}
    }
    
    Foreach ($pool in $applicationPools){
      if ($c -ne "localhost")
      {
        $cmp = $c
      } else {
        $cmp = $env:COMPUTERNAME
      }
      $objInfo = New-Object psobject -Property @{
        'Name' = $pool.Name
        'State' = $pool.state
        'PSComputerName' = $cmp
        'UserName' = $pool.processModel.userName
        'Password' = $pool.processModel.password -Join ", "
      }
      $Info += $objInfo
    } 
    
  }
  $Info | Format-Table -Property Name,State, PsComputerName, UserName,Password
  exit
}

# Changing the app pool's owner from the local server
if (($NewUserName -ne "none")-and ($NewPWString) -and ($MachineList -eq "none")) {
  $applicationPools = Invoke-Command -ScriptBlock {Get-ChildItem IIS:\AppPools | 
    Where-Object {$_.processModel.userName -eq $Using:UserName}} -Session $PSSession
  Invoke-Command -ScriptBlock {Import-Module WebAdministration} -Session $PSSession
  
    foreach($pool in $applicationPools)
    {
      Write-Host "[ComputerName: $env:COMPUTERNAME, NewUserName: $NewUserName ]"
        $pool.processModel.userName = $NewUserName
        $pool.processModel.password = $NewPWString
        $pool.processModel.identityType = 3
        $pool | Set-Item        
    }
    exit
} 

# Changing the user's password from the local server
if (($NewUserName -eq "none")-and ($NewPWString) -and ($MachineList -eq "none")){
    $applicationPools =  {Get-ChildItem IIS:\AppPools | 
      Where-Object {$_.processModel.userName -eq $UserName}}
    foreach($pool in $applicationPools)
    {
      Write-Host "[ComputerName: $env:COMPUTERNAME, UserName: $UserName ]"
        $pool.processModel.userName = $UserName
        $pool.processModel.password = $NewPWString
        $pool.processModel.identityType = 3
        $pool | Set-Item
    }
    exit
}

# Changing the app pool's owner remotely via Machinelist
if (($NewUserName -ne "none")-and ($NewPWString) -and ($MachineList -ne "none")) {
  foreach ($c in $cmp_list){
    if ($c -ne "localhost") {
    $PSSession = New-PSSession -ComputerName $c
    Invoke-Command -ScriptBlock {Import-Module WebAdministration} -Session $PSSession
    $applicationPools = Invoke-Command -ScriptBlock {Get-ChildItem IIS:\AppPools | 
      Where-Object {$_.processModel.userName -eq $Using:UserName}} -Session $PSSession
    
     $appPoolArray += , $applicationPools
  Invoke-Command -ScriptBlock {
    foreach($pool in $Using:appPoolArray[0])
      {
        $pool;
        Write-Host "[ComputerName: $env:COMPUTERNAME, NewUserName: $Using:NewUserName ]"
          $pool.processModel.userName = $Using:NewUserName
          $pool.processModel.password = $Using:NewPWString
          $pool.processModel.identityType = 3
          $pool | Set-Item
          Write-Host "Password Updated: Pool: $pool NewUserName: $Using:NewUserName "
      }
    } -Session $PSSession
    $PSSession | Remove-PSSession
  } else {
    Import-Module WebAdministration
    $applicationPools = Get-ChildItem IIS:\AppPools | 
    Where-Object {$_.processModel.userName -eq $UserName}
    $appPoolArray += , $applicationPools
    foreach($pool in $appPoolArray[0])
      {
        $pool;
        Write-Host "[ComputerName: $env:COMPUTERNAME, NewUserName: $NewUserName ]"
          $pool.processModel.userName = $NewUserName
          $pool.processModel.password = $NewPWString
          $pool.processModel.identityType = 3
          $pool | Set-Item
          Write-Host "Password Updated: Pool: $pool NewUserName: $NewUserName "
      }
  }
  $appPoolArray = @()
  }
  exit
} 

# Changing the User's Password remotely via Machinelist
if (($NewUserName -eq "none") -and ($NewPWString) -and ($MachineList -ne "none")){
  foreach ($c in $cmp_list){
      $appPoolArray = @()
      if ($c -ne "localhost") {
      $PSSession = New-PSSession -ComputerName $c
      Invoke-Command -ScriptBlock {Import-Module WebAdministration} -Session $PSSession
      $applicationPools = Invoke-Command -ScriptBlock {Get-ChildItem IIS:\AppPools | 
        Where-Object {$_.processModel.userName -eq $Using:UserName}} -Session $PSSession
       $appPoolArray += , $applicationPools
    Invoke-Command -ScriptBlock {
      foreach($pool in $Using:appPoolArray[0])
        {
          $pool;
          Write-Host "[ComputerName: $env:COMPUTERNAME, UserName: $Using:UserName ]"
            $pool.processModel.userName = $Using:UserName
            $pool.processModel.password = $Using:NewPWString
            $pool.processModel.identityType = 3
            $pool | Set-Item
            Write-Host "Password Updated: Pool: $pool UserName: $Using:UserName "
        }
      } -Session $PSSession
      $PSSession | Remove-PSSession

    } else {
      Import-Module WebAdministration
      $applicationPools = Get-ChildItem IIS:\AppPools | 
        Where-Object {$_.processModel.userName -eq $UserName}
       $appPoolArray += , $applicationPools
    
      foreach($pool in $appPoolArray[0])
        {
          $pool;
          Write-Host "[ComputerName: $env:COMPUTERNAME, UserName: $UserName ]"
            $pool.processModel.userName = $UserName
            $pool.processModel.password = $NewPWString
            $pool.processModel.identityType = 3
            $pool | Set-Item
            Write-Host "Password Updated: Pool: $pool UserName: $UserName "
        }
    }
  }
  exit
}

 Write-Host "Application pool passwords updated..." -ForegroundColor Magenta 
