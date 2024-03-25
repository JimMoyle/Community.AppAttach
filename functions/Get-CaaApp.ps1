function Get-CaaApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$WingetPackageId,
    
        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$EverGreenPackageId,

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