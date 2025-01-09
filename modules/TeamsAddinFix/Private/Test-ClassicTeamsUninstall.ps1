function Test-ClassicTeamsUninstall {
    [CmdletBinding()]
    param()

    $userLocalAppData = [Environment]::GetFolderPath("LocalApplicationData")
    $teamsUpdater = Join-Path -Path $userLocalAppData -ChildPath 'Microsoft\Teams\Update.exe'

    if (Test-Path -Path $teamsUpdater) {
        $process = Start-Process -Filepath $teamsUpdater -ArgumentList "--uninstall -s" -PassThru
        $process.WaitForExit()
        
        if ($process.ExitCode -ne 0) {
            Write-Warning "Classic Teams uninstallation failed with exit code $($process.ExitCode)"
            return $false
        }
        Write-Verbose "Classic Teams uninstallation was successful"
        return $true
    }
    
    Write-Verbose "Classic Teams installation not found"
    return $true
}
