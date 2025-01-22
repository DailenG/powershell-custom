function Get-HardwareReadiness {
    <#
    .SYNOPSIS
    Checks if the current system meets Windows 11 hardware requirements.

    .DESCRIPTION
    Performs a comprehensive check of system hardware to determine Windows 11 compatibility.
    Returns results in an easily consumable object format. Based on Microsoft's official
    hardware readiness check script (https://aka.ms/HWReadinessScript).

    .EXAMPLE
    Get-HardwareReadiness

    Returns:
    IsCapable  : True
    Result     : CAPABLE
    Reason     : 
    Details    : Storage: OSDiskSize=929GB. PASS; Memory: System_Memory=32GB. PASS; TPM: TPMVersion=2.0, 0, 1.59. PASS; 
                 Processor: Compatible. PASS; SecureBoot: Enabled. PASS;
    ReturnCode : 0

    .OUTPUTS
    [PSCustomObject] with the following properties:
    - IsCapable: Boolean indicating if system meets requirements
    - Result: Overall status (CAPABLE, NOT CAPABLE, etc.)
    - Reason: Detailed reason if not capable
    - Details: Comprehensive check results
    - ReturnCode: Status code (0=success, 1=failure, -1=error)
    #>
    [CmdletBinding()]
    param()

    try {
        [string]$jsonResult = Get-HardwareReadinessJSON

        if ([string]::IsNullOrEmpty($jsonResult)) {
            throw "No result returned from hardware check"
        }

        $resultObject = $jsonResult | ConvertFrom-Json

        return [PSCustomObject]@{
            IsCapable = $resultObject.returnResult -eq 'CAPABLE'
            Result = $resultObject.returnResult
            Reason = $resultObject.returnReason
            Details = $resultObject.logging
            ReturnCode = $resultObject.returnCode
        }
    }
    catch {
        return [PSCustomObject]@{
            IsCapable = $false
            Result = 'ERROR'
            Reason = $_.Exception.Message
            Details = ''
            ReturnCode = -1
        }
    }
}
