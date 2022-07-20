#TODO: Prompt for Static Network and assign if requested
#TODO: Prompt whether to join Domain and do so if requested (don't forget about renaming machine)
#TODO: Prompt User for Git Username
#TODO: Prompt User for Git Email
#TODO~ Configure Git
#TODO: Look into automating VSCode Settings Sync more. I don't think it's possible though.

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


#region Install RSAT
# Get-WindowsCapability -Name "*RSAT*" -Online | Add-WindowsCapability -Online
#endregion Install RSAT