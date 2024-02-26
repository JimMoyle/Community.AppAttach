function ConvertFrom-CaaWingetExeOut {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('PackageIdentifier')]
        [string]$Id
    )

    $wingetOut = Winget show --Id $Id
    $wingetLines = $wingetOut -Split '\r?\n'

    $output = [PSCustomObject]@{
        PackageIdentifier = $Id
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
        #TODO - Handle nested properties (if needed)
        $output | Add-Member -MemberType NoteProperty -Name $key -Value $value
    }

    Write-Output $output
}