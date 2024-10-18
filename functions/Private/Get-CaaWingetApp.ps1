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
        [System.String]$Id

    )

    begin {
        Set-StrictMode -Version Latest

    } # begin
    process {

        $msixResult = foreach ( $type in 'msix', 'appx') {
            $wingetReply = ConvertFrom-CaaWingetExeOut -Id $Id -InstallerType $type
            if ($wingetReply.PSobject.Properties.Name -contains 'Installer Type' ) {
                Write-Output $wingetReply
                break
            }
            else {
                $wingetReply = $null
            }
        }

        if (($msixResult | Measure-Object).Count -eq 1) {
            Write-Output $msixResult
            return
        }

        $notMsixReply = ConvertFrom-CaaWingetExeOut -Id $Id

        if ($notMsixReply.PSobject.Properties.Name -notcontains 'Installer Type' ) {
            Write-error "$Id not found by Winget"
            return
        }

        Write-Output $notMsixReply

    } # process
    end {} # end
}  #function