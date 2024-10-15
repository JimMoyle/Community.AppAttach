function Format-CaaVersion {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [Alias('PackageVersion')]
        [Version]$Version
    )
    
    begin {}
    
    process {
        $verCount = $Version.ToString().Split('.').Count
        switch ($true) {
            { $verCount -eq 4 } { $outputVer = $Version ;break}
            { $verCount -lt 4 } { 
                $outputVer = (4 - $verCount)..1 | ForEach-Object {
                    $Version.ToString() + '.0'
                } 
                break
            }
            { $verCount -gt 4 } {
                $outputVer = $Version.ToString() -replace "^(\d+(?:\.\d+){0,3})(?:\.\d+)*$", $matches[1]
                break
            }
            Default {}
        }
        
        $output = [PSCustomObject]@{
            Version = [version]$outputVer
        }

        Write-Output $output
        
    }
    end {}
}




