Function bup ( [string] $BackupLocation = "C:\scripts\backup\" )
{ 
    Backup-Profile $BackupLocation $($PSHelperDirectory) -Verbose:(isVerbose)
}
Function Backup-Profile  
{
    [cmdletbinding( )]
    Param ( $BackupLocation = $null, [string] $ModuleDirectory = $null )

    Write-Verbose "Arguments: BackupLocation [$($BackupLocation)], ModuleDirectory: [$ModuleDirectory]"

    if ( ( $true -eq ( [string]::IsNullOrWhiteSpace( $BackupLocation ) ) ) -or ( $false -eq ( Test-Path $BackupLocation ) ) )
    {
        Write-Verbose "Setting Back up directory to default"
        $BackupLocation = $(Split-Path $PROFILE)
        Write-Verbose "Updated BackupLocation: [$($BackupLocation)]"
    }

    #COPY PROFILE
    Copy-Item $PROFILE -Destination "$($BackupLocation)\$( Split-Path $PROFILE -Leaf )-$(Get-Date -F 'yyyy.MM.dd.HH.mm').bak" -Verbose:(isVerbose)

    #COPY ADDITIONAL SCRIPT/MODULAR FOLDERS
    if ( ( $false -eq ( [string]::IsNullOrWhiteSpace( $ModuleDirectory ) ) ) -or ( $false -eq ( Test-Path $ModuleDirectory ) ) )
    {
        Write-Verbose "Backing up ModuleDirectory: [$ModuleDirectory]"
        Write-Verbose "Destination: [$BackupLocation]"
        Write-Verbose "Backup Name: [$( split-Path $ModuleDirectory -Leaf )-$(Get-Date -F 'yyyy.MM.dd.HH.mm')]"
        Copy-Item $ModuleDirectory -Destination "$($BackupLocation)\$( split-Path $ModuleDirectory -Leaf)-$(Get-Date -F 'yyyy.MM.dd.HH.mm')" -Recurse -Verbose:(isVerbose)
    }
}

<# Gets version of .dll or .exe files ...might blow up on other extentions like .jpeg or .txt #>
Set-Alias gfv -Value Get-FileVersion -Description "Gets File version" 
Function Get-FileVersion ( [string] $file ) 
{
    Write-Host "Checking path [$file]"
    if ( $false -eq ( Test-Path $file ) ) 
    {
        Write-Error "Could not find file"
        EXIT -1
    }

    $filename = Split-Path $file -Leaf
    $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$file").FileVersion
    Write-Host "$filename is at version [$ver]"
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

Set-Alias Add-ToPath -Value Path-Add
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

Function Path-Clean ( )
{
    $ENV:Path = ( $ENV:Path.Split(";") | Select-Object -Unique ) -join ";";
}

Set-Alias Search-4str -Value Find-StringInDirectory -Description "Searches for string in directory files"
Set-Alias Find-str -Value Find-StringInDirectory  -Description "Searches for string in directory files"
Function Find-StringInDirectory ( [string] $string2Find, [string] $Dir, [string] $ext = "*" ) 
{
    if ( [string]::IsNullOrWhiteSpace( $Dir ) ) 
    {
        Write-Warning "Directory Argument not set. Using Current [$($pwd.Path)]"
        $Dir = "."
    }

    if ( [string]::IsNullOrWhiteSpace( $string2Find ) ) 
    {
        Write-Warning "String to search for is a required argument"
        while ( [string]::IsNullOrWhiteSpace( $string2Find ) ) 
        {
            $string2Find = Read-Host "String to search for"
        }
    }

    gci -path "$($Dir)\*" -include "$($ext)" -Exclude *.exe, *.dll, *.pdb, *.msi, *.jar, *.wav, *.mp4, *.mpg, *.wmv, *.png, *.jpg -Recurse | % { 
    
        if ( (Get-Item $_) -isnot [System.IO.DirectoryInfo] ) {
            if ( [string]::IsNullOrWhiteSpace( $( gc $_.FullName | Select-String "$string2Find" ) ) ) {
                Write-Host "$($_.FullName)" -ForegroundColor Gray
            }
            else {
                Write-Host "---------------> $($_.FullName)" -ForegroundColor Green
            }
        }
    }
}

Function Set-EnvPerm{
[CmdletBinding()]
  Param(
      [Parameter(Mandatory=$true)] [string] $EnvName,
      [Parameter(Mandatory=$true)] [string] $EnvVal
  )
  
  Begin{
    
  }
  
  Process{
    Try{
        #[System.Environment]::SetEnvironmentVariable("$EnvName", "$EnvVal", [System.EnvironmentVariableTarget]::User)
        [System.Environment]::SetEnvironmentVariable("$EnvName", "$EnvVal", [System.EnvironmentVariableTarget]::Machine)
    }
    
    Catch{
        $exc = $_.Exception
        Write-Host "Exception Encountered: " $exc.DESCRIPTION
      Break
    }
  }
  
  End{
    If($?){
        Write-Host "Environment Variable: %$EnvName% is set as: $EnvVal"
    }
  }
}



Function Get-LargestDrive ( [string] $RemoteComputer = "127.0.0.1", [int]$drivetype = 3 ) 
{
    Invoke-Command -ComputerName $RemoteComputer -Credential $( Get-Credential ) -ScriptBlock { Get-WMIObject Win32_LogicalDisk -Filter "drivetype=$($drivetype)"  | Sort-Object -Property Size -Descending | Select-Object -First 1 }
}
