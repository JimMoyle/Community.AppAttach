function Get-WingetExeApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ParameterSetName = 'MyParameterSetName',
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('PackageIdentifier')]
        [System.String]$Id

    )

    begin {
        Set-StrictMode -Version Latest

        $sources = foreach ($line in (& Winget source list | Select-Object -Skip 2)) {

            $sourceName, $sourceUrl = $line -Split '\s+', 2
            $source = [PSCustomObject]@{
                Source = $sourceName
                Url    = $sourceUrl
            }
            Write-Output $source
        }
        if ($sources.Source -notcontains 'msstore') {
            Write-Warning 'Store apps cannot be checked'
        }

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
. functions\ConvertFrom-CaaWingetExeOut.ps1
#Get-WingetExeApp -Id Mozilla.Firefox
#Get-WingetExeApp -Id BlenderFoundation.Blender
#Get-WingetExeApp -Id 9PP3C07GTVRH
Get-WingetExeApp -Id Not.true