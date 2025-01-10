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

        # Check if add-in is currently installed
        $addinInstalled = $false
        $addInPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{731F6BAA-A986-45A4-8936-7C3AAAAA760B}"
        if (-not (Test-Path $addInPath)) {
            $addInPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{731F6BAA-A986-45A4-8936-7C3AAAAA760B}"
            if (Test-Path $addInPath) {
                $addinInstalled = $true
            }
        }
        else {
            $addinInstalled = $true
        }

        if (-not $addinInstalled) {
            Write-Output "Teams Meeting Add-in not found in installed programs. Proceeding with cleanup..."
            Remove-TeamsAddinTraces
            return $true
        }

        Write-Output "MSI Path: $tmaMsiPath"
        $logPath = Join-Path $env:TEMP "tma-uninstall.log"
        
        Write-Output "Starting uninstallation process..."
        $process = Start-Process -FilePath "msiexec.exe" `
            -ArgumentList "/x{731F6BAA-A986-45A4-8936-7C3AAAAA760B} /qn /norestart /l*v `"$logPath`"" `
            -PassThru -Wait -ErrorAction Stop

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1605) {
            Write-Output "Uninstallation completed. Performing cleanup..."
            Remove-TeamsAddinTraces
            return $true
        }

        Write-Warning "Uninstall returned exit code: $($process.ExitCode). Attempting MSI-based uninstall..."
        $process = Start-Process -FilePath "msiexec.exe" `
            -ArgumentList "/x `"$tmaMsiPath`" /qn /norestart /l*v `"$logPath`"" `
            -PassThru -Wait -ErrorAction Stop

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1605) {
            Write-Output "MSI uninstallation completed. Performing cleanup..."
            Remove-TeamsAddinTraces
            return $true
        }

        Write-Error "Uninstallation failed with exit code: $($process.ExitCode). Check log: $logPath"
        return $false
    }
    catch {
        Write-Error "Uninstallation error: $_"
        return $false
    }
}
