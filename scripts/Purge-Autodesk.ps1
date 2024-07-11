# Define the versions of AutoCAD and Revit to uninstall
$RemoveVersions = @(
    # @{Name = "Autodesk"; Versions = @("2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025")},
    # @{Name = "AutoCAD"; Versions = @("2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025")},
    # @{Name = "Civil 3D"; Versions = @("2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025")},
    # @{Name = "Revit"; Versions = @("2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025")},
    @{Name = "AutoCAD"; Versions = @("*")},
    @{Name = "Civil 3D"; Versions = @("*")},
    @{Name = "Revit"; Versions = @("*")},
    @{Name = "Autodesk"; Versions = @("*")}
)

# Expanded list of processes to terminate
$processesToKill = @(
    "acad*", "AcEventSync*", "AcQMod*",  # AutoCAD processes
    "revit*",  # Revit processes
    "AdskAccessCore", "AdskAccessUIHost",
    "AdskIdentityManager", "RevitAccelerator"
)

# New array for services
$servicesToHandle = @()
    if(Get-Service "Autodesk Access Service Host" -ErrorAction SilentlyContinue) {
        $servicesToHandle += "Autodesk Access Service Host"
    }

    if(get-service "AdskLicensingService" -ErrorAction SilentlyContinue) {
        $servicesToHandle += "AdskLicensingService"
    }

$DataLocations = @(
    "C:\ProgramData\Autodesk",
    "C:\Users\Public\Documents\Autodesk",
    "C:\Users\*\AppData\Local\Autodesk",
    "C:\Users\*\AppData\Roaming\Autodesk",
    "C:\Users\*\AppData\Local\Temp\Autodesk",
    "C:\Autodesk",
    "C:\Program Files\Autodesk",
    "C:\Program Files\Common Files\Autodesk Shared",
    "C:\Program Files (x86)\Autodesk",
    "C:\Program Files (x86)\Common Files\Autodesk Shared"
)

$RegistryLocations = @(
    "HKCU:\Software\Autodesk",
    "HKLM:\Software\Autodesk",
    "HKU:\*\Software\Autodesk"
)

$todate = (Get-Date -Format 'yyyyMMdd_HHmmss')

$Logs = "C:\temp\ThePurge_$todate"

# Create a log directory
New-Item -ItemType Directory -Path $Logs -Force -ErrorAction SilentlyContinue | Out-Null

# Create a log file
$logFile = "$Logs\_PrimaryLog_.log"

# Add a simple menu screen telling the user what the script does, the remove versions that will be searched and uninstalled, locations that will be purged, registry paths that will be removed, and where the logs can be found
Write-Host "This script will search for and uninstall the following Autodesk products:"
foreach ($product in $RemoveVersions) {
    Write-Host "  $($product.Name) $($product.Versions)"
}

Write-Host "The following locations will be purged:"
foreach ($location in $DataLocations) {
    Write-Host "  $location"
}

Write-Host "The following registry paths will be removed:"
foreach ($location in $RegistryLocations) {
    Write-Host "  $location"
}

Write-Host "Logs will be saved to: $Logs"

$Response = Read-Host "Type Yes to continue..."

if ($Response -ne "Yes") {
    Write-Host "Quitting script..."
    exit
}

function Write-Log {
    param (
        [string]$Message
    )
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Output $logMessage
}

function Stop-AndRemoveService {
    param (
        [string]$ServiceName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if ($service) {
            # Stop the service
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Write-Log "Attempted to stop service: $ServiceName"
            
            # Disable the service
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log "Attempted to disable service: $ServiceName"
            
            # Remove the service
            sc.exe delete $ServiceName 2>&1 | Out-Null
            Write-Log "Attempted to remove service: $ServiceName"
        }
        else {
            Write-Log "Service not found: $ServiceName"
        }
    }
    catch {
        Write-Log "Error occurred while handling service $ServiceName. Error: $($_.Exception.Message)"
    }
}

function Invoke-UninstallAutodeskProduct {
    param (
        [string]$ProductName,
        [string[]]$Versions
    )

    foreach ($version in $Versions) {
        Write-Log "Starting uninstallation of $ProductName $version..."

        foreach ($processName in $processesToKill) {
            Get-Process -Name $processName -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $_ | Stop-Process -Force -ErrorAction SilentlyContinue
                    Write-Log "Stopped process: $($_.Name)"
                } catch {
                    Write-Log "Failed to stop process: $($_.Name). Error: $($_.Exception.Message)"
                }
            }
        }

        # Handle services
        foreach ($serviceName in $servicesToHandle) {
            Stop-AndRemoveService -ServiceName $serviceName
        }

        # Remove reboot requests that might stop un/installations
        $RegRebootRequired = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        Remove-Item -Path $RegRebootRequired -Force -ErrorAction SilentlyContinue
        Write-Log "Removed reboot requests (if any)"

        if($version -eq "*") {
            # Remove all versions
            $packageName = "*$ProductName*"
        } else {
            # Remove specific version
            $packageName = "*$ProductName*$version*"
        }

        $folderRoot = 'C:\Program Files\Autodesk'
        $validExitCodes = @(0, 3010, 1603, 1605, 1614, 1641)

        Get-ItemProperty -Path @('HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') `
                         -ErrorAction:SilentlyContinue `
        | Where-Object   {$_.DisplayName -like $packageName} `
        | ForEach-Object {
            $productCode = $_.PSChildName
            if($productCode -like '{*') {
                $uninstallString = $_.UninstallString
                $msiLogFile = "$Logs\$($_.DisplayName)_uninstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
                
                if ($uninstallString -match '^MsiExec\.exe') {
                    Write-Log "Uninstalling $($_.DisplayName) using msiexec..."
                    $msiArgs = "/x $productCode /qn /norestart /L*v `"$msiLogFile`""
                    $process = Start-Process "msiexec.exe" -ArgumentList $msiArgs -PassThru
                    
                    $zeroCpuTime = $null
                    
                    while (!$process.HasExited) {
                        Start-Sleep -Seconds 30
                        
                        try {
                            $grabProcess = Get-Process -Id $process.Id
                        } catch {
                            Write-Log "Failed to get process, continuing."
                            break
                        }

                        $cpuTime = $grabProcess.CPU
                        
                        if ($cpuTime -eq 0) {
                            if ($null -eq $zeroCpuTime) {
                                $zeroCpuTime = Get-Date
                            } elseif (((Get-Date) - $zeroCpuTime).TotalMinutes -ge 5) {
                                Write-Log "Msiexec process has been idle for more than 5 minutes. Terminating process."
                                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                                Write-Log "Uninstallation of $($_.DisplayName) failed due to inactivity"
                                break
                            }
                        } else {
                            $zeroCpuTime = $null
                        }
                    }
                    
                    $exitCode = $process.ExitCode
                } else {
                    Write-Log "Uninstalling $($_.DisplayName) using custom uninstaller..."
                    $process = Start-Process $uninstallString -ArgumentList "/qn /norestart" -Wait -NoNewWindow -PassThru
                    $exitCode = $process.ExitCode
                }
                
                Write-Log "Uninstaller completed with exit code: $exitCode"
                if ($exitCode -in $validExitCodes) {
                    Write-Log "Uninstallation of $($_.DisplayName) completed successfully"
                } else {
                    Write-Log "Uninstallation of $($_.DisplayName) failed with exit code: $exitCode"
                }
            }
            Remove-Item $_.PsPath -Recurse -Force -ErrorAction Ignore
            Write-Log "Removed registry key: $($_.PsPath)"
        }

        Get-ChildItem $folderRoot -Recurse -Force -Directory -ErrorAction SilentlyContinue -Include $packageName | ForEach-Object {
            $_ | Remove-Item -Recurse -Confirm:$false -Force -ErrorAction SilentlyContinue
            Write-Log "Removed directory: $($_.FullName)"
        }

        Write-Log "Completed uninstallation process for $ProductName $version"
    }
}

# Main execution
Write-Log "Starting Autodesk product uninstallation script"

foreach ($product in $RemoveVersions) {
    Write-Log "Processing $($product.Name)"
    Invoke-UninstallAutodeskProduct -ProductName $product.Name -Versions $product.Versions
}


foreach ($location in $DataLocations) {
    try {
        Remove-Item $location -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed directory: $location"
    } catch {
        Write-Log "Failed to remove directory: $location"
    }
}

New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS\ | Out-Null

$RegistryPaths = @()
foreach ($location in $RegistryLocations) {
    $RegistryPaths += Get-ChildItem $location -Recurse -ErrorAction SilentlyContinue
}

foreach ($path in $RegistryPaths) {
    try {
        Remove-Item $path.PSPath -Force -ErrorAction SilentlyContinue
        Write-Log "Removed registry key: $path"
    } catch {
        Write-Log "Failed to remove registry key: $path"
    }
}

Write-Log "Autodesk product uninstallation script completed"