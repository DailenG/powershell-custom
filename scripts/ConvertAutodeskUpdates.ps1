# Import JSON file
$json = (Get-Content 'AutodeskUpdates.json' | ConvertFrom-Json).ProductUpdates

# Iterate over each entry in the object
foreach ($item in $json) {


    <# THIS PART IS STILL NOT WORKING FOR SOME REASON 
    # Handle the 'languages' column
    if ($item.languages -is [PSCustomObject]) {
        [string]$languages = $item.languages | ForEach-Object { $_.langCode -join ", " }
        $item.languages = $languages
    }

    # Handle the 'language' column
    if ($item.language -is [PSCustomObject]) {
        $item.language = $item.language.langCode | ForEach-Object { $_.langCode -join ", " }
    }
    #>

    # Handle the 'platform' column
    if ($item.platform -is [PSCustomObject]) {
        $item.platform = $item.platform.name -join ", "
    }

    # Iterate over other properties if needed
    foreach ($property in $item.PSObject.Properties) {
        # Check and convert other System.Object[] properties as before
        if ($property.Value -is [System.Object[]]) {
            $item.$($property.Name) = $property.Value -join ", "
        }
    }
}

# Export the modified object to CSV
$json | Export-Excel Autodesk_Updates_Cleaned.xlsx