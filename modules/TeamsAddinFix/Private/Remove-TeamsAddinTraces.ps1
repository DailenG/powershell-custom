function Remove-TeamsAddinTraces {
    [CmdletBinding()]
    param()
    
    $cleanupLocations = @{
        RegistryKeys = @(
            "HKCU:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.TeamsAddin",
            "HKCU:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect",
            "HKCU:\SOFTWARE\Classes\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}",
            "HKCU:\SOFTWARE\Classes\Wow6432Node\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}"
        )
        FilePaths = @(
            "$env:LOCALAPPDATA\Microsoft\TeamsMeetingAddin",
            "$env:APPDATA\Microsoft\TeamsMeetingAddin"
        )
    }

    foreach ($key in $cleanupLocations.RegistryKeys) {
        if (Test-Path $key) {
            Write-Verbose "Removing registry key: $key"
            Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    foreach ($path in $cleanupLocations.FilePaths) {
        if (Test-Path $path) {
            Write-Verbose "Removing directory: $path"
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
