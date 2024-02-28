function Move-CaaFileToVersionPath {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [ValidateScript({
            if (-Not ($_ | Test-Path) ) { throw "File does not exist" }
            if (-Not ($_ | Test-Path -PathType Leaf) ) { throw "The Path argument must be a file. Folder paths are not allowed." }
            return $true
        })]
        [Alias('PSPath')]
        [System.String]$Path,

        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [ValidateScript({
            if (-Not ($_ | Test-Path) ) { throw "Folder does not exist" }
            if (-Not ($_ | Test-Path -PathType Container) ) { throw "The Path argument must be a folder. File paths are not allowed." }
            return $true
        })]
        [String]$DestinationShare,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Alias('Version')]
        [version]$PackageVersion,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Alias('Name', 'ID')]
        [String]$PackageIdentifier,
        
        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$PassThru
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {

        $fileInfo = Get-ChildItem -Path $Path

        $destId = Join-Path $DestinationShare $PackageIdentifier
        $destVer = Join-Path $destId $PackageVersion

        if (-not (Test-Path $destVer)) {
            New-Item -ItemType Directory $destVer | Out-Null
        }

        $destLoc = Join-Path $destVer $fileInfo.PSChildName

        if (-not (Test-Path $destLoc)) {
            Move-Item $Path $destLoc
        }

        If ($PassThru) {

            $output = [PSCustomObject]@{
                Name    = $PackageIdentifier
                Version = $PackageVersion
                Path = $destLoc
            }
            Write-Output $output
        }          
    } # process
    end {} # end
}  #function