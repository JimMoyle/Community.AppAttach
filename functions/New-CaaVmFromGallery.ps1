function New-CaaVmFromGallery {
    [CmdletBinding(DefaultParameterSetName = 'None')]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Name,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$GalleryName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$ImageDefinition,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$ResourceGroupName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$VnetName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$SubnetId,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$Location,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$VMSize,

        [Parameter(
            ParameterSetName = 'Sysprepped',
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$SysPrepped,

        [Parameter(
            ParameterSetName = 'Sysprepped',
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [pscredential]$Credential,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$NetworkResourceGroupName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$GalleryResourceGroupName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$NetworkSecurityGroupId
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        if (-not ($NetworkResourceGroupName)){
            $NetworkResourceGroupName = $ResourceGroupName
        }
        if (-not ($GalleryResourceGroupName)){
            $GalleryResourceGroupName = $ResourceGroupName
        }

        # Get the image. This will create the VM from the latest image version available.
        $definition = Get-AzGalleryImageDefinition -GalleryName $GalleryName -ResourceGroupName $GalleryResourceGroupName | Where-Object Name -eq $ImageDefinition

        $vnet = Get-AzVirtualNetwork -ResourceGroupName $NetworkResourceGroupName -Name $VnetName
        $subnetId = $vnet.subnets | Where-Object Name -eq $SubnetId | Select-Object -ExpandProperty Id

        $newAzNetworkInterface = @{
            Name = ($Name + '-Nic') 
            ResourceGroupName = $ResourceGroupName 
            Location = $Location 
            SubnetId = $subnetId 
        }

        if ($NetworkSecurityGroupId){
            $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name myNetworkSecurityGroup
            $newAzNetworkInterface = $newAzNetworkInterface += @{
                NetworkSecurityGroupId = $nsg.Id
            }
        }
        
        $nic = New-AzNetworkInterface @newAzNetworkInterface -Force

        # Create a virtual machine configuration using $imageDefinition.Id to use the latest image version.
        $vmConfig = New-AzVMConfig -VMName $Name -VMSize $VMSize -SecurityType TrustedLaunch | 
        Set-AzVMSourceImage -Id $definition.Id | 
        Add-AzVMNetworkInterface -Id $nic.Id |
        Set-AzVMBootDiagnostic -Disable
        
        if ($SysPrepped) {
            $vmConfig = $vmConfig | Set-AzVMOperatingSystem -Windows -ComputerName $Name -Credential $Credential
        }

        # Create a virtual machine
        $newVmResult = New-AzVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vmConfig -OSDiskDeleteOption Delete

        if ($newVMResult.IsSuccessStatusCode){
            $output = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Name
        }
        else{
            Write-Error "VM $Name creation failed"
            return
        }

        Write-Output $output
    } # process
    end {} # end
}  #function