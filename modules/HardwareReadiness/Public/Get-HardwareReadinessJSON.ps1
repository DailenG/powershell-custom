function Get-HardwareReadinessJSON {
    <#
    .SYNOPSIS
    Returns raw JSON results of Windows 11 hardware compatibility check.

    .DESCRIPTION
    Performs detailed hardware compatibility checks for Windows 11 requirements
    including TPM, SecureBoot, CPU, Memory, and Storage requirements.
    Returns results in JSON format matching the original Microsoft script output.

    .EXAMPLE
    Get-HardwareReadinessJSON

    Returns:
    {
        "returnCode": 0,
        "returnReason": "",
        "logging": "Storage: OSDiskSize=929GB. PASS; Memory: System_Memory=32GB. PASS; TPM: TPMVersion=2.0, 0, 1.59. PASS; 
                   Processor: {AddressWidth=64; MaxClockSpeed=1400; NumberOfLogicalCores=22; Manufacturer=GenuineIntel;
                   Caption=Intel64 Family 6 Model 170 Stepping 4; }. PASS; SecureBoot: Enabled. PASS; ",
        "returnResult": "CAPABLE"
    }

    .NOTES
    Based on Microsoft's hardware readiness check script: https://aka.ms/HWReadinessScript
    #>
    [CmdletBinding()]
    param()

    # Constants
    [int]$MinOSDiskSizeGB = 64
    [int]$MinMemoryGB = 4
    [Uint32]$MinClockSpeedMHz = 1000
    [Uint32]$MinLogicalCores = 2
    [Uint16]$RequiredAddressWidth = 64

    $PASS_STRING = "PASS"
    $FAIL_STRING = "FAIL"
    $FAILED_TO_RUN_STRING = "FAILED TO RUN"
    $UNDETERMINED_CAPS_STRING = "UNDETERMINED"
    $UNDETERMINED_STRING = "Undetermined"
    $CAPABLE_STRING = "Capable"
    $NOT_CAPABLE_STRING = "Not capable"
    $CAPABLE_CAPS_STRING = "CAPABLE"
    $NOT_CAPABLE_CAPS_STRING = "NOT CAPABLE"
    $STORAGE_STRING = "Storage"
    $OS_DISK_SIZE_STRING = "OSDiskSize"
    $MEMORY_STRING = "Memory"
    $SYSTEM_MEMORY_STRING = "System_Memory"
    $GB_UNIT_STRING = "GB"
    $TPM_STRING = "TPM"
    $TPM_VERSION_STRING = "TPMVersion"
    $PROCESSOR_STRING = "Processor"
    $SECUREBOOT_STRING = "SecureBoot"
    $I7_7820HQ_CPU_STRING = "i7-7820hq CPU"

    # Log format strings
    $logFormat = '{0}: {1}={2}. {3}; '
    $logFormatWithUnit = '{0}: {1}={2}{3}. {4}; '
    $logFormatReturnReason = '{0}, '
    $logFormatException = '{0}; '
    $logFormatWithBlob = '{0}: {1}. {2}; '

    # Reset output object
    $script:outObject = @{
        returnCode = -2
        returnResult = $FAILED_TO_RUN_STRING
        returnReason = ""
        logging = ""
    }

    try {
        # Check Storage
        $osDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
        $osDriveSize = [math]::Round($osDrive.Size / 1GB)
        
        if ($osDriveSize -ge $MinOSDiskSizeGB) {
            $script:outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, $osDriveSize, $GB_UNIT_STRING, $PASS_STRING
            UpdateReturnCode 0
        } else {
            $script:outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, $osDriveSize, $GB_UNIT_STRING, $FAIL_STRING
            $script:outObject.returnReason += $logFormatReturnReason -f "Insufficient disk space"
            UpdateReturnCode 1
        }

        # Check Memory
        $memory = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $memoryGB = [math]::Round($memory.Sum / 1GB)
        
        if ($memoryGB -ge $MinMemoryGB) {
            $script:outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, $memoryGB, $GB_UNIT_STRING, $PASS_STRING
            UpdateReturnCode 0
        } else {
            $script:outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, $memoryGB, $GB_UNIT_STRING, $FAIL_STRING
            $script:outObject.returnReason += $logFormatReturnReason -f "Insufficient memory"
            UpdateReturnCode 1
        }

        # Check TPM
        try {
            $tpm = Get-Tpm

            if ($null -eq $tpm) {
                UpdateReturnCode -ReturnCode 1
                $script:outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                $script:outObject.logging += $logFormatWithBlob -f $TPM_STRING, "TPM is null", $FAIL_STRING
            }
            elseif ($tpm.TpmPresent) {
                $tpmVersion = Get-WmiObject -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm | 
                             Select-Object -Property SpecVersion

                if ($null -eq $tpmVersion.SpecVersion) {
                    UpdateReturnCode -ReturnCode 1
                    $script:outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $script:outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, "null", $FAIL_STRING
                }

                $majorVersion = $tpmVersion.SpecVersion.Split(",")[0] -as [int]
                if ($majorVersion -lt 2) {
                    UpdateReturnCode -ReturnCode 1
                    $script:outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $script:outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $FAIL_STRING
                }
                else {
                    $script:outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $PASS_STRING
                    UpdateReturnCode -ReturnCode 0
                }
            }
            else {
                if ($tpm.GetType().Name -eq "String") {
                    UpdateReturnCode -ReturnCode -1
                    $script:outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
                    $script:outObject.logging += $logFormatException -f $tpm
                }
                else {
                    UpdateReturnCode -ReturnCode 1
                    $script:outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $script:outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpm.TpmPresent), $FAIL_STRING
                }
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $script:outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $script:outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
        }

        # Check Processor
        $processor = Get-CimInstance -ClassName Win32_Processor
        $cpuCheck = [CpuFamily]::Validate($processor.Manufacturer, $processor.Architecture)
        
        $cpuDetailsLog = "{AddressWidth=$($processor.AddressWidth); MaxClockSpeed=$($processor.MaxClockSpeed); NumberOfLogicalCores=$($processor.NumberOfLogicalProcessors); Manufacturer=$($processor.Manufacturer); Caption=$($processor.Caption); $($cpuCheck.Message)}"
        
        if ($cpuCheck.IsValid -and 
            $processor.AddressWidth -eq $RequiredAddressWidth -and 
            $processor.NumberOfCores -ge $MinLogicalCores -and 
            $processor.MaxClockSpeed -ge $MinClockSpeedMHz) {
            $script:outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, $cpuDetailsLog, $PASS_STRING
            UpdateReturnCode 0
        } else {
            $script:outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, $cpuDetailsLog, $FAIL_STRING
            $script:outObject.returnReason += $logFormatReturnReason -f "Processor not compatible"
            UpdateReturnCode 1
        }

        # Check SecureBoot
        try {
            $secureBoot = Confirm-SecureBootUEFI
            if ($secureBoot) {
                $script:outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, "Enabled", $PASS_STRING
                UpdateReturnCode 0
            } else {
                $script:outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, "Disabled", $FAIL_STRING
                $script:outObject.returnReason += $logFormatReturnReason -f "SecureBoot disabled"
                UpdateReturnCode 1
            }
        } catch {
            $script:outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, "Error", $FAILED_TO_RUN_STRING
            $script:outObject.returnReason += $logFormatException -f $_.Exception.Message
            UpdateReturnCode -1
        }

        # Set final result
        if ($script:outObject.returnCode -eq 0) {
            $script:outObject.returnResult = $CAPABLE_CAPS_STRING
        } elseif ($script:outObject.returnCode -eq 1) {
            $script:outObject.returnResult = $NOT_CAPABLE_CAPS_STRING
        } else {
            $script:outObject.returnResult = $FAILED_TO_RUN_STRING
        }

    } catch {
        $script:outObject.returnReason = $_.Exception.Message
        $script:outObject.returnCode = -1
        $script:outObject.returnResult = $FAILED_TO_RUN_STRING
    }

    # Return JSON result
    $script:outObject | ConvertTo-Json -Compress
}
