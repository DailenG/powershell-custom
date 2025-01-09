# Import Private Functions
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }

# Import Public Functions
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object { . $_.FullName }

# Export Public Functions
Export-ModuleMember -Function 'Test-TeamsAddinFix', 'Repair-TeamsAddin', 'Test-TeamsAddinRegistry'
