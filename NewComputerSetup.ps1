function New-ComputerSetup {
    $Logo = @"
 _   _                 _____                             _              _____      _               
| \ | |               /  __ \                           | |            /  ___|    | |              
|  \| | _____      __ | /  \/ ___  _ __ ___  _ __  _   _| |_ ___ _ __  \  --.  ___| |_ _   _ _ __  
| .   |/ _ \ \ /\ / / | |    / _ \| '_   _ \| '_ \| | | | __/ _ \ '__|   --  \/ _ \ __| | | | '_ \ 
| |\  |  __/\ V  V /  | \__/\ (_) | | | | | | |_) | |_| | ||  __/ |    /\__/ /  __/ |_| |_| | |_) |
\_| \_/\___| \_/\_/    \____/\___/|_| |_| |_| .__/ \__,_|\__\___|_|    \____/ \___|\__|\__,_| .__/ 
                                            | |                                             | |    
                                            |_|                                             |_|    
"@

    Write-Host "$Logo" -ForegroundColor Green
    # Check computer is running as admin
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if(!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Host "User is not running as Admin. Please rerun this with Administrator Priveleges." -ForegroundColor Red
        return
    }

    Write-Host "User is running as Admin, continuing..." -ForegroundColor Green
    
    Write-Host "Gathering computer information..." -ForegroundColor Green
    $ComputerInfo = Get-ComputerInfo
    
    $OsIsWindows = $false
    if($ComputerInfo.OsName -like "*Windows*"){
        Write-Host "Windows OS detected." -ForegroundColor Green
        $OsIsWindows = $true
    }

    if($OsIsWindows)
    {
        Write-Host "Checking Windows version..." -ForegroundColor Green

        #TODO: 3. Cater for Windows 12...
        $Win11 = $false

        if ($Computerinfo.OsName -like "* 11 *") {
            Write-Host "Windows 11 detected." -ForegroundColor Green
            $Win11 = $true
        }
        else {
            Write-Error "OS version not found."
            return
        }
        
        # Set folder
        $Path = $PSScriptRoot
        Set-Location -Path $Path

        if ($Win11) {
            Install-Fonts -FontFolder ".\Windows\Fonts\Hack NF\"
            Copy-ConfigFiles -ImportFile ".\Windows\ConfigFiles\ConfigFiles.json"
            Start-Winget -ImportFile ".\Windows\ConfigFiles\WinGet\win11-personal.txt"
            
            Write-Host "All tasks complete!" -ForegroundColor Green
            Write-Host "Restarting Computer in five seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            Restart-Computer -Force
        }
    }
    
    # TODO: 3. If Linux
}

function Start-Winget {
    param (
        [string]$ImportFile
    )
        
    Write-Host "Installing Applications with Winget." -ForegroundColor Green
    # Check Winget exists...
    where.exe winget.exe 2> Out-Null
    
    if($LASTEXITCODE -ne 0){
        Write-Error "Winget.exe not found, exiting."
        return
    }
    
    winget.exe import $ImportFile
}

function Install-Fonts {
    param (
        [string]$FontFolder
    )

    Write-Host "Installing fonts." -ForegroundColor Green
    $Fonts = Get-Childitem -Path $FontFolder -Filter "*.ttf"

    foreach ($Font in $Fonts) {
        (New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere($Font.FullName, 0x14)
    }
}

function Copy-ConfigFiles {
    param (
        [string]$ImportFile
    )
    
    Write-Host "Copy config files." -ForegroundColor Green

    if(!(Test-Path -Path $ImportFile)){
        Write-Error "$ImportFile doesn't exist"
        return
    }

    $Content = Get-Content -Path $ImportFile
    $Content = $Content | ConvertFrom-Json

    foreach ($Entry in $Content) {
        $Prefix = [System.Environment]::ExpandEnvironmentVariables($Entry.PrefixVariable)
        $Destination = $Prefix + $Entry.Destination
        Copy-Item -Path $Entry.Source -Destination $Destination
    }

}

New-ComputerSetup