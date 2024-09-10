

function Get-CaaRdAdguard {
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
            ValuefromPipeline = $true
        )]
        [System.Uri]$apiUrl = "https://store.rg-adguard.net/api/GetFiles"
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        $body = @{
            type = 'ProductId'
            url  = $StoreId
            ring = 'RP'
            lang = 'en-US'
        }
        $html = Invoke-RestMethod -Method Post -Uri $apiUrl -ContentType 'application/x-www-form-urlencoded' -Body $body

        $html | Select-String '<tr style.*<a href=\"(?<url>.*)"\s.*>(?<text>.*)<\/a>' -AllMatches |
        ForEach-Object { $_.Matches } |
        ForEach-Object { 
            $url = $_.Groups[1].Value
            $appName = $_.Groups[2].Value
            if ($appName -match "_(x86|x64|neutral).*(app|msi)x(|bundle)$") {
                $output = [PSCustomObject]@{
                    AppName       = $appName
                    InstallerUrl  = $url
                    Architecture  = $installer.Architecture
                    InstallerType = $installer.InstallerType
                }
                Write-Output $output
            }
        }
    } # process
    end {} # end
}  #function