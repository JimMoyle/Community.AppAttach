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

$param = @{
    Name                     = 'CaaTest'
    VMSize                   = 'Standard_B2als_v2'
    GalleryName              = 'MsixPackagerGallery'
    ImageDefinition          = 'MsixPackagingImageDefinition'
    ResourceGroupName        = 'DeleteMe'
    VnetName                 = 'AVDPermanent-vnet'
    NetworkResourceGroupName = 'AVDPermanent'
    GalleryResourceGroupName = 'AVDPermanent'
    SubnetId                 = 'default'
    Location                 = 'uksouth'
}

$vm = New-CaaVmFromGallery @param

$vm = $param  | Get-AzVm 

$vm | Remove-CaaVmFromGallery