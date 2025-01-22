[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Test = (-not $Publish),  # Make Test default if no other actions specified
    
    [Parameter()]
    [switch]$Publish,
    
    [Parameter()]
    [string]$ApiKey = $env:PSGALLERY_API_KEY
)

$ErrorActionPreference = 'Stop'
$ModuleName = 'HardwareReadiness'
$ModulePath = $PSScriptRoot
$ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"

function Test-ModuleStructure {
    param([string]$Path)
    
    $requiredFiles = @(
        "$ModuleName.psd1",
        "$ModuleName.psm1",
        "Public",
        "Private",
        "LICENSE",
        "README.md"
    )

    $moduleValid = $true
    Write-Verbose "Checking module structure in: $Path"

    # Check basic structure
    $missingItems = @()
    foreach ($item in $requiredFiles) {
        $itemPath = Join-Path $Path $item
        Write-Verbose "Checking for $itemPath"
        if (-not (Test-Path $itemPath)) {
            $missingItems += $item
            $moduleValid = $false
        }
    }

    # Check public functions
    $publicPath = Join-Path $Path "Public"
    $publicFunctions = Get-ChildItem -Path $publicPath -Filter "*.ps1" -ErrorAction SilentlyContinue
    Write-Verbose "Found $($publicFunctions.Count) public functions"
    if (-not $publicFunctions) {
        $missingItems += "Public/*.ps1 files"
        $moduleValid = $false
    }

    # Verify module manifest content
    $manifestContent = Import-PowerShellDataFile -Path (Join-Path $Path "$ModuleName.psd1") -ErrorAction SilentlyContinue
    if (-not $manifestContent) {
        Write-Warning "Failed to import module manifest"
        $moduleValid = $false
    }
    else {
        Write-Verbose "Manifest content:"
        $manifestContent | Format-List | Out-String | Write-Verbose
    }

    if (-not $moduleValid) {
        Write-Warning "Module structure validation failed:"
        $missingItems | ForEach-Object { Write-Warning "- Missing: $_" }
        Write-Warning "Module contents:"
        Get-ChildItem -Path $Path -Recurse | Select-Object FullName | Format-Table | Out-String | Write-Warning
    }

    return $moduleValid
}

# Validate module manifest
Write-Host "Validating module manifest..." -ForegroundColor Cyan
$manifest = Test-ModuleManifest -Path $ManifestPath
if (-not $manifest) {
    throw "Module manifest validation failed"
}

# Validate module structure
Write-Host "Validating module structure..." -ForegroundColor Cyan
if (-not (Test-ModuleStructure -Path $ModulePath)) {
    throw "Module structure validation failed"
}

if (-not ($Test -or $Publish)) {
    Write-Warning "No actions specified. Use -Test to run tests or -Publish to publish to gallery."
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 -Test" -ForegroundColor Gray
    Write-Host "  .\build.ps1 -Publish" -ForegroundColor Gray
    Write-Host "  .\build.ps1 -Test -Publish" -ForegroundColor Gray
    exit 0
}

# Run tests if specified
if ($Test) {
    Write-Host "Running tests..." -ForegroundColor Cyan
    if (Get-Module -Name Pester -ListAvailable) {
        $testPath = Join-Path $ModulePath 'tests'
        if (Test-Path $testPath) {
            try {
                # Force import module before testing
                if (Get-Module -Name $ModuleName) {
                    Remove-Module -Name $ModuleName -Force
                }
                Import-Module $ManifestPath -Force -ErrorAction Stop
                
                $testResults = Invoke-Pester -Path $testPath -PassThru
                if ($testResults.FailedCount -gt 0) {
                    throw "Pester tests failed"
                }
            }
            catch {
                throw "Test execution failed: $_"
            }
        }
        else {
            Write-Warning "No tests found in $testPath"
        }
    }
    else {
        Write-Warning "Pester module not found. Skipping tests."
    }
}

# Publish if specified
if ($Publish) {
    Write-Host "Publishing module..." -ForegroundColor Cyan
    
    # Verify API key
    if (-not $ApiKey) {
        throw "No API key provided. Either use -ApiKey parameter or set PSGALLERY_API_KEY environment variable"
    }

    try {
        # Create a temporary package directory
        $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        $packagePath = Join-Path $tempPath $ModuleName
        Write-Verbose "Creating temporary module package at: $packagePath"

        # Create module directory structure
        New-Item -Path $packagePath -ItemType Directory -Force | Out-Null
        
        # Copy module files
        $filesToCopy = @(
            "$ModuleName.ps*1"
            "Public"
            "Private"
            "README.md"
            "LICENSE"
        )

        foreach ($item in $filesToCopy) {
            $source = Join-Path $ModulePath $item
            if (Test-Path $source) {
                Write-Verbose "Copying $item to package"
                Copy-Item -Path $source -Destination $packagePath -Recurse -Force
            }
        }

        # Ensure module can be imported from package
        Write-Host "Verifying packaged module can be imported..." -ForegroundColor Cyan
        $packagedManifest = Join-Path $packagePath "$ModuleName.psd1"
        if (Get-Module -Name $ModuleName) {
            Remove-Module -Name $ModuleName -Force
        }
        Import-Module $packagedManifest -Force -ErrorAction Stop

        # Publish packaged module
        Write-Host "Publishing to PowerShell Gallery..." -ForegroundColor Cyan
        $publishParams = @{
            Path = $packagePath
            NuGetApiKey = $ApiKey
            Repository = 'PSGallery'
            Force = $true
            ErrorAction = 'Stop'
        }
        
        Publish-Module @publishParams
        Write-Host "Module published successfully!" -ForegroundColor Green

        # Cleanup
        Write-Verbose "Cleaning up temporary files"
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        $detailed = $_
        Write-Warning "Detailed error information:"
        Write-Warning $detailed.Exception.Message
        Write-Warning "Stack trace:"
        Write-Warning $detailed.ScriptStackTrace
        
        # Cleanup on error
        if ($tempPath -and (Test-Path $tempPath)) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        throw "Failed to publish module: $_"
    }
}

Write-Host "Build script completed successfully" -ForegroundColor Green
