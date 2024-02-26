function ConvertFrom-WingetExeOut {
    param (
        [string]$WingetId
    )

    $wingetOut = Winget show --Id Git.Git
    $wingetLines = $wingetOut -Split '\r?\n'

    $output = [PSCustomObject]@{
        PackageIdentifier = $WingetId
    }

    foreach ($line in $WingetLines) {
        if ($line -notlike '*:*') {
            continue
        }
        $key, $value = $line -split ':', 2
        $key = $key.Trim()
        $value = $value.Trim()
        if ([string]::IsNullOrEmpty($value)) {
           continue
        }
        <##
        #TODO - Handle nested properties (if needed)
        # Handle nested properties (if needed)
        if ($key -contains ':') {
            $nestedKeys = $key -split '\.'
            $currentObject = $mainObject
            foreach ($nestedKey in $nestedKeys) {
                if (-not $currentObject.$nestedKey) {
                    $currentObject | Add-Member -MemberType NoteProperty -Name $nestedKey -Value ([PSCustomObject]@{})
                }
                $currentObject = $currentObject.$nestedKey
            }
            $currentObject.Value = $value
        }
        else {
            $mainObject | Add-Member -MemberType NoteProperty -Name $key -Value $value
        }
        ##>
        $output | Add-Member -MemberType NoteProperty -Name $key -Value $value
    }

    Write-Output $output
}

# Usage:
ConvertFrom-WingetExeOut -WingetId Git.Git