function Get-CaaApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$WingetId,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$StoreId,
    
        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$EverGreenId,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$DownloadFolder
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        
    } # process
    end {} # end
}  #function