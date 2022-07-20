#TODO: Prompt for Static Network and assign if requested
#TODO: Prompt whether to join Domain and do so if requested (don't forget about renaming machine)
#TODO: Prompt User for Git Username
#TODO: Prompt User for Git Email
#TODO: Look into automating VSCode Settings Sync more. I don't think it's possible though.
#TODO: If not joining to the domain, add other apps (Brave, Whatsapp, Discord for example)

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

#region Install RSAT
# Get-WindowsCapability -Name "*RSAT*" -Online | Add-WindowsCapability -Online
#endregion Install RSAT