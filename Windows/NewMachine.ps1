#TODO: Move the variables from Line 17 - 59 to their own files!
#TODO: Prompt User for Git Username
#TODO: Prompt User for Git Email
#TODO: PowerToys needs to have everything else disabled
#TODO: Vim Profile
#TODO: Powershell Profile (Vim Alias, etc)
#TODO: Configure Git
#TODO: Delete Desktop Shortcuts from newly installed applications
#TODO: Request a reboot after

$Global:ProgressPreference = 'SilentlyContinue' # Stops Expand-Archive Loading bars clogging the output
$ProgressPreference = 'SilentlyContinue' # Stops web request loading bars clogging the output
$Path = Split-Path -Path $MyInvocation.MyCommand.Path 
$CommentLine = "##########################################" # TODO: Put comment syntax in a function

# These install on every machine - Work and Personal
$EssentialAppsToInstall = @(
    "Lexikos.AutoHotKey"
    "Git.Git"
    "JanDeDobbeleer.OhMyPosh"
    "Microsoft.Powershell"
    "Microsoft.PowerToys"
    "Microsoft.WindowsTerminal"
    "Microsoft.VisualStudioCode"
    "Vim.Vim"
)

# These only install on Personal machines
$PersonalAppsToInstall = @(
    "BraveSoftware.BraveBrowser"
    "WhatsApp.WhatsApp"
    "Discord.Discord"
    "RoyalApps.RoyalTS"
    "GOG.Galaxy"
    "Valve.Steam"
    "OBSProject.OBSStudio"
    "Microsoft.VisualStudio.2019.Community"
    "Cockos.REAPER"
    "Spotify.Spotify"
)

# These only install on Work machines
$WorkAppsToInstall = @(
    # Nothing here yet!
)

# These are the taskbar shortcuts to be pinned on a personal machine
$PersonalShortcuts = @{
    1 = "$Env:USERPROFILE\AppData\Local\BraveSoftware\Brave-Browser\Application\brave.exe"
    2 = "$Env:USERPROFILE\AppData\Local\BraveSoftware\Brave-Browser\Application\brave.exe mail.google.com"
    3 = "C:\Program Files\Royal TS V6\RoyalTS.exe"
    4 = "$Env:USERPROFILE\AppData\Local\Discord\Update.exe --processStart Discord.exe"
    5 = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe"
    6 = "$ENV:USERPROFILE\AppData\Local\Programs\Microsoft VS Code\Code.exe"
    7 = "C:\Program Files (x86)\GOG Galaxy\GalaxyClient.exe"
    8 = "$ENV:USERPROFILE\AppData\Local\WhatsApp\WhatsApp.exe"
    9 = "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_1.14.1962.0_x64__8wekyb3d8bbwe\wt.exe"
    0 = "" #TODO: Add-TaskBarIcons: Test Spotify - It won't install under Admin Context
}

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
        
        Write-Host "Installing $ApplicationName... " -ForegroundColor Green -NoNewline
        
        if (($CurrentlyInstalled | Select-String -pattern $Application).Matches.Count -eq 0) {
            winget.exe install $Application | Out-Null
            Write-Host "Complete!" -ForegroundColor Green
        }
        else {
            Write-Host "Already Installed!" -ForegroundColor Yellow
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
    Write-Host "Keyboard Manager... " -NoNewLine -ForegroundColor Green
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
    Write-Host "Always on Top... " -NoNewLine -ForegroundColor Green
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
    Write-Host "Restarting PowerToys... " -NoNewline -ForegroundColor Green
    
    $Process = Get-Process PowerToys -ErrorAction SilentlyContinue

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

function Set-TaskBar {
    #TODO: Set-TaskBar: Test on Windows 11 and potentially limit to Win 10
    
    Write-Host "Customising Taskbar..." -ForegroundColor Green -NoNewline

    # Cortana button
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowCortanaButton -Value 0

    # Task View Button (Workspaces)
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

    # Search bar and button
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0
    
    #TODO: Uncomment Out Hide TaskBar when done
    # Hide Taskbar when not in use
    # $Property = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3").Settings
    # 
    # Property is weird hex, have to change one value in the hex but leave the rest
    # $Property[8] = 3
    # 
    # Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name Settings -Value $Property
    
    # Weather/News Feed - If explorer is running the registry change won't stick 
    $Attempt = 0

    do {
        (Get-Process -Name explorer).kill()
        Start-Sleep -Seconds 1

        if (Get-Process -Name explorer -ErrorAction SilentlyContinue) {
            # Sometimes Explorer restarts itself after being closed...
            $Attempt += 1
        }        
        else {
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2
            $Attempt = 4
        }
    } while ( $Attempt -lt 3 )
    
    explorer.exe
    Write-Host "Done! May take a second to re-appear" -ForegroundColor Green

    if ( $Attempt -eq 3 ) {
        Write-Host "Unable to disable weather bar as Explorer.exe kept restarting automatically. To fix manually right click on Task Bar -> News and Interests -> Turn Off" -ForegroundColor Red
    }
}

function Add-TaskBarIcons {
    param (
        [hashtable]$ShortcutsToPin
    )
    
    Write-Host "Configuring Pinned Task Bar Icons... " -NoNewline -ForegroundColor Green

    # Clear what's currently there:
    Remove-Item -Path "$Env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Force

    # Create shortcuts
    $WshShell = New-Object -ComObject Wscript.Shell
    foreach ($Application in $ShortcutsToPin.Keys) {
        if ($ShortcutsToPin[$Application] -eq "") { Continue }

        $Command = $ShortcutsToPin[$Application] -split '(?<=.exe)\s', 2

        $ProgramPath = $Command[0]
        $Arguments = $Command[1]
        $FileName = "C:\Temp\" + (Split-Path $ProgramPath -LeafBase) 

        if (Test-Path -Path $ProgramPath) {
            $Number = 1
            $FileExists = 1

            do {
                if (Test-Path ($FileName + $Number + ".lnk")) {
                    $Number += 1
                }                
                else {
                    $FileName = $FileName + $Number
                    $FileExists = 0
                }
            } while ( $FileExists -eq 1)

            $Name = Split-Path $FileName -Leaf
            $Shortcut = $WshShell.CreateShortcut("C:\Temp\" + $Name + ".lnk" )
            $Shortcut.TargetPath = $ProgramPath
            $Shortcut.Arguments = $Arguments
            $Shortcut.Save()
        }
    }

    # Move them into place
    Move-Item -Path "c:\temp\*.lnk" -Destination "$Env:Appdata\Microsoft\Internet Explorer\Quick Launch\User Pinned\Taskbar\"

    # TODO: Add-TaskBarIcons: Needs to make a function which will save a copy of the registry (to speed up any changes in the future)
    # TODO: Add-TaskBarIcons: You've hardcoded the personal registry here! How do we make this dynamic between Personal and Work?
    
    # Import Registry Key which connects to the shortcuts
    $RegKey = Get-Content ($Path + "\RegistryKeys\PinnedIcons_Personal.bytes") -AsByteStream
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TaskBand" -Name "Favorites" -Value $RegKey

    Write-Host "Complete!" -ForegroundColor Green
    Write-Host "Refreshing TaskBar..." -NoNewline -ForegroundColor Green

    Get-Process explorer | Stop-Process

    Start-Sleep -Seconds 2

    try {
        Get-Process explorer | Out-Null
    }
    catch {
        Start-Process explorer.exe | Out-Null
    }

    Write-Host "Complete!" -ForegroundColor Green
}

$WorkOrPersonal = Get-WorkOrPersonal
Set-TempFolder
Set-TaskBar

Install-Applications -AppsToInstall $EssentialAppsToInstall
 
if($WorkOrPersonal -eq "P") { 
    Install-Applications -AppsToInstall $PersonalAppsToInstall
    Add-TaskBarIcons -ShortcutsToPin $PersonalShortcuts
}
elseif ($WorkOrPersonal -eq "W") {
    Install-Applications -AppsToInstall $WorkAppsToInstall
    Install-SysInternals
    Install-RsatTools
    Add-TaskBarIcons "W"
}

Install-Fonts
Set-PowershellProfile
Set-OhMyPosh
Set-PowerToysConfigFiles
Set-WindowsTerminalConfigFile
et-AutoHotKeyScripts