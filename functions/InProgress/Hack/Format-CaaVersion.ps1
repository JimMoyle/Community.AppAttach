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
            { $verCount -eq 4 } { $outputVer = $Version ; break }
            { $verCount -lt 4 } { 
                $outputVer = $Version.ToString()
                (4 - $verCount)..1 | ForEach-Object {
                    $outputVer += '.0'
                } 
                break
            }
            { $verCount -gt 4 } {
                $outputVer = $Version.ToString() -replace "^(\d+(?:\.\d+){0,3})(?:\.\d+)*$", $matches[1]
                break
            }
            Default {}
        }

        #Last, the revision needs to be 0 to be considered for store and MSIX packaging tool

        $outputVer = $outputVer.ToString() -replace "\.\d+$", ".0"
        try {
            $output = [PSCustomObject]@{
                Version = [version]$outputVer
            }
        }
        catch {
            Write-Warning "$outputVer Does not comply with version formatting requirements"
        }


        Write-Output $output
        
    }
    end {}
}




