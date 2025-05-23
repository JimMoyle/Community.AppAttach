



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

$JsonPath = 'D:\GitHub\Community.AppAttach\AppJson\Microsoft.WindowsTerminal.Preview.json'


$TemplateShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Templates\'
$InstallerShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Installers\'
$MsixShare = '\\avdtoolsmsix.file.core.windows.net\appattach\MSIXPackages\'
$diskImageShare = '\\avdtoolsmsix.file.core.windows.net\appattach\AppAttachPackages'
$CertPath = "\\avdtoolsmsix.file.core.windows.net\appattach\Templates\JimMoyleCodeSigningCert.pfx"
$TempPath = $env:TEMP
$Location = 'uksouth'

$UserName = 'JimAdmin'
$resourceGroupName = 'DeleteMe'

$machinePass = Get-Content 'c:\JimM\machinePass.txt'

$HostPoolName = 'MSIXPackage'


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

$appLocation = Get-Content $JsonPath | ConvertFrom-Json

$appInfo = switch ($appLocation) {
    {$null -ne $_.WingetId} { $appInfo = Get-CaaWingetExeApp -Id $_.WingetId; break }
    {$null -ne $_.StoreId} { $appInfo = Get-CaaStoreApp -Id $_.WingetId; break }
    {$null -ne $_.EvergreenId} { $appInfo = Get-EvergreenApp -Id $_.EvergreenId }
    Default {}
}


#$appInfo = Get-CaaWpmRestApp -Id $WpmPackageID | Where-Object { $_.Architecture -eq 'x64' -and $_.Scope -eq 'Machine' }

if ($appInfo.Count -gt 1) {
    Write-Error "More than One Package found for $WpmPackageID please adjust your filter"
    return
}

if ($UseEverGreen) {
    $evergreenAppInfo = Get-evergreenapp $EverGreenPackageID #| Where-Object { $_.channel -eq 'Insider' -and $_.Architecture -eq 'x64' -and $_.Platform -eq 'win32-x64' }
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

        if (($appInfo | Measure-Object).Count -eq 0) {
            $appInfo = $wingetexeAppInfo | Select-Object -Property *, @{name = 'PackageVersion'; e = { $_.Version } }, @{name = 'InstallerUrl'; e = { $_.'Installer Url' } }, @{name = 'InstallerSha256'; e = { $_.'Installer SHA256' } }
        }
        else {
            if ([version]$wingetexeAppInfo.Version -gt [version]$appInfo.PackageVersion) {
                $appInfo.PackageVersion = $wingetexeAppInfo.Version
                $appInfo.InstallerUrl = $wingetexeAppInfo.'Installer Url'
                $appInfo.InstallerSha256 = $wingetexeAppInfo.'Installer SHA256'
                #$appInfo.Architecture = $wingetexeAppInfo.Architecture
            }
        }
    }
    catch {
        'TODO: search store for a likely candidate'
    }
}

$installerFileName = $appInfo.InstallerUrl.Split('/')[-1]

if (Test-CaaIsMsix -Name $installerFileName) {
    $targetShare = $MsixShare
}
else {
    $targetShare = $InstallerShare
}

# Not using Join-Path as there are nore than 2 items
$installerFilePath = [IO.Path]::Combine($targetShare, $appInfo.PackageIdentifier, $appInfo.PackageVersion, $installerFileName)

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


if ($downloadInstaller) {
    $outFile = Join-Path $env:TEMP $installerFileName
    Invoke-WebRequest -Uri $appInfo.InstallerUrl -OutFile $outFile
    if (-not (Test-CaaSha256Hash -Path $outFile -Sha256Hash $appInfo.InstallerSha256)) {
        Write-Error "SHA256Hash incorrect for downloaded file $outFile, stopping processing"
        return
    }
    $initialMove = Move-CaaFileToVersionPath -Path $outFile -PackageVersion $appInfo.PackageVersion -DestinationShare $targetShare -PackageIdentifier $appInfo.PackageIdentifier -PassThru
}


if ($AppUrl) {
    $outFile = $AppUrl.Split('/')[-1]
    Invoke-WebRequest -Uri $AppUrl -OutFile $outFile
    if (Test-CaaIsMsix -Name $outFile) {
        $targetShare = $MsixShare
        $urlManifest = Read-CaaMsixManifest $outfile
        $appInfo = [PSCustomObject]@{
            PackageVersion = $urlManifest
            PackageIdentifier = $urlManifest
            InstallerSha256 = $urlManifest
        }
    }
    else {
        $targetShare = $InstallerShare
    }
    $initialMove = Move-CaaFileToVersionPath -Path $outFile -PackageVersion $appInfo.PackageVersion -DestinationShare $targetShare -PackageIdentifier $appInfo.PackageIdentifier -PassThru
}

#endregion

if (-not $isMsix) {

    #region create VM and Get IPaddress
    $packagingMachineName = 'CaaTest-1'
    $param = @{
        Name                     = $packagingMachineName
        VMSize                   = 'Standard_B2als_v2'
        GalleryName              = 'MsixPackagerGallery'
        ImageDefinition          = 'MsixPackagingImageDefinition'
        ResourceGroupName        = $resourceGroupName
        VnetName                 = 'AVDPermanent-vnet'
        NetworkResourceGroupName = 'AVDPermanent'
        GalleryResourceGroupName = 'AVDPermanent'
        SubnetId                 = 'default'
        Location                 = $Location
    }

    $vm = New-CaaVmFromGallery @param
    $ipData = Get-CaaVmPrivateIpAddress -Name $packagingMachineName
    $ip = $ipdata.PrivateIpAddress
    #endregion

    #region Update template file

    $formattedVersion = Format-CaaVersion -Version $appInfo.PackageVersion

    $fullName = New-CaaMsixName -PackageIdentifier $appInfo.PackageIdentifier -Version $formattedVersion.Version -Architecture $appInfo.Architecture -CertHash $msixHash

    $packageSaveLocation = Join-Path $tempPath ($FullName.Name + '.msix')
    $templateSaveLocation = Join-Path $tempPath ($FullName.Name + '.xml')

    $templateFile = $appInfo.PackageIdentifier + '.xml'

    $templatePath = Join-Path $templateShare $templateFile

    if ( ($appInfo.InstallerSwitches.custom | Measure-Object).Count -eq 1 ) {
        $silentInstall = Get-CaaSilentInstall -InstallerType $appInfo.InstallerType -InstallerSwitches $appInfo.InstallerSwitches.custom
    }
    else {
        $silentInstall = Get-CaaSilentInstall -InstallerType $appInfo.InstallerType
    }

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

    #if (-not (Test-WSman -ComputerName $ip)) {
    #Enter-PSSession -ComputerName $ip -UseSSL
    #    Write-Error "WinRM not avilable on $ip"
    #}
    #TODO disable Windows search on remote machine

    cmdkey /generic:$ip /user:$UserName /pass:$machinePass | Out-Null

    # $sessionOptions = New-PSSessionOption -SkipCNCheck
    # New-PSSession -ComputerName $ip -Credential $userName -UseSSL -SessionOption $sessionOptions -EnableNetworkAccess
    # Might need Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ip
    # currently New-PSSession -ComputerName $ip -Credential $userName -SessionOption $sessionOptions -EnableNetworkAccess works without the -UseSSL

    $secStringPassword = ConvertTo-SecureString $machinePass -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $ip -Concatenate -Force
    Start-Sleep 3
    $sessionOptions = New-PSSessionOption -SkipCNCheck

    $mysession = $null
    $timespan = (Get-Date).AddSeconds(30)

    while ($null -eq $mysession -and (Get-Date) -lt $timespan) {
        try {
            $mySession = New-PSSession -ComputerName $ip -Credential $cred -SessionOption $sessionOptions -EnableNetworkAccess -ErrorAction Stop
        }
        catch {
            Start-Sleep 1
        }
    }

    if ($null -eq $mysession) {
        Write-error "Could not connect to $ip using New-PSession"
        $vm | Remove-CaaVmFromGallery
        return
    }

    $filePath = "C:\SSL_PS_Remoting.cer"
    $scriptblock = {
        $hostName = $env:COMPUTERNAME
        $hostIP = ( Get-NetAdapter | Get-NetIPAddress ).IPv4Address | Out-String
        $srvCert = New-SelfSignedCertificate -DnsName $hostName, $hostIP -CertStoreLocation Cert:\LocalMachine\My
        New-Item -Path WSMan:\localhost\Listener\ -Transport HTTPS -Address * -CertificateThumbPrint $srvCert.Thumbprint -Force
        New-NetFirewallRule -Displayname 'WinRM - Powershell remoting HTTPS-In' -Name 'WinRM - Powershell remoting HTTPS-In' -Profile Any -LocalPort 5986 -Protocol TCP
        Export-Certificate -Cert $srvCert -FilePath c:\SSL_PS_Remoting.cer
    }
    Invoke-Command -Session $mySession -ScriptBlock $scriptblock
    Copy-Item -FromSession $mySession $filePath -Destination $filePath
    Import-Certificate -FilePath $filePath -CertStoreLocation Cert:\LocalMachine\root\ | Out-Null
    Remove-Item $filePath -Force
    $mySession | Remove-PSSession

    #TODO start minimised
    mstsc /v:$ip

    Start-Sleep 3

    $outputPackage = Start-Process MSIXPackagingTool.exe -ArgumentList "create-package --template $templatePath --machinePassword $machinePass" -Wait -Passthru -NoNewWindow

    If ($outputPackage.ExitCode -ne 0) {
        $vm | Remove-CaaVmFromGallery
        Write-Error 'TODO: Write_Error'
        return
    }

    Set-CaaMsixCertificate -Path $packageSaveLocation -CertificatePath $CertPath -CertificatePassword $certPass

    if (-not (Test-Path $packageSaveLocation)) {
        Write-Error "$packageSaveLocation could not be found"
        return
    }

    $vm | Remove-CaaVmFromGallery

    #endregion
    $moveInfo = Move-CaaFileToVersionPath -Path $packageSaveLocation -PackageVersion $formattedVersion.Version -DestinationShare $msixShare -PackageIdentifier $appInfo.PackageIdentifier -PassThru

    $msixPackagePath = $moveInfo.Path
}
else {
    $msixPackagePath = $initialMove.Path
}

#region create App attach

try {
    $manifest = Read-CaaMsixManifest -Path $msixPackagePath -ErrorAction Stop
}
catch {
    Write-Error "Manifest could not be read from $msixPackagePath, this may not be a complete Msix package."
    return
}

$target = Convert-CaaMsixToDisk -Path $msixPackagePath -DestinationPath $env:TEMP -PassThru

$diskMoveInfo = Move-CaaFileToVersionPath -Path $target.FullName -PackageVersion $manifest.Identity.Version -DestinationShare $diskImageShare -PackageIdentifier $manifest.Identity.Name -PassThru -IncludeExtensionInTargetPath

$familyName = New-CaaMsixName -PackageIdentifier $manifest.Identity.Name -CertHash (Get-CaaPublisherHash -publisherName $manifest.Identity.Publisher)
$currentPackage = Get-AzWvdAppAttachPackage | Where-Object { $_.ImagePackageFamilyName -eq $familyName.Name }

$importInfo = Import-AzWvdAppAttachPackageInfo -ResourceGroupName $resourceGroupName -HostPoolName $HostPoolName -Path $diskMoveInfo.Path

if (($importInfo | Measure-Object).Count -gt 1 ) {

    switch ($true) {
        { ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x64_*" } | Measure-Object).Count -ge 1 } {
            $correctPackage = ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x64_*" })[0]
            break
        }
        { ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_neutral_*" } | Measure-Object).Count -ge 1 } {
            $correctPackage = ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_neutral_*" })[0]
            break
        }
        { ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x86_*" } | Measure-Object).Count -ge 1 } {
            $correctPackage = ($importInfo | Where-Object { $_.ImagePackageFullName -like "*_x86_*" })[0]
            break
        }
        Default { $correctPackage = $importInfo[0] }
    }
}
else {
    $correctPackage = $importInfo
}

if (($currentPackage | Measure-Object).Count -eq 0 ) {
    $parameters = @{
        Name                            = $correctPackage.ImagePackageName
        ResourceGroupName               = $resourceGroupName
        Location                        = $Location
        FailHealthCheckOnStagingFailure = 'NeedsAssistance'
        ImageIsRegularRegistration      = $false
        ImageDisplayName                = $correctPackage.ImagePackageName.Replace(($correctPackage.ImagePackageName.split('.')[0] + '.'), '')
        ImageIsActive                   = $true
    }
    
    New-AzWvdAppAttachPackage -AppAttachPackage $correctPackage @parameters
}
else {
    Update-AzWvdAppAttachPackage -AppAttachPackage $correctPackage -ResourceGroupName $resourceGroupName -Name $currentPackage.Name
}

#endregion

#cleanup
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value '' -Force

Write-Output 'Done'