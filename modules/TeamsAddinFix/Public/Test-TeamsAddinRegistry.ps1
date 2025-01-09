function Test-TeamsAddinRegistry {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$UserSID
    )

    # Determine user context
    if (-not $UserSID) {
        $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($outlookProcess) {
            Write-Output "Found Outlook process, attempting to determine user context"
            try {
                $process = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($outlookProcess.Id)"
                if ($process) {
                    $owner = $process | Invoke-CimMethod -MethodName GetOwner
                    if ($owner.ReturnValue -eq 0) {
                        $account = New-Object System.Security.Principal.NTAccount($owner.Domain, $owner.User)
                        $UserSID = $account.Translate([System.Security.Principal.SecurityIdentifier]).Value
                        Write-Output "Detected User SID: $UserSID"
                    }
                }
            }
            catch {
                Write-Warning "Could not determine Outlook process owner: $_"
                $UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            }
        }
        
        if (-not $UserSID) {
            Write-Output "Using current user context"
            $UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        }
    }

    $hkuPath = "Registry::HKEY_USERS\$UserSID"
    Write-Output "Checking Teams Add-in registry entries for user context: $UserSID"

    $registryChecks = @{
        "Main Add-in Registration (64-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect"
            Values = @{
                "LoadBehavior" = 3
                "FriendlyName" = "Microsoft Teams Meeting Add-in for Microsoft Office"
                "Description" = "Microsoft Teams Meeting Add-in for Microsoft Office"
            }
        }
        "Main Add-in Registration (32-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Wow6432Node\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect"
            Values = @{
                "LoadBehavior" = 3
                "FriendlyName" = "Microsoft Teams Meeting Add-in for Microsoft Office"
                "Description" = "Microsoft Teams Meeting Add-in for Microsoft Office"
            }
        }
        "COM Class Registration (64-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}"
            Values = @{}
        }
        "COM Class InprocServer32 (64-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\InprocServer32"
            Values = @{
                "ThreadingModel" = "Apartment"
            }
        }
        "COM Class ProgID (64-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\ProgID"
            Values = @{
                "(default)" = "TeamsAddin.FastConnect.1"
            }
        }
        "COM Class VersionIndependentProgID (64-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\VersionIndependentProgID"
            Values = @{
                "(default)" = "TeamsAddin.FastConnect"
            }
        }
        "COM Class TypeLib (64-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\TypeLib"
            Values = @{
                "(default)" = "{C0529B10-073A-4754-9BB0-72325D80D122}"
            }
        }
        "COM Class Version (64-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\Version"
            Values = @{
                "(default)" = "1.0"
            }
        }
        "COM Class Registration (32-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\Wow6432Node\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}"
            Values = @{}
        }
        "COM Class InprocServer32 (32-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\Wow6432Node\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\InprocServer32"
            Values = @{
                "ThreadingModel" = "Apartment"
            }
        }
        "COM Class ProgID (32-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\Wow6432Node\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\ProgID"
            Values = @{
                "(default)" = "TeamsAddin.FastConnect.1"
            }
        }
        "COM Class VersionIndependentProgID (32-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\Wow6432Node\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\VersionIndependentProgID"
            Values = @{
                "(default)" = "TeamsAddin.FastConnect"
            }
        }
        "COM Class TypeLib (32-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\Wow6432Node\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\TypeLib"
            Values = @{
                "(default)" = "{C0529B10-073A-4754-9BB0-72325D80D122}"
            }
        }
        "COM Class Version (32-bit)" = @{
            Path = "$hkuPath\SOFTWARE\Classes\Wow6432Node\CLSID\{19A6E644-14E6-4A60-B8D7-DD20610A871D}\Version"
            Values = @{
                "(default)" = "1.0"
            }
        }
    }

    $results = @{
        IsComplete = $true
        UserContext = $UserSID
        Findings = @()
    }

    foreach ($check in $registryChecks.GetEnumerator()) {
        Write-Output "`nChecking $($check.Key)..."
        
        if (-not (Test-Path $check.Value.Path)) {
            $results.IsComplete = $false
            $results.Findings += [PSCustomObject]@{
                Component = $check.Key
                Status = "Missing"
                Details = "Registry key not found: $($check.Value.Path)"
                Severity = "Error"
            }
            continue
        }

        $values = Get-ItemProperty -Path $check.Value.Path -ErrorAction SilentlyContinue
        foreach ($expectedValue in $check.Value.Values.GetEnumerator()) {
            if ($values.$($expectedValue.Key) -ne $expectedValue.Value) {
                $results.IsComplete = $false
                $results.Findings += [PSCustomObject]@{
                    Component = $check.Key
                    Status = "Invalid"
                    Details = "$($expectedValue.Key) = $($values.$($expectedValue.Key)) (Expected: $($expectedValue.Value))"
                    Severity = "Warning"
                }
            }
            else {
                $results.Findings += [PSCustomObject]@{
                    Component = $check.Key
                    Status = "Valid"
                    Details = "$($expectedValue.Key) = $($expectedValue.Value)"
                    Severity = "Info"
                }
            }
        }
    }

    # Format and display results
    Write-Output "`nTeams Add-in Registry Status Summary:"
    Write-Output "User Context: $($results.UserContext)"
    Write-Output "Overall Status: $(if ($results.IsComplete) { 'Complete' } else { 'Incomplete' })"
    
    $results.Findings | ForEach-Object {
        $color = switch ($_.Severity) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            "Info" { "Green" }
        }
        Write-Host "`n$($_.Component) - $($_.Status)" -ForegroundColor $color
        Write-Host $_.Details
    }

    return $results
}
