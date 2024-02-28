function Get-CaaSilentInstall {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [ValidateSet("msix", "msi", "appx", "exe", "zip", "inno", "nullsoft", "wix", "burn", "pwa", "portable")]
        [System.String]$InstallerType,
    
        [Parameter(
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [String]$InstallerSwitches
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {

        $generic = switch ($InstallerType) {
            'inno' { '/VERYSILENT'; break }
            'msi' { '/qn'; break }
            'exe' {}
            'zip'{}
            'nullsoft' {}
            'wix' {}
            'burn' {}
            'pwa' {}
            'portable' {}
            Default {}
        }
         $custom = $InstallerSwitches

         $silentInstall = "{0} {1}" -f $generic, $custom

         Write-Output $silentInstall
        
    } # process
    end {} # end
}  #function