function Get-CaaWingetApp {
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

            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true
        )]
        [System.String]$Path = $ENV:TEMP
    )

    begin {
        #requires -modules Microsoft.WinGet.Client
        Set-StrictMode -Version Latest
    } # begin
    process {

        $ExportWingetPackageParam = @{
            Id                = $Id
            DownloadDirectory = $Path
            SkipDependencies  = $true
        }

        If ($id -notmatch "(?:9|X)\w{11}") {
            #this is not a store Package
            $ExportWingetPackageParam += @{
                InstallerType = 'Msix'
            }
        }

        $wingetResult = Export-WingetPackage @ExportWingetPackageParam

        switch ($wingetResult.Status) {
            'NoApplicableInstallers' { Write-Error -Message "No applicable installers found for $Id"; break }
            'DownloadError' { Write-Error -Message "Download is disabled for $($WingetResult.Name) with id: $Id"; break }
            'OK' { break } # Do nothing, as the status is successful
            default { Write-Error -Message "Download failed for $Id with error: $($wingetResult.Status)" }
        } # switch

    } # process
    end {} # end
}  #function

Get-CaaWingetApp 9PP3C07GTVRH