#TODO: Prompt for Static Network and assign if requested
#TODO: Prompt whether to join Domain and do so if requested (don't forget about renaming machine)
#TODO: Prompt User for Git Username
#TODO: Prompt User for Git Email
#TODO: Look into automating VSCode Settings Sync more. I don't think it's possible though.
#TODO: If not joining to the domain, add other apps (Brave, Whatsapp, Discord for example)
#TODO: Any other PowerToys Configs?
#TODO: FancyZones Custom Layouts
#TODO: Vim Profile
#TODO: Powershell Profile
#TODO: TaskBar order (Pinned items)
#TODO: TaskBar - Remove search, cortana, taskbar and weather
#TODO: TaskBar - Hide when not in use
#TODO: Configure Git
#TODO: Request a reboot after

$Global:ProgressPreference = 'SilentlyContinue' # Stops Expand-Archive Loading bars clogging the output
$ProgressPreference = 'SilentlyContinue' # Stops web request loading bars clogging the output
$Path = Split-Path -Path $MyInvocation.MyCommand.Path 
$CommentLine = "##########################################"

# These install on every machine - Work and Private
$EssentialAppsToInstall = @(
    "Lexikos.AutoHotKey"
    # "Git.Git"
    # "JanDeDobbeleer.OhMyPosh"
    # "Microsoft.Powershell"
    # "Microsoft.PowerToys"
    # "Microsoft.WindowsTerminal"
    # "Microsoft.VisualStudioCode"
    # "Vim.Vim"
)

# These only install on Private machines
$PrivateAppsToInstall = @(
    "BraveSoftware.BraveBrowser"
    # "RoyalApps.RoyalTS"
    # "GOG.Galaxy"
    # "Valve.Steam"
    # "OBSProject.OBSStudio"
    # "Microsoft.VisualStudio.2019.Community"
    # "Cockos.REAPER"
)

# These only install on Work machines
$WorkAppsToInstall = @(
    #TODO: Remove mRemoteNG when finished testing
    "mRemoteNG.mRemoteNG"
)

function Get-WorkOrPersonal {
    $validOutput = $false
    $Answer = ""

    do {
        Write-Host "(" -NoNewline
        Write-Host "W" -NoNewLine -ForegroundColor Yellow
        Write-Host ")ork or (" -NoNewline
        Write-Host "P" -NoNewline -ForegroundColor Yellow
        Write-Host ")ersonal computer: " -NoNewline
        $Answer = Read-Host

        if ($Answer -eq "W" -or $Answer -eq "P") {
            $validOutput = $true
        }
    } while ($ValidOutput -ne $true)

    Return $Answer
}

function Set-TempFolder {
    if ((Test-Path "C:\temp") -ne $true) {
        New-Item -Path "C:\temp" -ItemType Directory | Out-Null
    }

    Set-Location -Path "C:\temp"
}

function Install-Applications {
    param (
        [String[]]$AppsToInstall
        )
        
    $CurrentlyInstalled = winget.exe list
        
    foreach ($Application in $AppsToInstall) {
        $ApplicationName = $Application.Split(".")[1]

        if (($CurrentlyInstalled | Select-String -pattern $Application).Matches.Count -eq 0) {
            Write-Host "Installing $ApplicationName... " -ForegroundColor Green
            winget.exe install $Application | Out-Null
            Write-Host "$ApplicationName should now be installed!" -ForegroundColor Green
        }
        else {
            Write-Host "$ApplicationName already installed, skipping..." -ForegroundColor Yellow
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
    Write-Host "Installing SysInternals... " -ForegroundColor Green -NoNewline

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
    Write-Host "Installing RSAT Tools, this one takes some time... " -ForegroundColor Green -NoNewLine

    $Success = $false
    try {
        Get-WindowsCapability -Name "*RSAT*" -Online | Add-WindowsCapability -Online | Out-Null
        $Success = $true
    }
    catch {
        Write-Host "Error occured!" -ForegroundColor Red
    }

    if ($Success) { Write-Host "Success!" -ForegroundColor Green }
}

function Set-PowershellProfile {
    Write-Host "Creating Powershell Profile if it doesn't already exist..." -ForegroundColor Green

    if((Test-Path $Profile ) -ne $true){
        New-Item -Path $Profile -ItemType File -Force     
    } 
}

function Set-OhMyPosh {
    Write-Host "Configuring Oh-My-Posh for pwsh" -ForegroundColor Green

    $Theme = "$env:userprofile\Appdata\Local\Programs\oh-my-posh\themes\slim.org.json"
    $Executable = $ENV:USERPROFILE + "\Appdata\Local\Programs\oh-my-posh\bin\oh-my-posh.exe"   
    $Command = ". $Executable init pwsh --config $Theme | Invoke-Expression"
    
    # Only do this if Oh-My-Posh isn't already referenced in the profile.
    if ((Select-String -Path $Profile -Pattern "Oh-My-Posh").Matches.Count -eq 0) {
        $CommentLine | Out-File -FilePath $Profile -Append
        "# Oh-My-Posh Settings" | Out-File -FilePath $Profile -Append
        $CommentLine | Out-File -FilePath $Profile -Append
        $Command | Out-File -FilePath $Profile -Append    
    }  
}

function Set-AutoHotKeyScripts {
    Write-Host "Adding AutoHotKey scripts to startup..." -ForegroundColor Green

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
    Write-Host "Copying PowerToys config files..." -Foreground Green

    # Keyboard Mapper
    Write-Host "Keyboard Manager... " -NoNewLine -ForegroundColor Yellow
    $Success = 0

    try {
        $Source = $Path + "\ConfigFiles\PowerToys\KeyboardManager\Default.json"
        $Destination = "$ENV:USERPROFILE\AppData\Local\Microsoft\PowerToys\Keyboard Manager\Default.json"
        Copy-Item -Path $Source -Destination $Destination -Force    
        $Success = 1
    }
    catch {
        Write-Host "Failed!" -ForegroundColor Red
    }

    if ($Success -eq 1) {
        Write-Host "Complete!" -ForegroundColor Green
    }

    # Always on Top
    Write-Host "Always on Top... " -NoNewLine -ForegroundColor Yellow
    $Success = 0

    try {
        $Source = $Path + "\ConfigFiles\PowerToys\AlwaysOnTop\settings.json"
        $Destination = "$ENV:USERPROFILE\AppData\Local\Microsoft\PowerToys\AlwaysOnTop\settings.json"
        Copy-Item -Path $Source -Destination $Destination -Force        
        $Success = 1
    }
    catch {
        Write-Host "Failed!" -ForegroundColor Red
    }

    if ($Success -eq 1) {
        Write-Host "Complete!" -ForegroundColor Green
    }

    # Restarting PowerToys
    Write-Host "Restarting PowerToys... " -NoNewline -ForegroundColor Yellow
    
    $Process = Get-Process PowerToys

    if ($Process) {
        try {
            . $Process.Path
            Stop-Process -Id $Process.Id
            Write-Host "Sucess!" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed!" -ForegroundColor Red
        }
    }



}

function Set-WindowsTerminalConfigFile {
    Write-Host "Configuring Windows Terminal Config..." -ForegroundColor Green

    $Source = $Path + "\ConfigFiles\WindowsTerminal\settings.json"
    $Destination = "$Env:USERPROFILE\Appdata\local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\"
    Copy-Item -Path $Source -Destination $Destination -Force
}

$WorkOrPrivateInstall = Get-WorkOrPersonal
Set-TempFolder

Install-Applications -AppsToInstall $EssentialAppsToInstall

if($WorkOrPrivateInstall -eq "P") { 
    Install-Applications -AppsToInstall $PrivateAppsToInstall 
}
elseif ($WorkOrPrivateInstall -eq "W") {
    Install-Applications -AppsToInstall $WorkAppsToInstall
    #Install-SysInternals
    #Install-RsatTools
}

# Install-Fonts
# Set-PowershellProfile
# Set-OhMyPosh
# Set-PowerToysConfigFiles
# Set-WindowsTerminalConfigFile
# Set-AutoHotKeyScripts