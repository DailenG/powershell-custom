function Repair-TeamsAddin {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ForceCleanup
    )

    Write-Output "Starting Teams Add-in repair process..."
    
    # Check Teams installation type first
    $teamsInfo = Get-TeamsInstallType
    if (-not $teamsInfo.InstallPath) {
        Write-Error "No Teams installation found. Please install Teams first."
        return $false
    }

    Write-Output "Detected Teams $(if ($teamsInfo.IsStore) {'Microsoft Store'} else {'Traditional'}) installation"
    
    $status = Test-TeamsAddinFix
    $registryStatus = Test-TeamsAddinRegistry
    
    # If add-in shows as present but registry is incomplete, force cleanup
    if ($status.AddinPresent -and -not $registryStatus.IsComplete) {
        Write-Output "Detected partially installed add-in, initiating cleanup..."
        $ForceCleanup = $true
    }

    if ($ForceCleanup) {
        Write-Output "Performing full cleanup of Teams Meeting Add-in..."
        Remove-TeamsAddinTraces
        $status.NeedsFix = $true  # Force repair process
    }

    if (-not $status.NeedsFix -and -not $ForceCleanup) {
        Write-Output "No repair needed. Add-in status: Present=$($status.AddinPresent), New Teams=$($status.NewTeamsInstalled)"
        return $true
    }

    # Check for running processes
    $teamsRunning = Get-Process -Name "ms-teams" -ErrorAction SilentlyContinue
    $outlookRunning = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
    
    # Process closing section updated for Store app
    if ($teamsRunning -or $outlookRunning) {
        Write-Output "The repair process needs to close the following applications:"
        if ($teamsRunning) { 
            Write-Output "- Microsoft Teams $(if ($teamsInfo.IsStore) {'(Store App)'} else {''})" 
        }
        if ($outlookRunning) { Write-Output "- Microsoft Outlook" }
        
        $confirmation = Read-Host "Do you want to continue? (Y/N)"
        if ($confirmation -ne 'Y') {
            Write-Output "Repair process cancelled by user."
            return $false
        }

        if ($outlookRunning) {
            Write-Output "Closing Outlook..."
            $outlookRunning | Stop-Process -Force
        }
        if ($teamsRunning) {
            Write-Output "Closing Teams..."
            $teamsRunning | Stop-Process -Force
        }
        
        # Wait for processes to fully close
        Start-Sleep -Seconds 2
    }

    Write-Verbose "Performing add-in uninstallation and cleanup"
    $addinUninstalled = Test-AddinUninstall
    if (-not $addinUninstalled) {
        Write-Error "Failed to uninstall Teams meeting add-in"
        return $false
    }

    Write-Output "Please start Teams and wait for it to fully load."
    Write-Output "Press Enter once Teams is running..."
    Read-Host | Out-Null

    # Monitor for Teams process
    Write-Output "Waiting for Teams to start..."
    $teamsDetected = $false
    while (-not $teamsDetected) {
        if (Get-Process -Name "ms-teams" -ErrorAction SilentlyContinue) {
            Write-Output "Teams process detected. Now waiting for add-in registration..."
            $teamsDetected = $true
        }
        Start-Sleep -Seconds 2
    }

    # Monitor registry for add-in registration
    Write-Output "Starting registry monitoring for Teams add-in registration..."
    $timeout = (Get-Date).AddMinutes(2)
    $registered = $false
    $dots = 0

    while ((Get-Date) -lt $timeout -and -not $registered) {
        Write-Host "`rChecking registry for Teams add-in registration$('.' * $dots)   " -NoNewline
        $dots = ($dots + 1) % 4

        $registryStatus = Test-TeamsAddinRegistry
        if ($registryStatus.IsComplete) {
            Write-Host "" # Clear the progress line
            Write-Output "Teams add-in registry entries verified successfully."
            $registered = $true
            break
        }
        Start-Sleep -Seconds 2
    }

    Write-Host "" # Clear the progress line
    if (-not $registered) {
        Write-Output "Teams is running but required registry entries are incomplete:"
        if ($registryStatus.MissingEntries) {
            Write-Output "`nMissing Registry Entries:"
            $registryStatus.MissingEntries | ForEach-Object { Write-Output "- $_" }
        }
        if ($registryStatus.InvalidValues) {
            Write-Output "`nIncorrect Registry Values:"
            $registryStatus.InvalidValues | ForEach-Object { Write-Output "- $_" }
        }
        Write-Output "`nPlease try restarting Teams and running the repair process again."
        
        Write-Output "Would you like to retry the repair process? This will perform a full cleanup. (Y/N)"
        $retryConfirmation = Read-Host
        if ($retryConfirmation -eq 'Y') {
            Write-Output "Restarting repair process with full cleanup..."
            return Repair-TeamsAddin -ForceCleanup
        }
        return $false
    }

    Write-Output "Teams add-in has been registered. Please start Outlook."
    $confirmation = Read-Host "Has the Teams meeting add-in appeared in Outlook? (Y/N)"

    if ($confirmation -eq 'Y') {
        Write-Output "Repair completed successfully!"
        return $true
    }
    else {
        Write-Output "The repair process completed but the add-in is still not working. Additional troubleshooting may be needed."
        return $false
    }
}
