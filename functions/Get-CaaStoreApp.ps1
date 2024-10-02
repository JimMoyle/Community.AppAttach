function Get-CaaStoreApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ParameterSetName = 'MyParameterSetName',
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$StoreId,
    
        [Parameter(
            ParameterSetName = 'InputObject',
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [My.Type]$InputObject
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {

        $wingetDownloadOut = & WinGet Download --id $StoreId --download-directory $env:TEMP --skip-microsoft-store-package-license --skip-dependencies --accept-source-agreements --accept-package-agreements --ignore-warnings
        if ($wingetDownloadOut -notmatch 'Successfully verified Microsoft Store package hash') {
            $output = Get-CaaRdAdguard -StoreId $StoreId
        }
    } # process
    end {} # end
}  #function