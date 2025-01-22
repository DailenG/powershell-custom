# Get module path from test location
$modulePath = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$moduleName = "HardwareReadiness"

# Remove module if loaded
if (Get-Module -Name $moduleName) {
    Remove-Module -Name $moduleName -Force
}

# Import module using manifest
$manifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"
Import-Module $manifestPath -Force -ErrorAction Stop

Describe "HardwareReadiness Module Tests" {
    Context "Module Loading" {
        It "Should import successfully" {
            Get-Module -Name $moduleName | Should Not BeNullOrEmpty
        }
    }

    Context "Public Function Availability" {
        It "Should export Get-HardwareReadiness" {
            Get-Command Get-HardwareReadiness -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should export Get-HardwareReadinessJSON" {
            Get-Command Get-HardwareReadinessJSON -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Function Results" {
        It "Get-HardwareReadinessJSON should return valid JSON" {
            $result = Get-HardwareReadinessJSON
            { $result | ConvertFrom-Json } | Should Not Throw
        }

        It "Get-HardwareReadiness should return expected properties" {
            $result = Get-HardwareReadiness
            $result | Should Not BeNullOrEmpty
            
            # Test each property individually
            ($result.PSObject.Properties.Name -contains 'IsCapable') | Should Be $true
            ($result.PSObject.Properties.Name -contains 'Result') | Should Be $true
            ($result.PSObject.Properties.Name -contains 'Reason') | Should Be $true
            ($result.PSObject.Properties.Name -contains 'Details') | Should Be $true
            ($result.PSObject.Properties.Name -contains 'ReturnCode') | Should Be $true
        }
    }
}
