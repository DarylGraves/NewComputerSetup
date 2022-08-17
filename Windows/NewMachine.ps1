# Global Variables
$Global:ScriptPath = Split-Path -Path $MyInvocation.MyCommand.Path
$Global:OperatingSystem = (
            (Get-CimInstance -ClassName Win32_OperatingSystem).Caption |
            Select-String "Windows \d\d").Matches.Value

$FontsFile = $Global:ScriptPath + "\Customisations\FontsToInstall.txt"
$AppsEssentialsFile = $Global:ScriptPath + "\Customisations\App_Essentials.txt"
$AppsPersonalFile = $Global:ScriptPath + "\Customisations\App_Personal.txt"
$ConfigsFile = $Global:ScriptPath + "\Customisations\ConfigFiles.json"

# Global Variable Debugging
Write-Debug "Script running from $ScriptPath"
Write-Debug "OS detected: $Global:OperatingSystem"
Write-Debug "Essential Apps Path: $Apps_EssentialsFile"
Write-Debug "Personal Apps Path: $Apps_PersonalFile"

# Validation Steps
if ($null -eq $Global:OperatingSystem) {
    Write-Error "This script will only run on Windows machines." 
    Exit
}

try {
    Get-Command winget -ErrorAction SilentlyContinue | Out-Null
}
catch {
    Write-Error "The machine is currently missing winget.exe - Please run all Windows Updates first and then re-run."
    Exit
}

# Functions
function Set-TempFolder {
    if ((Test-Path "C:\temp") -ne $true) {
        New-Item -Path "C:\temp" -ItemType Directory | Out-Null
    }

    Set-Location -Path "C:\temp"
}

function Install-Fonts {
    param(
        [String]$FromFile
    )
    Write-Host "Installing Fonts..." -ForegroundColor Green

    $FontUrls = Get-Content -Path $FromFile | Where-Object { $_[0] -ne "#" -and $null -ne $_[0] }
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

function Install-Applications {
    param (
        [String]$FromFile
    )
    
    if ((Test-Path -Path $FromFile -ErrorAction SilentlyContinue) -ne $True) {
        Write-Error "The following path doesn't exist: $($FromFile)"
        return
    }

    $AppsToInstall = Get-Content -Path $FromFile | Where-Object { $_[0] -ne "#" -and $null -ne $_[0] }
    $CurrentlyInstalled = winget.exe list
        
    foreach ($Application in $AppsToInstall) {
        $ApplicationName = $Application.Split(".")[1]
        
        Write-Host "Installing $ApplicationName... " -ForegroundColor Green -NoNewline
        
        if (($CurrentlyInstalled | Select-String -pattern $Application).Matches.Count -eq 0) {
            try {
                winget.exe install $Application | Out-Null
                Write-Host "Complete!" -ForegroundColor Green   
            }
            catch {
                Write-Host "Error occured..." -ForegroundColor Red
            }
        }
        else {
            Write-Host "Already Installed!" -ForegroundColor Yellow
        }
    }
}

function Copy-Configurations {
    param (
        [string]$FromFile
    )
    
    if ((Test-Path $FromFile) -eq $False) {
        Write-Error "Path cannot be found!"
        return
    }

    $ConfigSettings = Get-Content $FromFile | ConvertFrom-Json

    foreach ($ConfigFile in $ConfigSettings) {
        Write-Debug $ConfigFile.Name
        
        $Source = $ConfigFile.Source.Replace("...", $Global:ScriptPath)
        $Destination = $ConfigFile.Destination.Replace("...", $ENV:USERPROFILE)

        Write-Debug "   Copying from: $Source"
        Write-Debug "   Copying to: $Destination"

        if (Test-Path $Source) {
            try {
                Copy-Item -Path $Source -Destination $Destination -Force
            }
            catch {
                Write-Error "Error occured!"
            }
        }
        else {
            Write-Error "Source file doesn't exist!"
        }
    }

    $AppsToRestart = ($ConfigSettings | Select-Object Application -Unique).Application

    foreach ($Application in $AppsToRestart) {
        try {
            if ($Application -ne "") {
                Write-Debug "Restarting $Application"
                $Process = Get-Process $Application -ErrorAction SilentlyContinue
    
                if ($Process) {
                    Stop-Process -Id $Process.Id
                    . $Process.Path
                }
            }
        }
        catch {
            Write-Error "An error occured restarting Appplication"
        }   
    }
}

function Set-Taskbar {
    switch ($Global:OperatingSystem) {
        "Windows 10" { 
            Set-Windows10TaskBar
         }
        "Windows 11" {  
            #TODO: Windows 11 Taskbar
            Write-Debug "Nothing for Windows 11 yet"
        }
    }
}

function Set-Windows10TaskBar {
    # TODO: This requires testing as copied straight out of old code.
    Write-Debug "Setting Windows 10 TaskBar"

    # Cortana button
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowCortanaButton -Value 0

    # Task View Button (Workspaces)
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

    # Search bar and button
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0
    
    # Hide Taskbar when not in use
    $Property = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3").Settings
    
    # Property is weird hex, have to change one value in the hex but leave the rest
    $Property[8] = 3
    
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name Settings -Value $Property
    
    # Weather/News Feed - If explorer is running the registry change won't stick 
    $Attempt = 0

    Write-Debug "Restarting Explorer"
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

    if ( $Attempt -eq 3 ) {
        Write-Host "Unable to disable weather bar as Explorer.exe kept restarting automatically. To fix manually right click on Task Bar -> News and Interests -> Turn Off" -ForegroundColor Red
    }
}

# Steps which run
Set-TempFolder
Install-Fonts        -FromFile $FontsFile
Install-Applications -FromFile $AppsEssentialsFile
Install-Applications -FromFile $AppsPersonalFile
Copy-Configurations   -FromFile $ConfigsFile
Set-Taskbar