<#
.SYNOPSIS
Tests whether the current user is running interactively on the local machine.

.DESCRIPTION
This function checks if the current user's UPN (User Principal Name) does not contain the hostname (in lowercase) of the machine where it's executed. If they match, it's likely a non-interactive session (e.g., scheduled task, remote execution).

.EXAMPLE
PS C:\> Test-Interactive
True  # If the user is logged in interactively on the machine

.EXAMPLE
PS C:\> Test-Interactive
False # If the user is running a script remotely or through a scheduled task

#>

function Test-Interactive {
    # Get the current user's UPN (e.g., 'johndoe@example.com')
    $UPN = whoami /upn

    # Get the hostname of the current machine (e.g., 'DESKTOP-123456')
    $HostName = $ENV:ComputerName

    # Check if the UPN contains the hostname (case-insensitive)
    # Return True if they don't match (interactive session)
    # Return False if they match (non-interactive session)
    return -Not $UPN.Contains($HostName.ToLowerInvariant())
}