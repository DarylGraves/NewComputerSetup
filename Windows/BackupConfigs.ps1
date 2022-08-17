# Note this is to collect settings files and move them into the Git Repository for uploading.
# In otherwords, it does the REVERSE of what the Json implies. 
# The Destination is the Source, the Source is the Desination!

# Global Variables
$Global:ScriptPath = Split-Path -Path $MyInvocation.MyCommand.Path

# Action move
$ConfigSettings = Get-Content -Path ($Global:ScriptPath + "\Customisations\ConfigFiles.json") | ConvertFrom-Json

foreach ($ConfigFile in $ConfigSettings) {
    Write-Debug $ConfigFile.Name

    # Destination and Source are reversed intentionally... Not a typo!
    $Source = $ConfigFile.Destination.Replace("...", $ENV:USERPROFILE)
    $Destination = $ConfigFile.Source.Replace("...", $Global:ScriptPath)

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