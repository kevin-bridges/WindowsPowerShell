<#
.SYNOPSIS
  Easy copy utility to copy files or folders to multiple servers
.DESCRIPTION
  Easy copy utility to copy files or folders to multiple servers.
  Can also easily specify to copy as another accont user.
  This can be useful if copying items to another domain.
.NOTES
 Version       :  1.0
 Author        :  Kevin Bridges
 Creation Date :  3 February 2021
 Purpose/Change: 
 Dependencies  : 
.EXAMPLE 
PS:> .\Copy-FilesToRemote.ps1 "C:\temp\my.img" -Computername "vm1" -ToDir "C:\temp\dir"
Copy a single file to remote server
 .EXAMPLE 
PS:> .\Copy-FilesToRemote.ps1 -FilePath ".\a.txt" -Computername "vm1" -ToDir "C:\temp\dir"
Copy a single file to remote server
.EXAMPLE 
PS:> .\Copy-FilesToRemote.ps1 -FilePath ".\a.txt" -Computername "vm1","vm2" -ToDir "C:\temp\dir"
Copy a single file to 2 remote servers
.EXAMPLE 
PS:> .\Copy-FilesToRemote.ps1 -FilePath ".\directory1\" -Computername "vm1" -ToDir "C:\temp\dir"
Copy a directory and its contents to remote server
.EXAMPLE 
PS:> .\Copy-FilesToRemote.ps1 -FilePath ".\a.txt" -Serverlist ".\servers.txt" -ToDir "C:\temp\dir"
Copy a single file to remote servers in a server list text file
.EXAMPLE 
PS:> .\Copy-FilesToRemote.ps1 -FilePath ".\a.txt" -Serverlist ".\servers.txt" -ToDir "C:\temp\dir" -AlternateCreds
Copy a single file to remote servers in a server list text file using alternate credentials
An interactive password window stores the credentials.
#>
[CmdletBinding(DefaultParameterSetName="Hostname")]
param(
  [Parameter(Position=0,Mandatory=$true)] [string] $FilePath,
  [Parameter(Mandatory=$true,ParameterSetName='Hostname')] [string[]] $Computername,
  [Parameter(Mandatory=$true,ParameterSetName='List')] [string] $Serverlist,
  [Parameter(Mandatory=$true)] [string] $ToDir,
  [Parameter(Mandatory=$false)] [Switch] $AlterateCreds
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
    #Get-Content -Path $Serverlist
    $Computername = Get-Content -Path $Serverlist
}

if($AlterateCreds -eq $true){
    $mypwd = Get-Credential
}

# Create hash table
$entries = @()

foreach (${item} in ${Computername}) {
    if($AlterateCreds -eq $true){
        $PSSession = New-PSSession -ComputerName $item -Credential $mypwd
        #if folder doesn't exist, create it
        $result = Invoke-Command -ScriptBlock {
            #test to make sure temp dir exists
            If (test-path $Using:ToDir){return $true}else{return $false};         
        } -Session $PSSession

        # Create C:\Temp\mycert if it doesn't exist
        if ($result -eq $false){
            Invoke-Command -ScriptBlock {New-Item -Path $Using:ToDir -ItemType DIR | Out-Null} -Session $PSSession
        }
        #Copy item
        Copy-Item $FilePath -Destination $ToDir -Recurse -Force -ToSession $PSSession
        
        # Add entry to array
        $Result = "" | Select-Object Computer,FilePath,ToDir
        $Result.Computer= $item
        $Result.FilePath= $FilePath
        $Result.ToDir= $ToDir
        $entries += $Result
        $PSSession | Remove-PSSession
    } else {
        $PSSession = New-PSSession -ComputerName $item
        #if folder doesn't exist, create it
        $result = Invoke-Command -ScriptBlock {
            #test to make sure temp dir exists
            If (test-path $Using:ToDir){return $true}else{return $false};         
        } -Session $PSSession

        # Create folder if it doesn't exist
        if ($result -eq $false){
            Invoke-Command -ScriptBlock {New-Item -Path $Using:ToDir -ItemType DIR | Out-Null} -Session $PSSession
        }

        #Copy item
        Copy-Item $FilePath -Destination $ToDir -Recurse -Force -ToSession $PSSession
        
        # Add entry to array
        $Result = "" | Select-Object Computer,FilePath,ToDir
        $Result.Computer= $item
        $Result.FilePath= $FilePath
        $Result.ToDir= $ToDir
        $entries += $Result

        $PSSession | Remove-PSSession 
    }

    

}

$entries
