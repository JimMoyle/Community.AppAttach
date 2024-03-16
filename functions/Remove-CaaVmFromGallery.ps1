function Remove-CaaVmFromGallery {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ParameterSetName = 'ViaId',
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Id,

        [Parameter(
            ParameterSetName = 'ViaId',
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$NicId,

        [Parameter(
            ParameterSetName = 'ViaId',
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$OsDiskName,
    
        [Parameter(
            ParameterSetName = 'InputObject',
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$InputObject
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        if ($PsCmdlet.ParameterSetName -eq 'InputObject'){
            $Id = $InputObject.Id
            $NicId = $InputObject.NetworkProfile.NetworkInterfaces.Id
            $OsDiskName = $InputObject.StorageProfile.OsDisk.Name
        }
        Remove-AzVM -Id $Id -ForceDeletion $true -Force | Out-Null
        Get-AzNetworkInterface -ResourceId $NicId | Remove-AzNetworkInterface -Force
        Get-AzDisk -DiskName $OsDiskName | Remove-AzDisk -Force | Out-Null
    } # process
    end {} # end
}  #function