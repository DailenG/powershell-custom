param (
    [string]$updateUrl = "https://www.softwaremetering.com/outgoing/softrack_full.zip",
    [string]$serviceName = "SofTrackService",
    [string]$installPath = "C:\softrack\"
)

function Get-SoftrackUpdate {
	param (
		[string]$url
	)
	
	$updateTemp = (New-TemporaryFile)
	$updateFolder = Join-Path $updateTemp.PSParentPath ("Update" + (Get-Date -Format "yyyyMMdd-HHmmss"))
	Write-Output "Fetching latest version of Softrack"
	$ProgressPreferenceOld = $ProgressPreferenceOld
	$ProgressPreference = "SilentlyContinue"
	Invoke-WebRequest $url -OutFile "$updateTemp.zip"
	Expand-Archive "$updateTemp.zip" $updateFolder
	Remove-Item $updateTemp
	$ProgressPreference = $ProgressPreferenceOld
	
	return Get-Item $updateFolder
}

# Function to stop the service
function Stop-ServiceSafely {
    param (
        [string]$serviceName
    )

    Write-Output "Stopping service: $serviceName"
    Stop-Service -Name $serviceName -Force -ErrorAction Stop
    Start-Sleep -Seconds 5  # Optional: Wait for a few seconds to ensure the service has stopped
}

# Function to copy files and overwrite existing files
function Copy-FilesWithOverwrite {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )

    Write-Output "Copying files from $sourcePath to $destinationPath"
    Copy-Item -Path "$sourcePath\*" -Destination $destinationPath -Recurse -Force -ErrorAction Stop
}

# Function to start the service
function Start-ServiceSafely {
    param (
        [string]$serviceName
    )

    Write-Output "Starting service: $serviceName"
    Start-Service -Name $serviceName -ErrorAction Stop
}

# Function to delete contents of source path
function Remove-SourceFiles {
    param (
        [string]$sourcePath
    )

    Write-Output "Deleting contents of $sourcePath"
    Remove-Item -Path "$sourcePath\*" -Recurse -Force -ErrorAction Stop
}

# Main script execution
try {
	$update = Get-SoftrackUpdate -Url $updateUrl
    Stop-ServiceSafely -serviceName $serviceName
    Copy-FilesWithOverwrite -sourcePath $update -destinationPath $destinationPath
    Start-ServiceSafely -serviceName $serviceName
    Remove-SourceFiles -sourcePath $update
    Write-Output "Update completed successfully."
} catch {
    Write-Error "An error occurred: $_"
}
