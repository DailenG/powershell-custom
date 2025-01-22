@{
    RootModule           = 'HardwareReadiness.psm1'
    ModuleVersion        = '1.0.2'
    CompatiblePSEditions = @('Desktop', 'Core')
    GUID                 = 'f8b6a46a-fb89-4856-9654-a37543aabd36'
    Author               = 'Dailen Gunter'
    CompanyName          = 'WideData Corporation, Inc.'
    HelpInfoURI          = 'https://github.com/DailenG/PS/tree/main/modules/HardwareReadiness'
    PowerShellVersion    = '5.1'
    RequiredAssemblies   = @()
    NestedModules        = @()
    FunctionsToExport    = @('Get-HardwareReadiness','Get-HardwareReadinessJSON')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    Description          = @'
This module provides functionality to check if a Windows system meets the hardware requirements for Windows 11. Based on Microsoft's official hardware readiness check script (https://aka.ms/HWReadinessScript) with minimal modifications to provide a more PowerShell-friendly interface.

The module checks various hardware requirements including:
- TPM version 2.0
- Secure Boot capability
- CPU compatibility
- Minimum 4GB RAM
- Minimum 64GB storage

Key functions:
- Get-HardwareReadiness: Returns formatted object with script results
- Get-HardwareReadinessJSON: Returns raw JSON results matching original script output

🏴 Questions or suggestions? Message @dailen on X or open an Issue on GitHub
'@

    PrivateData = @{
        PSData = @{
            Tags         = @('Windows11', 'Hardware', 'Readiness', 'Compatibility', 'TPM', 'SecureBoot', 'Dailen', 'WideData')
            ProjectUri   = 'https://github.com/DailenG/PS/tree/main/modules/HardwareReadiness'
            LicenseUri   = 'https://github.com/dgunter/PS/HardwareReadiness/LICENSE'
            IconUri      = 'https://wdc.help/icons/wam.png'
            ReleaseNotes = 'Improved comments and documentation'
            # Prerelease = ''
        }
    }
}
