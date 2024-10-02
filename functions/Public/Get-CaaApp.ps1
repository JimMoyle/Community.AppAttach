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

        switch ($jsonInfo) {
            { '' -ne $_.Evergreen.Id } {
                $everGreenAppInfo = Get-EvergreenApp -Id $_.Evergreen.Id
                $appInfo = $everGreenAppInfo 
            }
            { '' -ne $_.StoreId } {
                $storeAppInfo = Get-CaaStoreApp -Id $_.StoreId -DownloadPath $DownloadFolder
                if ($null -ne $_.EvergreenId) {
                    $storeAppInfo | Add-Member -MemberType NoteProperty -Name Version -Value $everGreenAppInfo.Version
                    $storeAppInfo | Add-Member -MemberType NoteProperty -Name InstallerUrl -Value $everGreenAppInfo.InstallerUrl
                }
                $appInfo = $storeAppInfo
            }
            { '' -ne $_.WingetId } {
                $wingetAppInfo = Get-CaaWingetApp -Id $_.WingetId
                if ($null -eq $appInfo.InstallerUrl) {
                    $appInfo = $wingetAppInfo
                }
                else{
                    $wingetAppInfo | Add-Member -MemberType NoteProperty -Name InstallerUrl -Value $appInfo.InstallerUrl
                    $appInfo = $wingetAppInfo
                }
            }
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