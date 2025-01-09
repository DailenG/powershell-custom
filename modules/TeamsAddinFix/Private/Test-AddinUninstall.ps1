function Test-AddinUninstall {
    [CmdletBinding()]
    param()

    try {
        Write-Output "Checking for Teams package..."
        $teamsPackage = Get-AppxPackage -Name MSTeams
        if (-not $teamsPackage) {
            Write-Error "MSTeams package not found"
            return $false
        }

        Write-Output "Preparing for add-in uninstallation..."
        $tmaMsiPath = "{0}\MicrosoftTeamsMeetingAddinInstaller.msi" -f $teamsPackage.InstallLocation
        if (-not (Test-Path $tmaMsiPath)) {
            Write-Error "Teams meeting add-in MSI not found at: $tmaMsiPath"
            return $false
        }

        Write-Output "MSI Path: $tmaMsiPath"
        Write-Verbose "Found Teams meeting add-in MSI at: $tmaMsiPath"
        $logPath = Join-Path $env:TEMP "tma-uninstall.log"
        
        Write-Output "Starting uninstallation process..."
        Write-Verbose "Attempting uninstallation..."
        $process = Start-Process -FilePath "msiexec.exe" `
            -ArgumentList "/x `"$tmaMsiPath`" InstallerVersion=v3 /quiet /l*v `"$logPath`"" `
            -PassThru -Wait -ErrorAction Stop

        if ($process.ExitCode -eq 0) {
            Write-Output "Initial uninstallation completed successfully"
            Write-Verbose "Successfully uninstalled Teams meeting add-in"
            return $true
        }

        Write-Output "Initial uninstall returned exit code: $($process.ExitCode)"
        Write-Verbose "Initial uninstall failed with exit code: $($process.ExitCode)"
        Write-Output "Starting repair attempt..."
        Write-Verbose "Attempting repair and retry..."
        
        $repairLogPath = Join-Path $env:TEMP "tma-uninstall-repair.log"
        $repairProcess = Start-Process -FilePath "msiexec.exe" `
            -ArgumentList "/fav `"$tmaMsiPath`" /quiet /l*v `"$repairLogPath`"" `
            -PassThru -Wait -ErrorAction Stop

        if ($repairProcess.ExitCode -eq 0) {
            Write-Output "Repair completed, attempting final uninstall..."
            Write-Verbose "Repair successful, attempting uninstall again..."
            $retryLogPath = Join-Path $env:TEMP "tma-uninstall-retry.log"
            $retryProcess = Start-Process -FilePath "msiexec.exe" `
                -ArgumentList "/x `"$tmaMsiPath`" /quiet InstallerVersion=v3 /l*v `"$retryLogPath`"" `
                -PassThru -Wait -ErrorAction Stop

            if ($retryProcess.ExitCode -eq 0) {
                Write-Output "Final uninstallation successful"
                Write-Verbose "Retry uninstallation successful"
                return $true
            }
            
            Write-Error "Final uninstallation failed (Exit: $($retryProcess.ExitCode)). Log: $retryLogPath"
        }
        else {
            Write-Error "Repair failed (Exit: $($repairProcess.ExitCode)). Log: $repairLogPath"
        }
        
        return $false
    }
    catch {
        Write-Error "Uninstallation error: $_"
        Write-Error "Failed to uninstall Teams meeting add-in: $_"
        return $false
    }
}
