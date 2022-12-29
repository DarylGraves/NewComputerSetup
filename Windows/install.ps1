$DumbSplashScreen = "
     __                  ___                            _              __      _               
  /\ \ \_____      __   / __\___  _ __ ___  _ __  _   _| |_ ___ _ __  / _\ ___| |_ _   _ _ __  
 /  \/ / _ \ \ /\ / /  / /  / _ \| '_ ` _ \ | '_ \| | | | __/ _ \ '__| \ \ / _ \ __| | | | '_ \ 
/ /\  /  __/\ V  V /  / /__| (_) | | | | | | |_) | |_| | ||  __/ |    _\ \  __/ |_| |_| | |_) |
\_\ \/ \___| \_/\_/   \____/\___/|_| |_| |_| .__/ \__,_|\__\___|_|    \__/\___|\__|\__,_| .__/ 
                                           |_|                                          |_|        
"

Write-Host $DumbSplashScreen -ForegroundColor Green
$ModuleDir = $Env:PSModulePath -split ";" | Where-Object {$_ -like "$ENV:USERPROFILE*" }
$ModuleToInstall = (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) + "\NewComputerSetup\"

# Basic validation on folder
if ($ModuleDir.Count -gt 1) { $ModuleDir = $ModuleDir[0] }
if (!(Test-Path $ModuleDir)) { Write-Error "$ModuleDir does not exist" }
Write-Host "Copying Module from $ModuleToInstall to $ModuleDir... " -ForegroundColor Yellow 

$AnyError = $False
try {
    Copy-Item -Path $ModuleToInstall -Destination $ModuleDir -Recurse -Force
}
catch {
    $AnyError  = $True
    Write-Host "An error occured." -ForegroundColor Red
}

if (!($AnyError)) {
    Write-Host "Success! Restart Powershell for changes to take effect" -ForegroundColor Green
}