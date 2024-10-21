function Get-CaaApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$StoreId,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$WingetId,

        [Parameter(
            ParameterSetName = 'EverGreen',
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$EverGreenId,

        [Parameter(
            ParameterSetName = 'EverGreen',
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$EverGreenFilter,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$MsixShare = '\\avdtoolsmsix.file.core.windows.net\appattach\MSIXPackages\',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$DownloadFolder = $env:TEMP,

        [Parameter(
            ParameterSetName = 'InputObject',
            ValuefromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$InputObject

    )

    begin {
        Set-StrictMode -Version Latest
        $Functions = @( Get-ChildItem -Path Functions\Private\*.ps1 -ErrorAction SilentlyContinue )

        Foreach ($import in $Functions) {
            Try {
                Write-Information "Importing $($Import.FullName)"
                . $import.fullname
            }
            Catch {
                Write-Error -Message "Failed to import function $($import.fullname): $_"
            }
        }
    } # begin
    process {

        if ($InputObject) {
            $InputObject = $InputObject | Get-CaaApp
            break
        }

        if ($WingetId) {
            $wingetDownloadOut = & WinGet Download --id $WingetId --download-directory $DownloadFolder --installer-Type msix --skip-dependencies --accept-source-agreements --accept-package-agreements
            if ($wingetDownloadOut -notcontains "Successfully verified installer hash") {
                Write-Error -Message "Failed to download $WingetId via Winget"
                return
            }
            $output = [pscustomobject]@{
                Path = (($wingetDownloadOut | Select-Object -Last 1) -Split ':', 2)[1].Trim()
            }
            Write-Output $output
            return
        }

        if ($EverGreenId) {
            $filter = [ScriptBlock]::Create($EverGreenFilter)
            try {
                $everGreenAppInfo = Get-EvergreenApp -Name $EvergreenId -ErrorAction Stop | Where-Object $filter
            }
            catch {
                Write-Error "Failed to run `'Get-EvergreenApp -Name $EvergreenId`'"
                break
            }
            
            if ((($everGreenAppInfo | Measure-Object).Count) -ne 1) {
                Write-Error "Filter did not result in a unique package, please refine the filter"
                return
            }
            $fileName = $everGreenAppInfo.URI.Split('/')[-1]
            $outFile = Join-Path $DownloadFolder $fileName
            $iwrPassThru = Invoke-WebRequest -Uri $everGreenAppInfo.URI -OutFile $outFile -PassThru
            if ($iwrPassThru.StatusCode -eq 200) {
                $output = [pscustomobject]@{
                    Path = $outFile
                }
                Write-Output $output
                return
            }
            else {
                Write-Error "Failed to download $EvergreenId via EverGreen"
            }
        }

        if ($StoreId) {
            try {
                $storeAppInfo = Get-CaaStoreApp -Id $StoreId -DownloadPath $DownloadFolder -ErrorAction stop
                $output = [pscustomobject]@{
                    Path = $storeAppInfo.Path
                }
                Write-Output $output
                return 
            }
            catch {
                Write-Information "failed to get Store App $StoreId via Winget"
            }

            try {
                $rdadguardAppInfo = Get-CaaRdAdguard -StoreId $StoreId -ErrorAction Stop
                $downloadPath = Join-Path $DownloadFolder $rdadguardAppInfo.AppName
                Invoke-WebRequest -Uri $rdadguardAppInfo.InstallerUrl -OutFile $downloadPath
                $output = [pscustomobject]@{
                    Path = $downloadPath
                }
                Write-Output $output
                return 
            }
            catch {
                Write-Error "Failed to get Store App $StoreId via RdAdguard"
            }
            
        }

    } # process
    end {} # end
}  #function

$Path = 'AppJson\Microsoft.PowerShell.Preview.json'
$Path = 'D:\GitHub\Community.AppAttach\AppJson\Microsoft.WindowsTerminal.Preview.json'
$info = Get-Content -Path $Path | ConvertFrom-Json
#Get-CaaApp -EverGreenId $info.EvergreenId -EverGreenFilter $info.EvergreenFilter
Get-CaaApp -StoreId $info.StoreId