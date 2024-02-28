function Find-CaaStoreApp {
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
            param (
                $AppList
            )
            $numberOfApps = ($AppList | Measure-Object).Count
            switch ($numberOfApps) {
                {$numberOfApps -eq 0 } { Write-Error "$Id cannot be found in the store"; break }
                {$numberOfApps -eq 1 } { 
                    #$storeAppInfo = Winget show --Id $isMsix --source msstore
                    Write-Output "Found Msix application $($AppList.AppName) with Id $($AppList.PackageIdentifier) in the store, but as the store does not allow downloads, if this looks like the application you want please contact the vendor for the msix file."
                    return
                }
                Default {}
            }
        }
    } # begin
    process {
        if ($id -like "*.*"){
            $publisher, $appName = $Id -Split '\.' , 2
        }
        else{
            $appName  = $Id
        }

        $searchStore = Winget search $appName --source msstore

        $removeHeaders = $searchStore | Select-Object -Skip 2

        $searchObj = foreach ($storeApp in $removeHeaders){
            $storeApp -Match "^(.*)\s(\w+)\s+Unknown$" | Out-Null
            $appObj = [PSCustomObject]@{
                AppName = $matches[1].Trim()
                PackageIdentifier = $matches[2].Trim()
            }
            Write-Output $appObj
        }

        $isMsix = $searchObj | Where-Object {$_.PackageIdentifier -like "9*"}

        reduceToOne -AppList $isMsix

        $isLikeName = $isMsix | Where-Object {$_.AppName -like "*$appName*" }

        reduceToOne -AppList $isLikeName

        $isMoreLikeName = $isLikeName | Where-Object {$_.AppName -Like "*$appName" -or $_.AppName -Like "$appName*" }

        reduceToOne -AppList $isMoreLikeName

        $isExactName = $isMoreLikeName | Where-Object {$_.AppName -eq $appName }

        reduceToOne -AppList $isExactName

    
    } # process
    end {} # end
}  #function