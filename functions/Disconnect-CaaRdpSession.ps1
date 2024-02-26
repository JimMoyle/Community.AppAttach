function Disconnect-CaaRdpSession {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$packagingMachine,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$UserName
    )
    
    begin {
        Set-StrictMode -Version Latest
    }
    
    process {
        $userBasic = $userName.Split('@')[0]
        $sessionInfo = qwinsta /server:$packagingMachine | Where-Object { $_ -like "*$userBasic*active*" }
        if (($sessionInfo | Measure-Object).Count -gt 0) {
            foreach ($session in $sessionInfo) {
                $sessionId = $session.split() | Where-Object { $_ -match "^\d+$" }
                LOGOFF $sessionId /server:$packagingMachine
            }
        }
    }
    
    end {}
}