
#requires -version 2

#---------------------------------------------------------[Help Menu]--------------------------------------------------------

<#
.SYNOPSIS
  Invoke a PowerShell Script on multiple machines with a file containing machine names
.DESCRIPTION
  Run PowerShell Scripts on other machines using remoting
.PARAMETER <Parameter_Name>
    -MachineList    - Reference a text file with a machine name on each line
    -Script         - Reference with powershell script you want to run
.INPUTS
  None
.OUTPUTS
  C:\Logs\ *Invoke-PS_ScriptByMachineList_<DATE_STRING>.log
.NOTES
  Version:        1.0
  Author:         Kevin Bridges (kevin.b.bridges@gmail.com)
  Creation Date:  02/07/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  PS:>  .\Invoke-PS_ScriptByMachineList.ps1 -MachineList .\testmachinelist.list -Script .\sayHi.ps1
#>


#-----------------------------------------------------------[Declarations]---------------------------------------------------------

param([string]$MachineList, [string]$Script)
$StartTime =  get-date -format "yyyy_MMM_dd__HH_mm_ss"
$LogFile = "C:\Logs\Invoke-PS_ScriptByMachineList_$StartTime.log"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Invoke-PS_ScriptsRemotely{
[CmdletBinding()]
  Param(
      [Parameter(Mandatory=$true)] [string] $MachineListForFunction,
      [Parameter(Mandatory=$true)] [string] $ScriptToRun
  )
  
  Begin{
    $MachineListArray = Get-Content $MachineListForFunction
  }
  
  Process{
    Try{
        foreach($Item in $MachineListArray){
            Write-Host "Running script[$ScriptToRun] on [$Item]" 
            Invoke-Command -ComputerName $Item -FilePath $ScriptToRun
        }

    }
    
    Catch{
        $exc = $_.Exception
        Write-Host "Exception Encountered: " $exc.DESCRIPTION 
      Break
    }
  }
  
  End{
    If($?){
        Write-Host "All remote scripts have completed" 
    }
  }
}


#-----------------------------------------------------------[Execution]---------------------------------------------------------

Start-Transcript -path $LogFile -append
Invoke-PS_ScriptsRemotely -MachineListForFunction $MachineList -ScriptToRun $Script 
Stop-Transcript
