#region Dot source the files
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
#endregion

$diskImageShare = "\\avdtoolsmsix.file.core.windows.net\appattach\YouTube\AppAttachDiskImages"
$msixPackagePath = "\\avdtoolsmsix.file.core.windows.net\appattach\YouTube\MSIXFiles\Microsoft.UI.Xaml.2.8\8.2310.30001.0\Microsoft.UI.Xaml.2.8_8.2310.30001.0_Universal_X86.appx"
$msixPackagePath = "\\avdtoolsmsix.file.core.windows.net\appattach\YouTube\MSIXFiles\Microsoft.ScreenSketch\2022.2407.3.0\Microsoft.ScreenSketch_2022.2407.3.0_neutral_~_8wekyb3d8bbwe.msixbundle"
$msixPackagePath = "C:\Users\jimoyle\Downloads\PowerShell-7.4.6-win.msixbundle"
#$resourceGroupName = 'DeleteMe'
#$HostPoolName = 'EditMsixPackage'

try {
    $manifest = Read-CaaMsixManifest -Path $msixPackagePath -ErrorAction Stop
}
catch {
    Write-Error "Manifest could not be read from $msixPackagePath, this may not be a complete Msix package."
    return
}

$target = Convert-CaaMsixToDisk -Path $msixPackagePath -DestinationPath $env:TEMP -PassThru

$diskMoveInfo = Move-CaaFileToVersionPath -Path $target.FullName -PackageVersion $manifest.Identity.Version -DestinationShare $diskImageShare -PackageIdentifier $manifest.Identity.Name -PassThru -IncludeExtensionInTargetPath

$diskMoveInfo

<##
$familyName = New-CaaMsixName -PackageIdentifier $manifest.Identity.Name -CertHash (Get-CaaPublisherHash -publisherName $manifest.Identity.Publisher)
$currentPackage = Get-AzWvdAppAttachPackage | Where-Object { $_.ImagePackageFamilyName -eq $familyName.Name }

$importInfo = Import-AzWvdAppAttachPackageInfo -ResourceGroupName $resourceGroupName -HostPoolName $HostPoolName -Path $diskMoveInfo.Path

if (($importInfo | Measure-Object).Count -gt 1 ) {

    switch ($true) {
        { ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x64_*" } | Measure-Object).Count -ge 1 } {
            $correctPackage = ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x64_*" })[0]
            break
        }
        { ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_neutral_*" } | Measure-Object).Count -ge 1 } {
            $correctPackage = ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_neutral_*" })[0]
            break
        }
        { ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x86_*" } | Measure-Object).Count -ge 1 } {
            $correctPackage = ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x86_*" })[0]
            break
        }
        Default { $correctPackage = $importInfo[0] }
    }
}
else {
    $correctPackage = $importInfo
}

if (($currentPackage | Measure-Object).Count -eq 0 ) {
    $parameters = @{
        Name                            = $correctPackage.ImagePackageName
        ResourceGroupName               = $resourceGroupName
        Location                        = 'uksouth'
        FailHealthCheckOnStagingFailure = 'NeedsAssistance'
        ImageIsRegularRegistration      = $false
        ImageDisplayName                = $correctPackage.ImagePackageName
        ImageIsActive                   = $true
    }
    
    New-AzWvdAppAttachPackage -AppAttachPackage $correctPackage @parameters
}
else {
    Update-AzWvdAppAttachPackage -AppAttachPackage $correctPackage -ResourceGroupName $resourceGroupName -Name $currentPackage.Name
}

##>