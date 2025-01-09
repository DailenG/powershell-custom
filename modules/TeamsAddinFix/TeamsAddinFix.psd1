@{
    RootModule = 'TeamsAddinFix.psm1'
    ModuleVersion = '0.2.0'
    GUID = 'f8b92d4b-9c6e-4f25-9b6e-8f5b7c8b0b9b'
    Author = 'Dailen Gunter'
    CompanyName = 'WideData Corporation, Inc.'
    Copyright = '2025'
    Description = 'Fixes Microsoft Teams Meeting Add-in issues after upgrading to new Teams'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = @('Test-TeamsAddinFix', 'Repair-TeamsAddin', 'Test-TeamsAddinRegistry')
    CmdletsToExport = @()
    VariablesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Teams', 'Outlook', 'Add-in', 'Meeting', 'Dailen','WideData')
            ProjectUri = 'https://github.com/DailenG/PS/'
            IconUri = 'https://wdc.help/icons/wam.png'
            ReleaseNotes = 'Initial release'
        }
    }
}
