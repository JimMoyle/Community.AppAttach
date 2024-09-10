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
        
    } # process
    end {} # end
}  #function