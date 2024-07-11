    <#
    .SYNOPSIS
    Uninstalls the Global VPN Client application.

    .DESCRIPTION
    This script will search the uninstall registry keys for the Global VPN Client application.When found, it will execute the uninstall string to uninstall the application.

    It first stops any running processes that start with "SWGVC" to avoid issues uninstalling.

    It searches both 32-bit and 64-bit registry locations for the uninstall information.

    .EXAMPLE
    Uninstall-GlobalVPNClient

    Demonstrates how to find and execute the uninstall command for Global VPN Client.
    #>

function Uninstall-GlobalVPNClient {

    # Stop processes starting with "SWGVC"
    Get-Process | Where-Object { $_.ProcessName -like "SWGVC*" } | Stop-Process -Force

    # Path to the registry location for uninstall commands
    [String[]]$regs = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    $regs += "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    
    $Installs = Get-ChildItem -LiteralPath $regs | where-object { $_.GetValue("DisplayName") -eq "Global VPN Client"}

    If($Installs.Count -eq 1) {
        if ($Installs.GetValue("UninstallString")) {
            if($Installs.GetValue("UninstallString").Contains("MsiExec.exe /X")) {
                $ProductCode = $Installs.GetValue("UninstallString").Replace("MsiExec.exe /X","")
                $cmdArgs = "/x `"$ProductCode`" /qn /norestart /log `"C:\temp\GVC_Uninstall.log`" REMOVE_RCF=1 REMOVE_MAC=1"
                Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList $cmdArgs
            } else {
                Write-Error "No MSIEXEC UninstallString Found"
                exit 1
            }
        } else {
            Write-Host "Uninstall command not found for Global VPN Client."
        }

    } elseif ($Installs.Count -gt 1) {
        Write-Error "Multiple Installations Located."
    } elseif ($Installs.Count -eq 0) {
        Write-Output "No Installations Found."
        exit
    }


}

Uninstall-GlobalVPNClient