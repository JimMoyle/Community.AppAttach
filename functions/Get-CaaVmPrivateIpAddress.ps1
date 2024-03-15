function Get-CaaVmPrivateIpAddress {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ParameterSetName = 'MyParameterSetName',
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Name
    )

    begin {
        Set-StrictMode -Version Latest
        #requires -Modules Az.Compute, Az.Network
    } # begin
    process {

        $vm = Get-AzVM -name Caapack 
        $nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces.Id

        if (($nic | Measure-Object).Count -ne 1){
            Write-Error "More than one Nic on $Name"
            return
        }

        Write-Output $nic.IpConfigurations #| Select-Object PrivateIpAddress, PublicIpAddress, PrivateIpAllocationMethod, ProvisioningState
        
    } # process
    end {} # end
}  #function