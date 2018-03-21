#---- VARIABLES
Set-Variable -Name PSHelperDirectory -Value "$(Split-Path $PROFILE)\helpers\" -Scope global -Description "Where i keep my helper scripts"
Set-Variable -Name ProfileRoot -Value "$(Split-Path $PROFILE)" -Scope global -Description "PowerShell Profile Root Directory"

#---- ALIAS'S
Set-Alias np notepad
Set-Alias np2 "${env:ProgramFiles}\Notepad2\Notepad2.exe"
Set-Alias vi "${env:ProgramFiles}\Notepad2\Notepad2.exe" -Description "Sometimes i have flashbacks of linux"
Set-Alias npp "${env:ProgramFiles}\Notepad++\notepad++.exe"
Set-Alias ff "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
Set-Alias ss Select-String -Description "Saves me typing 11 characters ... and correctly."
Set-Alias svc "services.msc" -Description "Opens services window"
Set-Alias opf "appwiz.cpl" -Description "Opens Program and Files window"
Set-Alias PF "appwiz.cpl" -Description "Opens Program and Files window"
Set-Alias gs -Value Open-GroupShare -Description "TO LAZY TO CLICK AND TYPE"
Set-Alias GroupShare -Value Open-GroupShare -Description "TO LAZY TO CLICK AND TYPE"
Set-Alias sqlui "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\Tools\Binn\ManagementStudio\Ssms.exe" -Description "Also default alias ssms but i always forget =["
Set-Alias gimp "${env:ProgramFiles}\GIMP 2\bin\gimp-2.8.exe"
Set-Alias vb "${env:ProgramFiles}\Oracle\VirtualBox\VirtualBox.exe"
Set-Alias vbox "${env:ProgramFiles}\Oracle\VirtualBox\VirtualBox.exe"
Set-Alias vbm "${env:ProgramFiles}\Oracle\VirtualBox\VBoxManage.exe"
Set-Alias vman "${env:ProgramFiles}\Oracle\VirtualBox\VBoxManage.exe"
Set-Alias pycharm -Value 'C:\Program Files\JetBrains\PyCharm Community Edition 2017.2\bin\pycharm64.exe'
Set-Alias wireshark -Value 'C:\Program Files\Wireshark\Wireshark.exe'
Set-Alias dockerUI -Value 'C:\Program Files\Docker\Docker\Docker for Windows.exe' -Description "Dam thing keeps crashing and needing a restart"
Set-Alias Hyper-V_DISABLE -value 'bcdedit /set hypervisorlaunchtype off'
Set-Alias Hyper-V_ENABLE -value 'bcdedit /set hypervisorlaunchtype auto'
Set-Alias which Get-Command -Description "I miss linux sometimes =["

Function _Write ([string] $PreText, [string] $ColoredText, [string] $PostText, [System.ConsoleColor] $color = "Magenta" ) 
{
    Write-Host -NoNewline $PreText
    Write-Host -NoNewline $ColoredText -ForegroundColor $color
    Write-Host $PostText
}


Function Open-ProfileDirectory ( )
{
    ii $(Split-Path $PROFILE)
}

Function Edit-PowershellFiles ( )
{
    code $PROFILE $( Get-ChildItem "$($PSHelperDirectory)\*.*" -Include "*.ps1" ).FullName
}

Function Edit-Module ( [string] $ModuleName = $null )
{
    #ii "$( split-path ( Get-Module -ListAvailable $ModuleName ).path -Parent )"
    code (Get-Module -ListAvailable $ModuleName).path
}

Function Open-ModuleFolder ( [string] $ModuleName = $null )
{
    #todo add folder
    ii $(Split-Path $PROFILE)
}

<#CAUSE I ALWAYS FORGET =[#>
Function Date-Examples 
{
    Write-Host "Date Function Created: Thursday, October 13, 2016 7:58:38 AM" -ForegroundColor Magenta

    Write-Host "`n-F 'yyyy.MM.dd.HH.mm.ss'" -ForegroundColor Cyan 
    Write-Host "2016.10.13.07.58.38"

    Write-Host "`n-F g" -ForegroundColor Cyan
    Write-Host "10/13/2016 7:58 AM"

    Write-Host "`n-F o" -ForegroundColor Cyan
    Write-Host "2016-10-13T07:58:38.9194951-04:00"

    Write-Host "`n-F u" -ForegroundColor Cyan
    Write-Host "2016-10-13 07:58:38Z"

    Write-Host "`n-F s" -ForegroundColor Cyan
    Write-Host "2016-10-13T07:58:38"

    Write-Host "`n-F T" -ForegroundColor Cyan
    Write-Host "7:58:38 AM"

    Write-Host "`nGet Day of Week Monday(1) - Sunday(7)" -ForegroundColor Cyan
    Write-Host "(Get-Date | Select-Object -ExpandProperty DayOfWeek)"

    Write-Host "`nConvert to UTC" -ForegroundColor Cyan
    Write-Host "(Get-Date).ToUniversalTime()"

    Write-Host "`nDayLightSavingsTime" -ForegroundColor Cyan
    Write-Host "(Get-Date).IsDaylightSavingTime()"

    Write-Host "`nGet-Date -uformat %j" -ForegroundColor Cyan
    Write-Host "287 #Day of Year"

    Write-Host "`nGet-Date -uformat %V" -ForegroundColor Cyan
    Write-Host "42 #Week of Year"
    
    Write-Host "`nMore Information: [https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-date?view=powershell-5.1]`n"
}

Set-Alias Show-msg -Value Display-Balloon
Function Display-Balloon
{
    [cmdletbinding( )]
    param(                      
            [string] $Title = "Default Title",     
            [string] $Message = "Default Message: $(Get-Date)",    
            [string] $Duration= 20000,     
            [ValidateSet("Info","Warning","Error")]             
            [string] $MessageType = "Info"                               
        )            
   
   [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null            
   $balloon = New-Object System.Windows.Forms.NotifyIcon            
   $path = Get-Process -id $pid | Select-Object -ExpandProperty Path            
   $icon = [System.Drawing.Icon]::ExtractAssociatedIcon( $path )            
   $balloon.Icon = $icon #"C:\Program Files\Microsoft Office 15\root\office15\1033\DataServices\FOLDER.ICO"                     
   $balloon.BalloonTipTitle = $Title  
   $balloon.BalloonTipText = $Message            
   $balloon.BalloonTipIcon = $MessageType       
   $balloon.Visible = $true            
   $balloon.ShowBalloonTip( $Duration ) 
}

<#MAIN#>
#---- DEFAULT WINDOW 
$MaxHeight = $Host.UI.RawUI.MaxPhysicalWindowSize.Height 
$MaxWidth = $Host.UI.RawUI.MaxPhysicalWindowSize.Width 
$MyBuffer = $Host.UI.RawUI.BufferSize 
$MyWindow = $Host.UI.RawUI.WindowSize  
#$MyWindow.Height = ( $MaxHeight - 95 ) 
#$MyWindow.Width = ( $Maxwidth - 30 ) 
$MyWindow.Height = ( 40 ) 
$MyWindow.Width = ( 110 )
$MyBuffer.Height = ( 9999 ) 
$MyBuffer.Width = ( $Maxwidth ) 
$host.UI.RawUI.set_bufferSize( $MyBuffer  ) 
$host.UI.RawUI.set_windowSize( $MyWindow ) 

Function Test-ConsoleColor 
{
    [cmdletbinding()]
    Param( )
     
    Clear-Host
    $heading = "White"
    Write-Host "Pipeline Output" -ForegroundColor $heading
    Get-Service | Select -first 5
     
    Write-Host "`nError" -ForegroundColor $heading
    Write-Error "I made a mistake"
     
    Write-Host "`nWarning" -ForegroundColor $heading
    Write-Warning "Let this be a warning to you."
     
    Write-Host "`nVerbose" -ForegroundColor $heading
    $VerbosePreference = "Continue"
    Write-Verbose "I have a lot to say."
    $VerbosePreference = "SilentlyContinue"
     
    Write-Host "`nDebug" -ForegroundColor $heading
    $DebugPreference = "Continue"
    Write-Debug "`nSomething is bugging me. Figure it out."
    $DebugPreference = "SilentlyContinue"
     
    Write-Host "`nProgress" -ForegroundColor $heading
    1..10 | foreach -Begin {$i=0} -process {
     $i++
     $p = ($i/10)*100
     Write-Progress -Activity "Progress Test" -Status "Working" -CurrentOperation $_ -PercentComplete $p
     Start-Sleep -Milliseconds 250 }
} 

#---- DEFAULT FONTS
#Display Path to PS Profile Root
$iSeperator = "============================================================================"
Write-Host $iSeperator -ForegroundColor Cyan
Write-Host -ForegroundColor Green "PowerShell Profile Root: $ProfileRoot"
Write-Host $iSeperator -ForegroundColor Cyan

#Lucida Console
$Host.UI.RawUI.ForegroundColor = "yellow"

#---- LOAD Modules
Write-Host "Loading Modules: " -ForegroundColor Green

gci "$ProfileRoot\modules\" -Filter *.psm1 |
Foreach-Object {Import-Module $ProfileRoot"\modules\*.psm1"}
 
gci "$ProfileRoot\modules\" -Filter *.psm1 |
Foreach-Object {Write-Host "$_" -ForegroundColor DarkGray}


#---- LOAD HELPERS
#Write-Host "Loading Helper files: " -ForegroundColor Green
#gci "$(Split-Path $PROFILE)\helpers\*.*" -Include "*.ps1" | % { Write-Host " $($_.FullName)" -ForegroundColor DarkGray;. $_.fullname }

Write-Host "Loading Helpers: " -ForegroundColor Green
pushd $ProfileRoot\helpers
$ivar = gci "$ProfileRoot\helpers\" -Filter *.ps1
$ivar.Name | Foreach-Object { . ".\$_" }
$ivar.Name | Foreach-Object {Write-Host "$_" -ForegroundColor DarkGray}
popd


#gci "$ProfileRoot\helpers\" -Filter *.ps1 |
#Foreach-Object (Import-Module "$_" }

#gci "$ProfileRoot\helpers\" -Filter *.ps1 |
#Foreach-Object {Write-Host "$_.Name" -ForegroundColor DarkGray}



#---- NO STUPID BEEP ON BACKSPACE Powershell 5.1 PSReadline (https://github.com/lzybkr/PSReadLine)
#Set-PSReadlineOption -BellStyle None

#---- PRINT OUT POWERSHELL VERSION
$PSVersionTable

#---- PRINT OUT PROMPT ARCHITECTURE
_write "Running 64-bit PowerShell `t[" $([Environment]::Is64BitProcess) "]"

#---- PRINT OUT POWERSHELL EXECTION POLICY
_Write "Execution Policy: `t`t[" $(Get-ExecutionPolicy ) "]" Cyan

#--- IP ADDRESS
_Write "IPAddress: `t`t`t[" $( get-WmiObject Win32_NetworkAdapterConfiguration| Where {$_.Ipaddress.length -gt 1} ).ipaddress[0] "]" Green

#---- DOMAIN INFO
_Write "I AM: `t`t`t`t[" $(whoami) "]" DarkCyan
_Write "Domain User: `t`t`t[" (Get-WmiObject Win32_ComputerSystem).Name "]" Gray
_Write "Domain Name: `t`t`t[" (Get-WmiObject Win32_ComputerSystem).Domain "]" DarkGreen

#---- OS NAME
_write "OS : `t`t`t`t[" $( ( get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName ).ProductName ) "]" White

#---- DEFAULT POWERSHELL LOCATION
Push-Location \
[Environment]::CurrentDirectory = ( Get-Location -PSProvider FileSystem ).ProviderPath
_Write "Environment CurrentDirectory: `t[" ( [Environment]::CurrentDirectory ) "]" DarkGray

#--- Display helpful message about modules
Write-Host ""
Write-Host "To see which modules are available, run: Show-MyModules"

<#
 TEST CRAP SHOULD BE DELETED
#>
Function test 
{
    [cmdletbinding( )]
    Param ( [string] $var = $null )

    Write-Host "Verbose flag present: [$VerbosePreference]"
    if ( ( [string]::IsNullOrWhiteSpace( $var ) )  -or ( $false -eq ( Test-Path $var ) ) ) 
    {
        $var = "default"
        Write-Verbose "Back up directory [$($var)]" 
    }
    
    Write-Host "var = $($var)"
    Write-Host "isVerbose = " + (isVerbose)
}

<#
    ENV PATH FUNCTIONS
#>
Set-Alias myPath -Value Path-List
Set-Alias Get-Path -Value Path-List
Function Path-List ( ) 
{
    ($env:path).split(';')
}

Set-Alias Add-ToPath -Value Add-Path
Function Path-Add ( $AddPath )
{
    if ( [string]::IsNullOrWhiteSpace( [string] $AddPath ) )
    {
        return "Path Cannot be empty"
    }

    if ( $ENV:PATH | Select-String -SimpleMatch $AddPath )
    { 
        return "Path ($AddPath) already exists."
    }

    if ( $true -eq $(Test-Path $AddPath ) )
    {
        $AddPath = ";$($AddPath.Trim( ))"
        [System.Environment]::SetEnvironmentVariable( "Path", $env:Path + $AddPath, [System.EnvironmentVariableTarget]::User )
    }
}

<#
.SYNOPSIS

.DESCRIPTION
Creates a file symbolic link in specified folder

.PARAMETER File
File to create the Symblic link

.PARAMETER SymbolicLinkFolder
Directory to create the link.

.EXAMPLE
SymbolicLink-Add -File C:\test\hello.ps1 -SymbolicLinkFolder C:\Users\$env:USERNAME
#This will add the file link in C:\Users\$env:USERNAME\hello.ps1

.NOTES
cause i never remeber how off the top of my head

#>#
Function SymbolicLink-Add 
{
    [CmdLetBinding( )]
    Param ( [string] $File, [string] $SymbolicLinkFolder )

    $LinkFile = (Get-Item $File)

    if ( $false -eq $LinkFile.Exists )
    {
        return "Cannot create symbolic link file does not exist: [$File]"
    }

    if ( $false -eq ( Test-Path $SymbolicLinkFolder ) )
    {
        New-Item -Type Directory -Path $SymbolicLinkFolder -Verbose: (isVerbose) -ErrorAction Stop
		#New-Item -Type Directory -Path $SymbolicLinkFolder -Verbose: (true) -ErrorAction Stop
    }

    New-Item -ItemType SymbolicLink -Path $SymbolicLinkFolder -Name $LinkFile.Name -Value $LinkFile -Verbose: (isVerbose)
	#New-Item -ItemType SymbolicLink -Path $SymbolicLinkFolder -Name $LinkFile.Name -Value $LinkFile -Verbose: (true)
}

Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-a4faccd\src\posh-git.psd1'
