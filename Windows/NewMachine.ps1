#TODO: Prompt for Static Network and assign if requested
#TODO: Prompt whether to join Domain and do so if requested (don't forget about renaming machine)
#TODO: Prompt User for Git Username
#TODO: Prompt User for Git Email
#TODO: Look into automating VSCode Settings Sync more. I don't think it's possible though.
#TODO: If not joining to the domain, add other apps (Brave, Whatsapp, Discord for example)

$ProgressPreference = 'SilentlyContinue' # Stops web request loading bars clogging the output
$Path = Split-Path -Path $MyInvocation.MyCommand.Path 

#region Install Software through Winget
$AppsToInstall = @(
    "Microsoft.Powershell"
    "Microsoft.PowerToys"
    "Microsoft.WindowsTerminal"
    "Microsoft.VisualStudioCode"
    "Git.Git"
)

$CurrentlyInstalled = winget.exe list
foreach ($Application in $AppsToInstall) {
    if (($CurrentlyInstalled | Select-String -pattern $Application).Matches.Count -eq 0) {
        Write-Host "Installing $Application..." -ForegroundColor Yellow
        winget.exe install $Application
        Write-Host "$Application should now be installed!" -ForegroundColor Green
    }
    else {
        Write-Host "$Application already installed, skipping..." -ForegroundColor Green
    }
}
#endregion Install Software through Winget

#region Copying Config Files
#PowerToys - Keyboard Mapper
$Source = $Path + "\ConfigFiles\PowerToys\KeyboardManager\Default.json"
$Destination = "$ENV:USERPROFILE\AppData\Local\Microsoft\PowerToys\Keyboard Manager\Default.json"
Copy-Item -Path $Source -Destination $Destination -Force

#TODO: PowerToys Always On Top Config
#TODO: Any other PowerToys Configs?
#TODO: Windows Terminal Config Files

#endregion Copying Config Files

#region Running Commands
#TODO: Configure Git
#endregion Running Commands

#region Install SysInternals
Write-Host "Installing SysInternals..." -ForegroundColor Green
$Url = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
$SourcePath = "C:\ToolBox\SysInternals"

if((Test-Path -Path "C:\Toolbox\SysInternals") -ne $True)
{ 
    New-Item -Path "C:\Toolbox" -Name "SysInternals" -ItemType Directory -Force | Out-Null 
}

try {    
    Invoke-WebRequest -Uri $Url -OutFile "$SourcePath\Sysinternalssuite.zip"
    Expand-Archive -Path "$SourcePath\Sysinternalssuite.zip" -DestinationPath "$SourcePath\"
    Remove-Item "$SourcePath\Sysinternalssuite.zip"
}
catch {
    Write-Host "Error occured trying to retrieve and unzip SysInternals" -ForegroundColor Red
}

if((Get-ChildItem -Path $SourcePath).Count -gt 0)
{
    Write-Host "SysInternals installed!" -ForegroundColor Green
}
#TODO: Add SysInternals directory to Path

#endregion Install SysInternals
#region Install RSAT
# Get-WindowsCapability -Name "*RSAT*" -Online | Add-WindowsCapability -Online
#endregion Install RSAT