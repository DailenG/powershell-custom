<#
.SYNOPSIS
    Invokes a script block or script file remotely on multiple computers and returns an array of completed job objects.

.DESCRIPTION
    This function allows you to execute a PowerShell script block or a script file on remote computers.
    It verifies the connectivity to each computer before attempting execution, provides feedback on job progress, and returns an array of job objects representing the successfully completed scripts.

.PARAMETER Computers
    An array of computer names or IP addresses to execute the script on.

.PARAMETER ScriptBlock
    The script block to execute remotely. This parameter is mutually exclusive with -Script.

.PARAMETER Script
    The path to the script file to execute remotely. This parameter is mutually exclusive with -ScriptBlock.

.EXAMPLE
    $completedJobs = Invoke-RemoteScript -Computers Computer1,Computer2 -ScriptBlock { Get-ChildItem -Path C:\ }
    $completedJobs | Receive-Job

    This will execute the Get-ChildItem command on Computer1 and Computer2 and then retrieve the results of each completed job.

.EXAMPLE
    $completedJobs = Invoke-RemoteScript -Computers Computer1,Computer2 -Script "C:\MyScript.ps1"
    $completedJobs | Receive-Job

    This will execute the script file MyScript.ps1 on Computer1 and Computer2 and then retrieve the results of each completed job.

.NOTES
    - Ensure that WinRM is properly configured on the target computers for remote execution to work.
    - Be mindful of the security implications of executing scripts remotely. Ensure your scripts are properly secured and only run trusted code.

.OUTPUTS
    An array of completed job objects representing the successfully executed scripts.

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
        $connected = $false
        $addresses = [System.Net.Dns]::GetHostAddresses($computer)
        foreach ($address in $addresses) {
            if (Test-NetConnection -ComputerName $address.IPAddressToString -CommonTCPPort WinRM -InformationLevel Quiet) {
                $connected = $true
                break
            }
        }
        if ($connected) {
            $verified += $computer
        }
    }

    # Create and start jobs on each computer
    $jobs = @()
    foreach ($computer in $verified) {
        try {
            # Determine which parameter was used and invoke accordingly
            if ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
                $job = Invoke-Command -ComputerName $computer -ScriptBlock $ScriptBlock -ArgumentList $computer -AsJob
            } elseif ($PSCmdlet.ParameterSetName -eq 'Script') {
                $job = Invoke-Command -ComputerName $computer -FilePath $Script -ArgumentList $computer -AsJob
            }
            $jobs += $job
        } catch {
            Write-Host "Failed to start job on $computer $_" -ForegroundColor Red
        }
    }

    # Monitor job progress and display status
    do {
        $completedJobs = $jobs | Where-Object {$_.State -eq 'Completed'}
        $completedJobs | ForEach-Object { Write-Host "$($_.Location) has completed" }
        $jobs = $jobs | Where-Object {$_.State -ne 'Completed'}
        Start-Sleep -Seconds 2
    } while ($jobs.Count -gt 0)

    Write-Host "`nAll jobs have completed."

    # Return the array of completed job objects
    return $completedJobs
}