function Get-CaaApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$JsonPath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$MsixShare = '\\avdtoolsmsix.file.core.windows.net\appattach\MSIXPackages\',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$DownloadFolder = $env:TEMP
    )

    begin {
        Set-StrictMode -Version Latest
        $Functions = @( Get-ChildItem -Path Functions\*.ps1 -ErrorAction SilentlyContinue )

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
        $appLocation = Get-Content $JsonPath | ConvertFrom-Json

        $appInfo = switch ($appLocation) {
            { $null -ne $_.WingetId } { $appInfo = Get-CaaWingetExeApp -Id $_.WingetId; break }
            { $null -ne $_.StoreId } { $appInfo = Get-CaaStoreApp -Id $_.WingetId; break }
            { $null -ne $_.EvergreenId } { $appInfo = Get-EvergreenApp -Id $_.EvergreenId }
            Default {}
        }

        if ($appInfo.Count -gt 1) {
            Write-Error "More than One Package found"
            return
        }


    } # process
    end {} # end
}  #function

'AppJson\BlenderFoundation.Blender.json' | Get-CaaApp