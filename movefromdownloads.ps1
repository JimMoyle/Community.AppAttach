#region Dot source the files
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
#endregion
Get-ChildItem -Path "$env:userprofile\Downloads\9*" | Get-ChildItem -File -Filter "*.???x*" -Recurse | Foreach-Object{
    $path = $_.FullName
    $manifest = Read-CaaMsixManifest $path 
    $manifest.Identity | Move-CaaFileToVersionPath -DestinationShare D:\MSIXPackages -Path $path -PassThru
}