# HardwareReadiness PowerShell Module

This module provides functionality to check if a Windows system meets the hardware requirements for Windows 11. It is based on Microsoft's official hardware readiness check script (available at https://aka.ms/HWReadinessScript) with minimal modifications to provide a more PowerShell-friendly interface.

## Functions

### Get-HardwareReadiness

Returns a formatted object with Windows 11 hardware compatibility status.

```powershell
Get-HardwareReadiness
```

Returns:
- IsCapable: Boolean indicating if system meets requirements
- Result: Overall status (CAPABLE, NOT CAPABLE, etc.)
- Reason: Detailed reason if not capable
- Details: Comprehensive check results
- ReturnCode: Status code (0=success, 1=failure, -1=error)

### Get-HardwareReadinessJSON

Returns raw JSON results of hardware compatibility check.

```powershell
Get-HardwareReadinessJSON
```

## Requirements

- PowerShell 5.1 or later
- Windows OS
- Administrative privileges

## Installation

```powershell
# Clone from GitHub
git clone https://github.com/dgunter/PS/HardwareReadiness

# Import module
Import-Module .\HardwareReadiness
```

## License

Based on Microsoft's hardware readiness check script, distributed under MIT license.
