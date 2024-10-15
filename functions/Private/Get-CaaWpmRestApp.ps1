
function Get-CaaWpmRestApp {
    [CmdletBinding()]

    Param (

        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('PackageIdentifier')]
        [System.String]$Id,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Uri]$Uri = 'https://pkgmgr-wgrest-pme.azurefd.net/api/packageManifests/',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Int]$ApiTimeoutSeconds = 90
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin

    process {
        Write-Verbose "Querying $ID from $Uri"

        # Construct the query URI
        $queryUri = $Uri.ToString().TrimEnd('/') + '/' + $ID

        $noResponse = $true
        $timeSpan = (Get-Date).AddSeconds($ApiTimeoutSeconds)

        # Wait for a response or timeout
        while ($noResponse) {
            if ((Get-Date) -gt $timeSpan) {
                Write-Error "Timeout waiting for $ID response from $queryUri"
                return
            }
            try {
                $package = Invoke-RestMethod -Uri $queryUri -ErrorAction Stop
                $noResponse = $false
            }
            catch {
                Start-Sleep -Milliseconds 500
            }
        }

        # Check if the package is null
        if ($null -eq $package) {
            Write-Error "Could not find package with Id $ID"
            return
        }
        # Check if the package is properly formed
        if ($package.PSobject.Properties.Name -notcontains 'Data') {
            Write-Error "Package with Id $ID did not return a valid response from REST"
            return
        }

        try {
            # Create version object rather than string
            $packageSortable = $package.Data.Versions | Select-Object @{Name = 'PackageVersion'; Expression = { [Version]$_.PackageVersion } }, Installers, DefaultLocale

            # If the package version count is 0, use a regular expression to extract the version number
            if (($packageSortable.PackageVersion | Measure-Object).Count -eq 0) {
                $packageSortable = $package.Data.Versions | Select-Object  @{Name = 'PackageVersion'; Expression = { 
                        $_.PackageVersion -match "(\D{0})(\d+)((\.{1}\d+)*)(\.{0})" | Out-Null
                        if ($($Matches[0]) -notlike "*.*") { 
                            [Version]($Matches[0] + ".0") 
                        } 
                        else {
                            [Version]$Matches[0] 
                        } 
                    }
                } , Installers, DefaultLocale
            }
        }
        catch {
            # Output any errors that occur during version selection
            Write-Error "Error selecting newest package version for $ID"
        }

        # Select the package detail with the highest version number
        $packageDetail = $packageSortable | Sort-Object -Property PackageVersion -Descending | Select-Object -First 1

        # Set the timeout for version query match
        $timeSpan = (Get-Date).AddSeconds(30)
        $appInfo = $null

        # Wait for a version query match or timeout
        while (($appInfo | Measure-Object).Count -eq 0 ) {
            if ((Get-Date) -gt $timeSpan) {
                Write-Error "Timeout waiting for version query match for $ID"
                return
            }
            # As the version can't be trusted getting the recent one by joining the installer sha256
            $appInfo = $package.Data.versions | Where-Object { -join $_.Installers.InstallerSha256 -eq -join $packageDetail.Installers.InstallerSha256 }
        }
        
        # Iterate through each installer in the package detail
        foreach ($installer in $packageDetail.Installers) {

            # Create a custom object with the installer details
            $output = [PSCustomObject]@{
                PackageIdentifier         = $package.Data.PackageIdentifier
                PackageVersion            = $packageDetail.PackageVersion
                Publisher                 = $appInfo.DefaultLocale.Publisher
                ShortDescription          = $appInfo.DefaultLocale.ShortDescription
                InstallerIdentifier       = $installer.InstallerIdentifier      
                InstallerSha256           = $installer.InstallerSha256
                InstallerUrl              = $installer.InstallerUrl
                Architecture              = $installer.Architecture
                InstallerType             = $installer.InstallerType
                Scope                     = if ($installer.PSobject.Properties.Name -contains 'Scope') { $installer.Scope } else { $null }
                InstallerSwitches         = if ($installer.PSobject.Properties.Name -contains 'InstallerSwitches') { $installer.InstallerSwitches } else { $null }
                Commands                  = if ($installer.PSobject.Properties.Name -contains 'Commands') { $installer.Commands } else { $null }
                InstallerAbortsTerminal   = $installer.InstallerAbortsTerminal
                ReleaseDate               = $installer.ReleaseDate
                InstallLocationRequired   = $installer.InstallLocationRequired
                RequireExplicitUpgrade    = $installer.RequireExplicitUpgrade
                DisplayInstallWarnings    = $installer.DisplayInstallWarnings
                DownloadCommandProhibited = $installer.DownloadCommandProhibited
            }

            # Output the installer details
            Write-Output $output
        }

    } # process

    end {} # end

}  #function
