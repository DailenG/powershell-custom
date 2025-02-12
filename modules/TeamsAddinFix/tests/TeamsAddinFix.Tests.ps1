# Get module path from test location
$modulePath = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$moduleName = "TeamsAddinFix"

# Remove module if loaded
if (Get-Module -Name $moduleName) {
    Remove-Module -Name $moduleName -Force
}

# Import module using manifest
$manifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"
Import-Module $manifestPath -Force -ErrorAction Stop

Describe "TeamsAddinFix Module Tests" {
    Context "Module Loading" {
        It "Should import successfully" {
            Get-Module TeamsAddinFix | Should Not BeNullOrEmpty
        }
    }

    Context "Public Function Availability" {
        It "Should export Repair-TeamsAddin" {
            Get-Command Repair-TeamsAddin -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }

        It "Should export Test-TeamsAddinRegistry" {
            Get-Command Test-TeamsAddinRegistry -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        }
    }

    Context "Private Function Availability" {
        It "Should have Test-TeamsAddinFix as a private function" {
            $module = Get-Module TeamsAddinFix
            $module.Invoke({Get-Command -Name Test-TeamsAddinFix -ErrorAction SilentlyContinue}) | Should Not BeNullOrEmpty
        }
    }
}
