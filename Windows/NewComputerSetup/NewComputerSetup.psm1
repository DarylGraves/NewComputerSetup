<#
.SYNOPSIS
Reads the modules ConfigFiles.json file

.DESCRIPTION
Reads the modules ConfigFiles.json file

.EXAMPLE
Get-NcConfig
#>
function Get-NcConfig {
    $File = $PSScriptRoot + "\ConfigFiles.json"
    if (!(Test-Path -Path $File)) {
        Write-Error "$File does not exist"
        return
    }

    $Json = (Get-Content $File | ConvertFrom-Json)
    
    $Json
}

<#
.SYNOPSIS
Adds new configurations into the ConfigFiles.json

.DESCRIPTION
Adds new configurations into the ConfigFiles.json

.PARAMETER Name
The name for the Config File

.PARAMETER Source
The location in the Module's Directory for this Config File

.PARAMETER Destination
Where the file should be moved to on the user's machine when running the commands

.EXAMPLE
Add-NcConfig -Name "Windows Terminal" -Source "\ConfigFiles\WindowsTerminal\Settings.json" -Destination "\AppData\Local\Packages\Microsoft.WindowsTerminal_7wekyb3d8bbwe\LocalState\settings.json"

.NOTES
Any source or destination with "appdata" in the path will be stripped to begin at with "appdata. This is to prevent user names from being hard-coded into the config file. 
#>
function Add-NcConfig {
    param (
        [string]$Name,
        [string]$Source,
        [string]$Destination
    )
    
    $Json = Get-NcConfig

    # Validate input - Is the name already in use?
    if (($Json | Where-Object { $_.Name -eq $Name }).Count -gt 0 ) {
        Write-Error "There is already an entry in the config file called '$Name'. To change an existing setting use 'Set-NcConfig', to delete an existing setting use 'Remove-NcConfig'"
        return
    }
    
    # If in Appdata, we don't care about C:\Users\Username as this could vary in different environments
    if ($Source -Match "\\Appdata.*") { $Source = $Matches[0] }
    if ($Destination -Match "\\Appdata.*") { $Destination = $Matches[0] }
    
    $Json += [PSCustomObject]@{
        Name = $Name
        Source = $Source
        Destination = $Destination
    }

    $Json | ConvertTo-Json | Out-File -FilePath ( $PSScriptRoot + "\ConfigFiles.json" )
}

<#
.SYNOPSIS
Amends an existing configuration in the ConfigFiles.json file.

.DESCRIPTION
Amends an existing configuration in the ConfigFiles.json file.

.PARAMETER Name
The name for the Config File

.PARAMETER Source
The location in the Module's Directory for this Config File

.PARAMETER Destination
Where the file should be moved to on the user's machine when running the commands

.EXAMPLE
Set-NcConfig -Name "Windows Terminal" -Source "\ConfigFiles\WindowsTerminal\Settings.json" -Destination "\AppData\Local\Packages\Microsoft.WindowsTerminal_7wekyb3d8bbwe\LocalState\settings.json"
#>
function Set-NcConfig {
    param (
        [string]$Name,
        [string]$Source,
        [string]$Destination
    )
    
    $Json = Get-NcConfig

    if (($Json | Where-Object {$_.Name -eq $Name}).Count -eq 0) {
        Write-Error "There is no entry for $Name to amend."
        return
    }
    
    # If in Appdata, we don't care about C:\Users\Username as this could vary in different environments
    if ($Source -Match "\\Appdata.*") { $Source = $Matches[0] }
    if ($Destination -Match "\\Appdata.*") { $Destination = $Matches[0] }

    $Json = $Json | Where-Object { $_.Name -ne $Name }
    $Json += [PSCustomObject]@{
        Name = $Name
        Source = $Source
        Destination = $Destination
    }

    $Json | ConvertTo-Json | Out-File -FilePath ( $PSScriptRoot + "\ConfigFiles.json" )
}

<#
.SYNOPSIS
Removes an existing configuration from the ConfigFiles.json file.

.DESCRIPTION
Removes an existing configuration from the ConfigFiles.json file.

.PARAMETER Name
The name for the Config File

.PARAMETER Source
The location in the Module's Directory for this Config File

.PARAMETER Destination
Where the file should be moved to on the user's machine when running the commands

.EXAMPLE
Remove-NcConfig -Name "Windows Terminal" -Source "\ConfigFiles\WindowsTerminal\Settings.json" -Destination "\AppData\Local\Packages\Microsoft.WindowsTerminal_7wekyb3d8bbwe\LocalState\settings.json"
#>
function Remove-NcConfig {
    param (
        [string]$Name
    )
    
    $Json = Get-NcConfig

    if ( ($Json | Where-Object { $_.Name -ne $Name } ).Count -lt 1) {
        Write-Error "There is no entry for $Name to remove."
        return
    }

    $Json = ($Json | Where-Object { $_.Name -ne $Name } )

    $Json | ConvertTo-Json | Out-File -FilePath ( $PSScriptRoot + "\ConfigFiles.json" )
}