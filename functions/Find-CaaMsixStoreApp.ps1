function Find-CaaMsixStoreApp {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('PackageIdentifier')]
        [System.String]$Id
    )

    begin {
        Set-StrictMode -Version Latest

        function reduceToOne {
            [CmdletBinding()]
            param (
                $AppList
            )
            $numberOfApps = ($AppList | Measure-Object).Count
            switch ($numberOfApps) {
                { $numberOfApps -eq 0 } { Write-Error "$Id cannot be found in the store"; break }
                { $numberOfApps -eq 1 } { 
                    #$storeAppInfo = Winget show --Id $isMsix --source msstore
                    Write-Output "Found MSIX application $($AppList.AppName) with Id $($AppList.PackageIdentifier) in the store, but as the store does not allow downloads, if this looks like the application you want please contact the vendor for the MSIX file."
                    return
                }
                Default {}
            }
        }
    } # begin
    process {
        if ($id -like "*.*") {
            $publisher, $appName = $Id -Split '\.' , 2
        }
        else {
            $appName = $Id
        }

        $searchStore = Winget search $appName --source msstore

        $removeHeaders = $searchStore | Where-Object { $_ -like "*unknown*" }
        $searchObj = foreach ($storeApp in $removeHeaders) {
            $storeApp -Match "^(.*)\s(\w+)\s+Unknown$" | Out-Null
            $appObj = [PSCustomObject]@{
                AppName           = $matches[1].Trim()
                PackageIdentifier = $matches[2].Trim()
            }
            Write-Output $appObj
        }

        if (($appObj | Measure-Object).Count -eq 0) {
            Write-Error "$Id cannot be found in the store"
            return
        }

        $isMsix = $searchObj | Where-Object { $_.PackageIdentifier -like "9*" }
        try {
            reduceToOne -AppList $isMsix        
        }
        catch {
            foreach ($appItem in $isMoreLikeName) {
                Write-Output "Found MSIX application $($appItem.AppName) with Id $($appItem.PackageIdentifier) in the store, but as the store does not allow downloads, if this looks like the application you want please contact the vendor for the MSIX file."
            }
        }

        $isLikeName = $isMsix | Where-Object { $_.AppName -like "*$appName*" }
        try {
            reduceToOne -AppList $isLikeName -ErrorAction Stop
        }
        catch {
            foreach ($appItem in $isMsix) {
                Write-Output "Found MSIX application $($appItem.AppName) with Id $($appItem.PackageIdentifier) in the store, but as the store does not allow downloads, if this looks like the application you want please contact the vendor for the MSIX file."
            }
        }

        $isMoreLikeName = $isLikeName | Where-Object { $_.AppName -Like "*$appName" -or $_.AppName -Like "$appName*" }
        try {
            reduceToOne -AppList $isMoreLikeName -ErrorAction Stop
        }
        catch {
            foreach ($appItem in $isLikeName) {
                Write-Output "Found MSIX application $($appItem.AppName) with Id $($appItem.PackageIdentifier) in the store, but as the store does not allow downloads, if this looks like the application you want please contact the vendor for the MSIX file."
            }
        }

        $isExactName = $isMoreLikeName | Where-Object { $_.AppName -eq $appName }

        try {
            reduceToOne -AppList $isExactName -ErrorAction Stop
        }
        catch {
            foreach ($appItem in $isMoreLikeName) {
                Write-Output "Found MSIX application $($appItem.AppName) with Id $($appItem.PackageIdentifier) in the store, but as the store does not allow downloads, if this looks like the application you want please contact the vendor for the MSIX file."
            }
        }
 
    } # process
    end {} # end
}  #function