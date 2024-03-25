function Test-CaaIsMsix {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Name
    

    )

    begin {
        Set-StrictMode -Version Latest
        $validExtensions = 'msix', 'msixbundle', 'appx', 'appxbundle'
    } # begin
    process {
        if ( $Name.Split('.')[-1] -in $validExtensions ) {
            Write-Output = $true
        }
        else {
            Write-Output= $false
        }
    } # process
    end {} # end
}  #function



