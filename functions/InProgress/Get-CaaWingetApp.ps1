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
            'NoApplicableInstallers' { Write-Error -Message "No applicable installers found for $Id" }
            'DownloadError' { Write-Error -Message "Download is disabled for $($WingetResult.Name) with id: $Id"          }
            'OK' { # Do nothing, as the status is successfu}
            default { Write-Error -Message "Download failed for $Id with error: $($wingetResult.Status)" }
        }

    } # process
    end {} # end
}  #function

Get-CaaWingetApp 9P7KNL5RWT25