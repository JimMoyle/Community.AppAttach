function Get-CaaStoreApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('StoreId')]
        [System.String]$Id,

        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$DownloadPath
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {

        $wingetDownloadOut = & WinGet Download --id $Id --download-directory $env:TEMP --skip-microsoft-store-package-license --skip-dependencies --accept-source-agreements --accept-package-agreements #--ignore-warnings
        if ($wingetDownloadOut -notmatch 'Successfully verified Microsoft Store package hash') {
            Write-Error -Message "Failed to download $Id"
            return
        }
        Write-Output $output
    } # process
    end {} # end
}  #function