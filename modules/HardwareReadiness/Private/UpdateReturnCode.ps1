function UpdateReturnCode {
    <#
    .SYNOPSIS
    Updates the return code of hardware check operations.
    
    .DESCRIPTION
    Internal helper function that manages the return code state based on check results.
    
    .PARAMETER ReturnCode
    The return code to process. Valid values: -2, -1, 0, 1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(-2, 1)]
        [int] $ReturnCode
    )

    Switch ($ReturnCode) {
        0 {
            if ($script:outObject.returnCode -eq -2) {
                $script:outObject.returnCode = $ReturnCode
            }
        }
        1 {
            $script:outObject.returnCode = $ReturnCode
        }
        -1 {
            if ($script:outObject.returnCode -ne 1) {
                $script:outObject.returnCode = $ReturnCode
            }
        }
    }
}
