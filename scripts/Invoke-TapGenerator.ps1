import-module Microsoft.Graph.Authentication
import-module Microsoft.Graph.Identity.SignIns


# Timespan in minutes
$timespan = 10080  

try {
    $currentPath = $PWD.ToString()
    Write-Output "Importing UserList.csv from current directory: $currentPath\UserList.csv"
    # Import a simple CSV with one column with a header named UPN, with the list of UPNs
    $users = Import-CSV -Path ".\UserList.csv"
    $userCount = ($users | Measure-Object).Count
    Write-Output "Imported $userCount users"
} catch {
    Write-Error "Unable to import UserList.csv"
    Write-Error $Error[0].Exception
    Exit 1
}

# Creating blank object to add entries to export at the end
$data = @()

try {
    Write-Output "Connecting to Microsoft Graph..."
    # Connect with proper scope needed for this functionality
    Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All", "UserAuthenticationMethod.ReadWrite.All" -ContextScope Process -NoWelcome
} catch {
    Write-Error "Unable to connect to Microsoft Graph"
    Write-Error $Error[0].Exception
    Exit 1
}

foreach ($user in $users) {

# You can't set a TAP for your own account so skipping if that's the current user
if((get-mgcontext).Account -eq $user.UPN) {
    Write-Output "Skipping account $($user.UPN) as authenticated user."
    continue
}

try {
    Write-Output "Creating TAP for $($user.UPN)..."
    $tap = New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.UPN -lifetimeInMinutes $timespan -IsUsable

    If(($tap.TemporaryAccessPass).StartsWith("=")) {
        Write-Output "Regenerating TAP for $($user.UPN)..."
	$tap = New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.UPN -lifetimeInMinutes $timespan -IsUsable
    }

    $data += [PSCustomObject]@{
        User = $user.UPN
        TAP = $tap.TemporaryAccessPass
        Lifetime = $tap.LifetimeInMinutes
    }
} catch {
    Write-Warning "Unable to create TAP for $user.UPN"
    Write-Warning $Error[0].Exception
}

}

    Write-Output "Exporting user data to UserCreds.csv"
    # Export-CSV to current directory
    $data | Export-CSV -Path ".\UserCreds.csv" -NoTypeInformation -Force

Disconnect-MgGraph | Out-Null