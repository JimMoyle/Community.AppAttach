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

#region Parameters

$UseEverGreen = $true
$UseWingetexe = $true

$EverGreenPackageID = 'MicrosoftVisualStudioCode'
$WpmPackageID = 'Microsoft.VisualStudioCode.Insiders'

$TemplateShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Templates\'
$InstallerShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Installers\'
$MsixShare = '\\avdtoolsmsix.file.core.windows.net\appattach\MSIXPackages\'
$CertPath = "\\avdtoolsmsix.file.core.windows.net\appattach\Templates\JimAdmin.pfx"
$TempPath = $env:TEMP

$packagingMachine = 'AAPack-2.AVD.Tools'
$UserName = 'User2@avd.tools'

$machinePass = Get-Content 'c:\JimM\machinePass.txt'

$HostPoolName = 'JimMHostPool'

#endregion

#region GetCert Info

$certPass = ConvertTo-SecureString (Get-Content 'c:\JimM\certPass.txt') -AsPlainText -Force
$certInfo = Get-PfxData -Password $certPass -FilePath $certPath
$certPublisher = $certInfo.EndEntityCertificates.Subject
$publisherName = $certPublisher.Trim().Split(',')[0]
$msixHash = Get-CaaPublisherHash $certPublisher
$PublisherDisplayName = $publisherName.Split('=')[-1]

#endregion

#region Find App
#TODO loop till 1 left
$appInfo = Get-CaaWpmRestApp -Id $WpmPackageID | Where-Object { $_.Architecture -eq 'x64' -and $_.Scope -eq 'machine' }

if ($appInfo.Count -ne 1) {
    Write-Error "More than One Package found for $WpmPackageID please adjust your filter"
    return
}

if ($UseEverGreen) {
    $evergreenAppInfo = Get-evergreenapp $EverGreenPackageID | Where-Object { $_.channel -eq 'Insider' -and $_.Architecture -eq 'x64' -and $_.Platform -eq 'win32-x64' }
    if (($evergreenAppInfo | Measure-Object).Count -gt 1) {
        Write-Error "More than One Package found for $evergreenAppInfo please adjust your filter"
        return
    }
    if (($evergreenAppInfo | Measure-Object).Count -ne 1) {
        Write-Error "More than One Package found for $evergreenAppInfo please adjust your filter"
        return
    }
    else {
        if ([version]$evergreenAppInfo.Version -gt [version]$appInfo.PackageVersion) {
            $appInfo.PackageVersion = $evergreenAppInfo.Version
            $appInfo.InstallerUrl = $evergreenAppInfo.URI
            $appInfo.InstallerSha256 = $evergreenAppInfo.Sha256
            $appInfo.Architecture = $evergreenAppInfo.Architecture
        }
    }
}

if ($UseWingetexe) {
    try {
        $wingetexeAppInfo = Get-CaaWinGetExeApp -Id $WpmPackageID -ErrorAction Stop
        if ($wingetexeAppInfo.'Installer Type' -eq 'msstore' -and $wingetexeAppInfo.PackageIdentifier -like "9*") {
            Write-Error "MSIX present in the store with Id $PackageIdentifier but is not downloadable, please contact the vendor to obtain the MSIX file"
            return
        }
        if ($wingetexeAppInfo.'Installer Type' -eq 'msstore' -and $wingetexeAppInfo.PackageIdentifier -like "X*") {
            Write-Error "Win32 app is present in the store with Id $PackageIdentifier but is not downloadable, please contact the vendor to obtain the installer"
            return
        }

    }
    catch {
        'TODO: search store for a likely candidate'
    }
}

$installerFileName = $appInfo.InstallerUrl.Split('/')[-1]

# Not using Join-Path as there are nore than 2 items
$installerFilePath = [IO.Path]::Combine($installerShare, $appInfo.PackageIdentifier, $appInfo.PackageVersion, $installerFileName)

if (Test-Path $installerFilePath) {
    if (Test-CaaSha256Hash -Path $installerFilePath -Sha256Hash $appInfo.InstallerSha256) {
        $downloadInstaller = $false
    }
    else {
        Remove-Item $installerFilePath -Force -Confirm:$false
        $downloadInstaller = $true
    }
}
else {
    $downloadInstaller = $true
}

# TODO Move Move-CaaFileToVersionPath out of region
if ($downloadInstaller) {
    $outFile = Join-Path $env:TEMP $installerFileName
    Invoke-WebRequest -Uri $appInfo.InstallerUrl -OutFile $outFile
    if (-not (Test-CaaSha256Hash -Path $outFile -Sha256Hash $appInfo.InstallerSha256)) {
        Write-Error "SHA256Hash incorrect for downloaded file $outFile, stopping processing"
        return
    }
}

#endregion

Move-CaaFileToVersionPath -Path $outFile -PackageVersion $appInfo.PackageVersion -DestinationShare $installerShare -PackageIdentifier $appInfo.PackageIdentifier



#region create VM and Get IPaddress
$ipData = Get-CaaVmPrivateIpAddress -Name $packagingMachine
$ip = $ipdata.PrivateIpAddress
#endregion

#region Update template file

$formattedVersion = Format-CaaVersion -Version $appInfo.PackageVersion

$fullName = New-CaaMsixName -PackageIdentifier $appInfo.PackageIdentifier -Version $formattedVersion.Version -Architecture $appInfo.Architecture -CertHash $msixHash

$packageSaveLocation = Join-Path $tempPath ($FullName.Name + '.msix')
$templateSaveLocation = Join-Path $tempPath ($FullName.Name + '.xml')

$templateFile = $appInfo.PackageIdentifier + '.xml'

$templatePath = Join-Path $templateShare $templateFile

$silentInstall = Get-CaaSilentInstall -InstallerType $appInfo.InstallerType -InstallerSwitches $appInfo.InstallerSwitches.custom

$updateParams = @{
    Path                 = $templatePath
    InstallerPath        = $installerFilePath
    PackageSaveLocation  = $packageSaveLocation
    ComputerName         = $ip
    UserName             = $UserName
    Version              = $formattedVersion.Version
    PublisherName        = $certPublisher
    PublisherDisplayName = $PublisherDisplayName
    TemplateSaveLocation = $templateSaveLocation
    NoTemplate           = $true
    InstallerSwitches    = $silentInstall
}

$appInfo | Update-CaaMptTemplate @updateParams

#endregion


#region Convert to MSIX from installer

if (-not (Test-WSman -ComputerName $ip)) {
    #Enter-PSSession -ComputerName $ip -UseSSL
    Write-Error "WinRM not avilable on $ip"
}
#TODO disable Windows search on remote machine

cmdkey /generic:$ip /user:$UserName /pass:$machinePass | Out-Null

# $sessionOptions = New-PSSessionOption -SkipCNCheck
# New-PSSession -ComputerName $ip -Credential $userName -UseSSL -SessionOption $sessionOptions -EnableNetworkAccess
# Might need Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ip
# currently New-PSSession -ComputerName $ip -Credential $userName -SessionOption $sessionOptions -EnableNetworkAccess works without the -UseSSL

$secStringPassword = ConvertTo-SecureString $machinePass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

$sessionOptions = New-PSSessionOption -SkipCNCheck
$mySession = New-PSSession -ComputerName $ip -Credential $cred -SessionOption $sessionOptions -EnableNetworkAccess
$mySession | Enter-PSSession
$hostName = $env:COMPUTERNAME
# Do we need this if w ealready have the IP?
$hostIP = ( Get-NetAdapter | Get-NetIPAddress ).IPv4Address | Out-String
$srvCert = New-SelfSignedCertificate -DnsName $hostName, $hostIP -CertStoreLocation Cert:\LocalMachine\My
New-Item -Path WSMan:\localhost\Listener\ -Transport HTTPS -Address * -CertificateThumbPrint $srvCert.Thumbprint -Force
New-NetFirewallRule -Displayname 'WinRM - Powershell remoting HTTPS-In' -Name 'WinRM - Powershell remoting HTTPS-In' -Profile Any -LocalPort 5986 -Protocol TCP
Export-Certificate -Cert $srvCert -FilePath c:\SSL_PS_Remoting.cer
Exit-PSSession
Copy-Item -FromSession $mySession "C:\SSL_PS_Remoting.cer" -Destination "C:\SSL_PS_Remoting.cer"
Import-Certificate -FilePath "C:\SSL_PS_Remoting.cer" -CertStoreLocation Cert:\LocalMachine\root\
$mySession | Remove-PSSession

Disconnect-CaaRdpSession -packagingMachine $ip -UserName $UserName

#TODO start minimised
mstsc /v:$ip

while ((qwinsta /server:$ip | Where-Object { $_ -like "*$userBasic*active*" }).Count -eq 0) {
    Start-Sleep 1
}

Start-Sleep 1



$outputPackage = Start-Process MSIXPackagingTool.exe -ArgumentList "create-package --template $templatePath --machinePassword $machinePass" -Wait -Passthru -NoNewWindow

If ($outputPackage.ExitCode -ne 0) {
    Write-Error 'TODO: Write_Error'
    Disconnect-CaaRdpSession -packagingMachine $ip -UserName $UserName
    return
}

Disconnect-CaaRdpSession -packagingMachine $ip -UserName $UserName

Set-CaaMsixCertificate -Path $packageSaveLocation -CertificatePath $CertPath -CertificatePassword $certPass

if (-not (Test-Path $packageSaveLocation)) {
    Write-Error "$packageSaveLocation could not be found"
    return
}

#endregion

$moveInfo = Move-CaaFileToVersionPath -Path $packageSaveLocation -PackageVersion $formattedVersion.Version -DestinationShare $msixShare -PackageIdentifier $appInfo.PackageIdentifier -PassThru

#region create App attach
$resourceGroup = 'DeleteMe'
$Path = "\\avdtoolsmsix.file.core.windows.net\appattach\MSIXPackages\Microsoft.VisualStudioCode.Insiders\1.87.0.0\Microsoft.VisualStudioCode.Insiders_1.87.0.0_x64__479h0rr4v8y2t.msix"
try {
    $manifest = Read-CaaMsixManifest -Path $Path -ErrorAction Stop
}
catch {
    Write-Error "Manifest could not be  read from $Path, this may not be a complete Msix package."
    Return
}

$familyName = New-CaaMsixName -PackageIdentifier $manifest.Identity.Name -CertHash (Get-CaaPublisherHash -publisherName $manifest.Identity.Publisher)
$currentPackage = Get-AzWvdAppAttachPackage | Where-Object { $_.ImagePackageFamilyName -eq $familyName }

Import-AzWvdAppAttachPackageInfo -ResourceGroupName $resourceGroup -HostPoolName $HostPoolName

if (($currentPackage | Measure-Object).Count -eq 0 ) {
    New-AzWvdAppAttachPackage -ResourceGroupName $resourceGroup -HostPoolName $HostPoolName
}
else {
    Update-AzWvdAppAttachPackage -ResourceGroupName $resourceGroup -HostPoolName $HostPoolName
}
#endregion

Write-Output 'Done'