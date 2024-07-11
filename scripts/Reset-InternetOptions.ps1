# Load Assembly for UI Automation
Add-Type -AssemblyName System.Windows.Forms

$TeamsProcess = Get-Process *Teams* -ErrorAction SilentlyContinue
$OutlookProcess = Get-Process *Outlook* -ErrorAction SilentlyContinue

# Display a message to ensure all Internet Explorer windows are closed
[System.Windows.Forms.MessageBox]::Show("On the next screen click Reset, no need to delete personal settings. Click CLOSE once the process is complete.", "Reset Internet Options", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null

if ($TeamsProcess.Count -gt 0) 
{
    # Stop Teams process
    Stop-Process $TeamsProcess.Id -Force

    [string]$TeamsPath = $TeamsProcess.Path
}

if ($OutlookProcess.Count -gt 0) 
{
    # Stop Outlook process
    Stop-Process $OutlookProcess.Id -Force    

    [string]$OutlookPath = $OutlookProcess.Path
}


# Reset Internet Explorer settings using the 'Rundll32' command
Start-Process "Rundll32.exe" -ArgumentList "inetcpl.cpl,ResetIEtoDefaults" -Wait

# Display a message indicating completion
[System.Windows.Forms.MessageBox]::Show("Your Internet Options have been reset. Teams and/or Outlook will be restarted if they were closed.", "Reset Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null

if ($TeamsProcess.Count -gt 0) {
    Start-Process $TeamsPath
}

if ($OutlookProcess.Count -gt 0) {
    Start-Process $OutlookPath
}