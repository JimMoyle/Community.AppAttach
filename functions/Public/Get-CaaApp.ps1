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
        $jsonInfo = Get-Content $JsonPath | ConvertFrom-Json

        $appInfo = switch ($jsonInfo) {
            { $null -ne $_.WingetId } { $appInfo = Get-CaaWingetApp -Id $_.WingetId; break }
            { $null -ne $_.StoreId } { $appInfo = Get-CaaStoreApp -Id $_.WingetId; break }
            { $null -ne $_.EvergreenId } { $appInfo = Get-EvergreenApp -Id $_.EvergreenId }
            Default {}
        }

        switch (($appInfo | Measure-Object).Count) {
            1 { break }
            0 { Write-Error "No Package found"; return }
            Default { Write-Error "More than One Package found"; return }
        }

        if ($appInfo.Count -gt 1) {
            Write-Error "More than One Package found"
            return
        }


    } # process
    end {} # end
}  #function

Get-CaaApp -JsonPath 'AppJson\BlenderFoundation.Blender.json'