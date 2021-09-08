<#
.SYNOPSIS
Easy Directory Selector Menu
.DESCRIPTION
Easy Directory Selector Menu
Either select, add, or remove favorite directories
.NOTES
Version       :  1.0
Author        :  Kevin Bridges
Creation Date :  
Purpose/Change:   
Dependencies  :  Works best if added to $env:PATH variable
.EXAMPLE 
PS:> Select-Dir
Run script normally. This will bring up the selection menu. Script should be added to path variable.
.EXAMPLE
PS:> .\Select-Dir.ps1
Run script normally. This will bring up the selection menu. Need to be in the scripts directory to run this way.
.EXAMPLE
PS:>  Select-Dir.ps1 -AddPresentDirectory
Add the present directory to the file 
.EXAMPLE
PS:>  Select-Dir.ps1 -RemoveEntries
Remove directories from the file 
#>
[CmdletBinding(DefaultParameterSetName = 'x')] #empty param set
param(
    [Parameter(Mandatory = $false, ParameterSetName = 'AddPresentDirctory')] [Switch] $AddPresentDirectory = $false,
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveEntries')] [Switch] $RemoveEntries = $false
)


Function Create-Menu () {
    
    Param(
        [Parameter(Mandatory = $false)][String]$MenuTitle,
        [Parameter(Mandatory = $false)][array]$MenuOptions
    )

    $MaxValue = $MenuOptions.count - 1
    $Selection = 0
    $EnterPressed = $False
    
    Clear-Host

    While ($EnterPressed -eq $False) {
        
        Write-Host "$MenuTitle"

        For ($i = 0; $i -le $MaxValue; $i++) {
            
            If ($i -eq $Selection) {
                Write-Host -BackgroundColor Cyan -ForegroundColor Black "[ $($MenuOptions[$i]) ]"
            }
            Else {
                Write-Host "  $($MenuOptions[$i])  "
                
            }

        }

        $KeyInput = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode

        Switch ($KeyInput) {
            13 {
                $EnterPressed = $True
                
                if ($RemoveEntries -eq $true) {
                    #remove entry from list
                    $mySelect = $MenuOptions[$Selection]
                    $mySelect
                    $data = foreach ($line in Get-Content $filepath) {
                        if ($line -notlike $mySelect) {
                            $line
                        }
                    }
                    $data | Set-Content $filepath -Force
                    Clear-Host
                    break
                }
                # Return $Selection
                Clear-Host
                Push-Location $MenuOptions[$Selection]
                break
            }

            38 {
                If ($Selection -eq 0) {
                    $Selection = $MaxValue
                }
                Else {
                    $Selection -= 1
                }
                Clear-Host
                break
            }

            40 {
                If ($Selection -eq $MaxValue) {
                    $Selection = 0
                }
                Else {
                    $Selection += 1
                }
                Clear-Host
                break
            }
            Default {
                Clear-Host
            }
        }
    }
}

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$file = 'dirs.txt'
$filepath = "$dir\$file"

if (-not(Test-Path -Path $filepath -PathType Leaf)) {
    New-Item -ItemType File -Path $filepath -Force -ErrorAction Stop
    Add-Content -Path $filepath -Value $env:USERPROFILE -Force
    Write-Host "The file [$file] didn't exist, so it has now been created and populated with one default value ($env:USERPROFILE) Please add more values to it"
    break
}

[string[]]$arrayFromFile = Get-Content -Path $filepath

if ($AddPresentDirectory -eq $true) {
    $pdir = (pwd).Path
    Add-Content -Path $filepath -Value $pdir -Force
    Write-Host "Added [$pdir] to favorites"
    break
}

$banner = @'
#################################
        Select Directory
#################################
'@

if ($RemoveEntries -eq $true) {
    $banner = @'
#################################
        Remove Directory
#################################
'@ 
}
Create-Menu -MenuTitle $banner -MenuOptions $arrayFromFile
