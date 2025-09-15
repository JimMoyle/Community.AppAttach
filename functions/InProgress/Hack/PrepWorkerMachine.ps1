Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.desktopappinstaller_8wekyb3d8bbwe
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -name psgallery -InstallationPolicy Trusted
Install-Module -Name Microsoft.WinGet.Client
Install-WinGetPackage -Id 9N5LW3JBCXKF #MSIX Packaging tool
Start-Process dism.exe -Wait -ArgumentList "/Online /add-capability /CapabilityName:Msix.PackagingTool.Driver"
Set-Service -Name WSearch -StartupType Disabled
Stop-Service -Name WSearch