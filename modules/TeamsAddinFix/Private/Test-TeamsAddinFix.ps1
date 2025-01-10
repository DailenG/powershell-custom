function Test-TeamsAddinFix {
    [CmdletBinding()]
    param()

    $addinPath = "HKCU:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.TeamsAddin"
    $isAddinPresent = Test-Path $addinPath
    $newTeamsInstalled = Get-AppxPackage -Name MSTeams

    return @{
        AddinPresent = $isAddinPresent
        NewTeamsInstalled = ($null -ne $newTeamsInstalled)
        NeedsFix = (-not $isAddinPresent -and $null -ne $newTeamsInstalled)
    }
}
