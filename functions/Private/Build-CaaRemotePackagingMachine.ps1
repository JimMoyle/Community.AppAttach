function Build-RemotePackagingMachine {
    [CmdletBinding()]

    Param (
        [Parameter(
            ValuefromPipeline = $true
        )]
        [System.Uri]$MptUri = 'https://download.microsoft.com/download/6/c/7/6c7d654b-580b-40d4-8502-f8d435ca125a/da97fb568eee4e6baa07bc3b234048b3.msixbundle',
    
        [Parameter(
            ValuefromPipeline = $true
        )]
        [System.Uri]$MptLicenseUri = 'https://download.microsoft.com/download/6/c/7/6c7d654b-580b-40d4-8502-f8d435ca125a/da97fb568eee4e6baa07bc3b234048b3_License1.xml'
    )

    begin {
        #requires -RunAsAdministrator
        Set-StrictMode -Version Latest
    } # begin
    process {
        # Install Microsoft Packaging Toolkit Driver
        Start-Process dism.exe -Wait -ArgumentList "/Online /add-capability /CapabilityName:Msix.PackagingTool.Driver"

        # Create filenames for downloads
        $mptOutFile = $MptUri.ToString().TrimEnd('/').Split('/')[-1]
        $mptLicenseOutFile = $MptLicenseUri.ToString().TrimEnd('/').Split('/')[-1]

        # Download Microsoft Packaging Toolkit
        Invoke-WebRequest -Uri $MptUri -OutFile $mptOutFile
        $msixFileInfo = Get-Childitem $mptOutFile
        Unblock-File $msixFileInfo.FullName

        # Download License
        Invoke-WebRequest -Uri $MptLicenseUri -OutFile $mptLicenseOutFile
        $msixLicenseFileInfo = Get-Childitem $mptLicenseOutFile
        Unblock-File $msixLicenseFileInfo.FullName

        # Install Microsoft Packaging Toolkit
        Add-AppxPackage -Path $msixFileInfo.FullName

        # Enables PowerShell Remoting
        Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
        New-NetFirewallRule -DisplayName “ICMPv4” -Direction Inbound -Action Allow -Protocol icmpv4 -Enabled True
        Enable-PSRemoting -force
        
        # Stop and disable search service
        Set-Service -Name WSearch -StartupType Disabled
        Stop-Service -Name WSearch
    } # process
    end {} # end
}  #function