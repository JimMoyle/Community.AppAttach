function ConvertFrom-CaaWingetExeOut {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('PackageIdentifier')]
        [string]$Id,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        #TODO add validate set
        [string[]]$InstallerType

    )
    begin {
        Set-StrictMode -Version Latest
    }
    process {
        #TODO change this to switch
        if ($InstallerType -contains 'msix' -or $InstallerType -contains 'appx') {
            $wingetOut = Winget show --Id $Id --Installer-Type $InstallerType
        }
        else{
            $wingetOut = Winget show --Id $Id 
        }

        $wingetLines = $wingetOut -Split '\r?\n'

        $joined = $wingetOut -join ''

        if ($joined -match 'Description:(?:\s*)(.*)Homepage:\s') {
            $description = $matches[1]
        }
        else {
            $description = ''
        }

        $output = [PSCustomObject]@{
            PackageIdentifier = $Id
            Description = $description
        }


        foreach ($line in $WingetLines) {
            if ($line -notlike '*:*') {
                continue
            }
            $key, $value = $line -split ':', 2
            $key = $key.Trim()
            $value = $value.Trim()
            if ([string]::IsNullOrEmpty($value)) {
                continue
            }
            #TODO - Handle nested properties (if needed)
            $output | Add-Member -MemberType NoteProperty -Name $key -Value $value
        }

        Write-Output $output
    }
    end{
        #Remove-Variable $output
        #Remove-Variable $WingetLines
    }
}