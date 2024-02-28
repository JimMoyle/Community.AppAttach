Install-PackageProvider -Name NuGet -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name Evergreen
Install-Module -Name Microsoft.WinGet.Client
$appInfo = Get-EvergreenApp MicrosoftPowerShell | Where-Object {$_.Architecture -eq 'x64' -and $_.Release -eq 'Stable'}
Invoke-WebRequest -Uri $appInfo.Uri -OutFile $appInfo.Uri.Split('/')[-1]
$fileInfo = Get-ChildItem $appInfo.Uri.Split('/')[-1]
Unblock-File $fileInfo.FullName
Start-Process msiexec.exe -Wait -ArgumentList "/I $($fileInfo.FullName) /quiet"
Start-Process dism.exe -Wait -ArgumentList "/Online /add-capability /CapabilityName:Msix.PackagingTool.Driver"
$msixPackagingToolUri = 'https://download.microsoft.com/download/6/c/7/6c7d654b-580b-40d4-8502-f8d435ca125a/da97fb568eee4e6baa07bc3b234048b3.msixbundle'
$msixPackToolLicense = 'https://download.microsoft.com/download/6/c/7/6c7d654b-580b-40d4-8502-f8d435ca125a/da97fb568eee4e6baa07bc3b234048b3_License1.xml'
Invoke-WebRequest -Uri $msixPackagingToolUri -OutFile $msixPackagingToolUri.Split('/')[-1]
$msixFileInfo = Get-Childitem $msixPackagingToolUri.Split('/')[-1]
Invoke-WebRequest -Uri $msixPackToolLicense -OutFile $msixPackToolLicense.Split('/')[-1]
Unblock-File $msixFileInfo.FullName
Add-AppxPackage -Path $msixFileInfo.FullName
Set-Service -Name WSearch -StartupType Disabled
Stop-Service -Name WSearch
Enable-PSRemoting -force
New-NetFirewallRule -DisplayName “ICMPv4” -Direction Inbound -Action Allow -Protocol icmpv4 -Enabled True
Set-Service -Name wuauserv -StartupType Disabled
Stop-Service -Name wuauserv

#Enable-PSRemoting

# Enables PowerShell Remoting
# Enable-PSRemoting -force
# New-NetFirewallRule -DisplayName “ICMPv4” -Direction Inbound -Action Allow -Protocol icmpv4 -Enabled True

# Actual command the tool uses
# $sessionOptions = New-PSSessionOption -SkipCNCheck
# $persistentMPTSession = New-PSSession -ComputerName 'aapack-2.avd.tools' -Credential 'user2@avd.tools' -UseSSL -SessionOption $sessionOptions -EnableNetworkAccess 
# Enroll machine cert
# Activate listener for remoting
# Make sure thumbprint on cert and listener match (Winrm enumerate winrm/config/listener)

# New-PSSession -ComputerName Server01 -UseSSL
# https://learn.microsoft.com/en-us/troubleshoot/windows-client/system-management-components/configure-winrm-for-https
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting?view=powershell-7.4

<##

param(
    [Parameter(Mandatory=$true)]
    $certThumb
)

Set-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTPS"} -ValueSet @{CertificateThumbprint=$certThumb}

##>