import-module Microsoft.Graph.Authentication
import-module Microsoft.Graph.Identity.SignIns

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
try {
    Write-Output "Removing TAP for $($user.UPN)..."
    $MethodID = (Get-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.UPN).Id

    if((get-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.UPN).Count -eq 1) {
        Remove-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.UPN -TemporaryAccessPassAuthenticationMethodId $MethodID
    }
} catch {
    Write-Warning "Unable to remove TAP for $user.UPN"
    Write-Warning $Error[0].Exception
}

}

Disconnect-MgGraph | Out-Null