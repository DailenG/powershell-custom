<#
.SYNOPSIS
    Executes a multi-stage script deployment on remote computers.

.DESCRIPTION
    This function orchestrates the execution of multiple scripts on remote computers in a sequential manner. 
    Each script is executed on the computers that successfully completed the previous stage.
    If a script fails on a computer, subsequent scripts are skipped for that computer.

.PARAMETER Computers
    An array of computer names or IP addresses to execute the scripts on.

.PARAMETER Scripts
    A string array of paths to the script files to execute remotely. The scripts will be executed in the order they are specified in the array.

.EXAMPLE
    Invoke-MultiStageRemoteScript -Computers Computer1,Computer2 -Scripts "C:\Stage1.ps1", "C:\Stage2.ps1", "C:\Stage3.ps1"

    This will execute Stage1.ps1 on Computer1 and Computer2. If successful, it will then execute Stage2.ps1 on those computers. Finally, if Stage2.ps1 is successful, it will execute Stage3.ps1.

.NOTES
    - Ensure that WinRM is properly configured on the target computers for remote execution to work.
    - Be mindful of the security implications of executing scripts remotely. Ensure your scripts are properly secured and only run trusted code.

.OUTPUTS
    Displays the status of each job and a final message indicating completion.

#>
function Invoke-MultiStageRemoteScript {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Computers,
        [Parameter(Mandatory = $true)]
        [string[]] $Scripts,
        [Parameter(Mandatory = $false)]
        [switch]$DebugJobs
    )

    $successfulComputers = $Computers

    # Loop through each script in the $Scripts array
    for ($i = 0; $i -lt $Scripts.Count; $i++) {
        $currentScript = $Scripts[$i]
        $stageNumber = $i + 1

        Write-Host "Executing Stage $stageNumber Script: $currentScript"

        # Execute the current script using Invoke-RemoteScript and store the returned jobs
        $stageJobs = Invoke-RemoteScript -Computers $successfulComputers -Script $currentScript

        # Identify successful computers for the next stage
        $successfulComputers = @()
        foreach ($job in $stageJobs) {
            # Check if the job succeeded
            if (-Not(Receive-Job -Job $job -Keep -ErrorAction SilentlyContinue)) { 
                $successfulComputers += $job.Location
            } else {
                Write-Host "Stage $stageNumber script failed on $($job.Location). Skipping subsequent stages." -ForegroundColor Yellow
            }
        }

        # If no computers were successful in the current stage, exit the loop
        if (-not $successfulComputers) {
            Write-Host "No computers succeeded Stage $stageNumber. Exiting script execution." -ForegroundColor Red
            break
        }
    }

    if(-Not($DebugJobs)) {
        Get-Job | Remove-Job
        Write-Output "Any oustanding jobs have been removed".
    } else {
        Write-Output "Jobs retained for debugging."
    }

    Write-Host "Multi-Stage Script Execution Completed."
}