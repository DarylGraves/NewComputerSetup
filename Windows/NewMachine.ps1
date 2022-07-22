#TODO: Prompt for Static Network and assign if requested
#TODO: Prompt whether to join Domain and do so if requested (don't forget about renaming machine)
#TODO: Prompt User for Git Username
#TODO: Prompt User for Git Email
#TODO: Look into automating VSCode Settings Sync more. I don't think it's possible though.
#TODO: If not joining to the domain, add other apps (Brave, Whatsapp, Discord for example)
#TODO: PowerToys Always on Toy Config
#TODO: Any other PowerToys Configs?
#TODO: Vim Profile
#TODO: Powershell Profile
#TODO: Configure Git

$ProgressPreference = 'SilentlyContinue' # Stops web request loading bars clogging the output
$Path = Split-Path -Path $MyInvocation.MyCommand.Path 

$AppsToInstall = @(
    "Microsoft.Powershell"
    "Microsoft.PowerToys"
    "Microsoft.WindowsTerminal"
    "Microsoft.VisualStudioCode"
    "Lexikos.AutoHotKey"
    "Git.Git"
    "Vim.Vim"
)

function Create-TempFolder {
    if ((Test-Path "C:\temp") -ne $true) {
        New-Item -Path "C:\temp" -ItemType Directory | Out-Null
    }
}

function Install-Applications {
    param (
        [String[]]$AppsToInstall
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
}

function Install-Fonts {
    Write-Host "Installing Fonts..." -ForegroundColor Green

    $FontUrls = @(
        # Nerd Font - For Windows Terminal
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip"
    )
    $TempFolder = "C:\Windows\Temp\Fonts"
    $FontInstaller = (New-Object -ComObject Shell.Application).Namespace(0x14) # Don't ask...

    foreach ($Font in $FontUrls) {
        Invoke-WebRequest -Uri $Font -OutFile "C:\temp\$(Split-Path $Font -leaf)"
        Expand-Archive -Path "C:\temp\$(Split-Path $Font -leaf)" -DestinationPath $TempFolder -Force

        Get-ChildItem -path $TempFolder | ForEach-Object {
            $Font = $_.FullName
            $FontInstaller.CopyHere($Font,0x10)
            Remove-Item $Font -Force
        }
    }

    Get-Childitem "C:\temp" | Remove-Item -Force
}
    
function Install-SysInternals {
    Write-Host "Installing SysInternals..." -ForegroundColor Green
    $Url = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
    $SourcePath = "C:\ToolBox\SysInternals"
    
    if((Test-Path -Path "C:\Toolbox\SysInternals") -ne $True)
    { 
        New-Item -Path "C:\Toolbox" -Name "SysInternals" -ItemType Directory -Force | Out-Null 
    }
    
    try {    
        Invoke-WebRequest -Uri $Url -OutFile "$SourcePath\Sysinternalssuite.zip"
        Expand-Archive -Path "$SourcePath\Sysinternalssuite.zip" -DestinationPath "$SourcePath\" -Force
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
}

function Install-RsatTools {
    Get-WindowsCapability -Name "*RSAT*" -Online | Add-WindowsCapability -Online
}

function Set-AutoHotKeyScripts {
    $Files = @(
        # Add each file to be moved as a PS Custom Object with a Source and Destination
        [PSCustomObject]@{
            Source = $Path + "\ConfigFiles\AutoHotKey\startup.ahk"
            Destination = $Env:APPDATA + "\Microsoft\Windows\Start Menu\Programs\Startup"
        }
    )

    foreach ($File in $Files) {
        Copy-Item -Path $File.Source -Destination $File.Destination
    }
}

function Set-PowerToysConfigFiles {
    # Keyboard Mapper
    $Source = $Path + "\ConfigFiles\PowerToys\KeyboardManager\Default.json"
    $Destination = "$ENV:USERPROFILE\AppData\Local\Microsoft\PowerToys\Keyboard Manager\Default.json"
    Copy-Item -Path $Source -Destination $Destination -Force
}

function Set-WindowsTerminalConfigFile {
    $Source = $Path + "\ConfigFiles\WindowsTerminal\settings.json"
    $Destination = "$Env:USERPROFILE\Appdata\local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\"
    Copy-Item -Path $Source -Destination $Destination -Force
}

# Create-TempFolder
# Install-Applications -AppsToInstall $AppsToInstall
# Install-Fonts
# Install-SysInternals
# Install-RsatTools
# Set-PowerToysConfigFiles
# Set-WindowsTerminalConfigFile
Set-AutoHotKeyScripts