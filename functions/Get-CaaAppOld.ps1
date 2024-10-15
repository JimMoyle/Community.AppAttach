function Get-CaaApp {
    [CmdletBinding(DefaultParameterSetName = 'Winget')]

    Param (
        [Parameter( ParameterSetName = 'Winget', Position = 0, ValuefromPipelineByPropertyName = $true, ValuefromPipeline = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'All', Position = 0, ValuefromPipelineByPropertyName = $true, ValuefromPipeline = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'WingetWpm', Position = 0, ValuefromPipelineByPropertyName = $true, ValuefromPipeline = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'WingetEvergreen', Position = 0, ValuefromPipelineByPropertyName = $true, ValuefromPipeline = $true, Mandatory = $true )]
        [System.String]$WingetPackageId,
    
        [Parameter( ParameterSetName = 'Evergreen',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'All',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'WingetEvergreen',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'EvergreenWpm',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [System.String]$EverGreenPackageId,

        [Parameter( ParameterSetName = 'WPM', ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'All',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'EvergreenWpm',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'WingetWpm',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [System.String]$WindowsPackageManagerId,

        [Parameter( ParameterSetName = 'WPM', ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'All',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'EvergreenWpm',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [Parameter( ParameterSetName = 'WingetWpm',ValuefromPipelineByPropertyName = $true, Mandatory = $true )]
        [System.Uri]$WindowsPackageManagerUri,

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