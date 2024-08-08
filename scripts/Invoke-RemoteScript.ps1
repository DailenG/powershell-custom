<#
.SYNOPSIS
    Invokes a script block or script file remotely on multiple computers.

.DESCRIPTION
    This function allows you to execute a PowerShell script block or a script file on remote computers.
    It verifies the connectivity to each computer before attempting execution and provides feedback on job progress.

.PARAMETER Computers
    An array of computer names or IP addresses to execute the script on.

.PARAMETER ScriptBlock
    The script block to execute remotely. This parameter is mutually exclusive with -Script.

.PARAMETER Script
    The path to the script file to execute remotely. This parameter is mutually exclusive with -ScriptBlock.

.EXAMPLE
    Invoke-RemoteScript -Computers Computer1,Computer2 -ScriptBlock { Get-ChildItem -Path C:\ }

    This will execute the Get-ChildItem command on Computer1 and Computer2.

.EXAMPLE
    Invoke-RemoteScript -Computers Computer1,Computer2 -Script "C:\MyScript.ps1"

    This will execute the script file MyScript.ps1 on Computer1 and Computer2.

.NOTES
    - Ensure that WinRM is properly configured on the target computers for remote execution to work.
    - Be mindful of the security implications of executing scripts remotely. Ensure your scripts are properly secured and only run trusted code.

.OUTPUTS
    Displays the status of each job and a final message indicating completion.

#>

function Invoke-RemoteScript {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Computers,
        [Parameter(Mandatory = $true, ParameterSetName = 'ScriptBlock')]
        [ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory = $true, ParameterSetName = 'Script')]
        [string] $Script
    )

    # Ensure only one of -Script or -ScriptBlock is specified
    if ($PSCmdlet.ParameterSetName -eq 'ScriptBlock' -and $Script) {
        throw "You cannot specify both -Script and -ScriptBlock parameters."
    }
    if ($PSCmdlet.ParameterSetName -eq 'Script' -and $ScriptBlock) {
        throw "You cannot specify both -Script and -ScriptBlock parameters."
    }

    # Verify connectivity to each computer
    $verified = @()
    foreach ($computer in $Computers) {
        if (Test-NetConnection $computer -CommonTCPPort WinRM -InformationLevel Quiet) {
            $verified += $computer
        }
    }

    $computers = $verified

    # Create and start jobs on each computer
    $jobs = @{}
    foreach ($computer in $computers) {
        try {
            # Determine which parameter was used and invoke accordingly
            if ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
                $jobs[$computer] = Invoke-Command -ComputerName $computer -ScriptBlock $ScriptBlock -ArgumentList $computer -AsJob
            } elseif ($PSCmdlet.ParameterSetName -eq 'Script') {
                $jobs[$computer] = Invoke-Command -ComputerName $computer -FilePath $Script -ArgumentList $computer -AsJob
            }
        } catch {
            Write-Host "Failed to start job on $computer $_" -ForegroundColor Red
        }
    }

    # Monitor job progress and display status
    do {
        $newJobs = @{}
        foreach ($key in $jobs.Keys) {
            $job = $jobs[$key]
            if ($job.State -eq 'Completed') {
                Write-Host "$key has completed"
            } else {
                $newJobs[$key] = $job
            }
        }
        $jobs = $newJobs
        Start-Sleep -Seconds 2
    } while ($jobs.Count -gt 0)

    Write-Host "`nAll jobs have completed."
}