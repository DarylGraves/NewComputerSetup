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
        [string]$FileName,
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
        FileName = $FileName
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
        [string]$FileName,
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
        FileName = $FileName
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

<#
.SYNOPSIS
Takes the data from ConfigFiles.json and copies the data from the module directory into the specified locations

.DESCRIPTION
Takes the data from ConfigFiles.json and copies the data from the module directory into the specific locations

.EXAMPLE
Deploy-NcConfig

.NOTES
Overwrites any existing file of the same name.
#>
function Deploy-NcConfig {
    [CmdletBinding()]
    param ()

    $Json = Get-NcConfig
    
    
    foreach ($Entry in $Json) {
        Write-Debug "Beginning $($Entry.Name)"
       
        $Source = [System.IO.Path]::Combine(
            $PSScriptRoot, 
            $Entry.Source.Trim("\"), 
            $Entry.FileName.Trim("\")
        )
    
        $Destination = [System.IO.Path]::Combine(
            $Entry.Destination.Trim("\"), 
            $Entry.FileName.Trim("\")
        )
    
        if ($Destination -like "*AppData*") {
            Write-Debug "AppData destination detected"
            $Destination = $Env:UserProfile + "\" + $Destination
            Write-Debug "Destination is now: $Destination"
        }

        Write-Debug "Planning to copy $Source"
        Write-Debug "to $Destination"

        if (!(Test-Path -Path $Source)) {
            Write-Error -Message "Source: $Source could not be found"
            continue
        }

        if (!(Test-Path -Path (Split-Path $Destination -Parent ))) {
            Write-Error -Message "Destination: $Destination could not be found"
            continue
        }

        Copy-Item -Path $Source -Destination $Destination -Force
    }
}

<#
.SYNOPSIS
Takes the data from ConfigFiles.json and copies the data from the specified locations back to the module directory and then, optionally, to github

.DESCRIPTION
Takes the data from ConfigFiles.json and copies the data from the specified locations back to the module directory and then, optionally, to github

.EXAMPLE
Sync-NcConfig

.NOTES
Prompts for Github but this is a seperate function
#>
function Sync-NcConfig {
    [cmdletbinding()]
    param ()
    
    $Json = Get-NcConfig

    foreach($Entry in $Json) {
        Write-Debug "Beginning $($Entry.Name)"
        
        # Note when we prepare the variables below we are inverting the $Entry.___
        # For example $Source below is $Entry.DESTINATION not $Entry.Source.... Confusing!
    
        $Source = [System.IO.Path]::Combine(
            $Entry.Destination.Trim("\"),
            $Entry.FileName.Trim("\")
        )

        $Destination = [System.IO.Path]::Combine(
            $PSScriptRoot,
            $Entry.Source.Trim("\"),
            $Entry.FileName.Trim("\")
        )

        if ($Source -like "*Appdata*") {
            Write-Debug "AppData Source detected"
            $Source = $Env:UserProfile + "\" + $Source
            Write-Debug "Source is now $Source"
        }
    
        Write-Debug "Planning to copy $Source"
        Write-Debug "to $Destination"
    
        if (!(Test-Path -Path $Source)) {
            Write-Error -Message "Source: $Source could not be found"
            continue
        }
    
        if (!(Test-Path -Path (Split-Path $Destination -Parent ))) {
            Write-Error -Message "Destination: $Destination could not be found"
            continue
        }
    
        Copy-Item -Path $Source -Destination $Destination -Force
    }

    $ValidAnswer = $False
    do {
        $Answer = Read-Host "Files copied, would you like to push to Github? (Y/N)"

        if (($Answer.Count -eq 1) -and
            ($Answer[0] -eq "Y" -or
            $Answer[0] -eq "N" )
        ) {
            $ValidAnswer = $True
            if ($Answer -eq "Y") {
                # TODO: Github
                Write-Host "Github goes here"
            }
        }

    } while ( $ValidAnswer -ne $True ) 
}