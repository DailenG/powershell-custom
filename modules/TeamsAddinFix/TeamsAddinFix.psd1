@{
  
    RootModule           = 'TeamsAddinFix.psm1'
    ModuleVersion        = '1.2.0'
    CompatiblePSEditions = @('Desktop', 'Core')
    GUID                 = 'f8b92d4b-9c6e-4f25-9b6e-8f5b7c8b0b9b'
    Author               = 'Dailen Gunter'
    CompanyName          = 'WideData Corporation, Inc.'
    Copyright            = '(c) All rights reserved.'
    HelpInfoURI          = 'https://github.com/DailenG/PS/tree/main/modules/TeamsAddinFix'
    PowerShellVersion    = '5.1'
    RequiredAssemblies   = @()
    NestedModules        = @()
    FunctionsToExport    = @('Repair-TeamsAddin', 'Test-TeamsAddinRegistry')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    Description          = @'
Attempts to fix Microsoft Teams Meeting Add-in issues after upgrading to new Teams. Just run Repair-TeamsAddin and follow the prompts.

  I got tired of manually trying all sorts of different fixes and compiled the most proven fix and a series of checks into this module. 

  As some of the process requires starting Teams and Outlook in the user context, it automates what it can and guides you through the rest.
  
  🏴 If you have any questions, requests, suggestions etc. about this module, please message me on X @dailen or open an Issue on GitHub

  ⭕ Text formatting shamelessly stolen from https://github.com/HotCakeX/Harden-Windows-Security
  
'@

    PrivateData      = @{
        PSData = @{
            Tags = @('Teams', 'Outlook', 'Add-in', 'Meeting', 'Dailen','WideData')
            ProjectUri = 'https://github.com/DailenG/PS/tree/main/modules/TeamsAddinFix'
            IconUri = 'https://wdc.help/icons/wam.png'
            ReleaseNotes = 'Removed attempt to launch teams as it was launching but for the wrong user context when script run as a different admin user'
            # Prerelease = 'beta'
        }

    }
  }
