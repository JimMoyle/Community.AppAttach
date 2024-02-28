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
$UseWingetexe = $false

$EverGreenPackageID = 'MicrosoftVisualStudioCode'
$WpmPackageID = 'Microsoft.VisualStudioCode.Insiders'
#$InstallerArguments = '/MERGETASKS=!runcode'

$TemplateShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Templates\'
$InstallerShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Installers\'
$MsixShare = '\\avdtoolsmsix.file.core.windows.net\appattach\MSIXPackages\'
$CertPath = "\\avdtoolsmsix.file.core.windows.net\appattach\Templates\JimAdmin.pfx"
$TempPath = $env:TEMP

$packagingMachine = 'AAPack-2.AVD.Tools'
$UserName = 'User2@avd.tools'

$machinePass = Get-Content 'c:\JimM\machinePass.txt'

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
$appInfo = Get-CaaWpmRestApp -Id $WpmPackageID | Where-Object { $_.Architecture -eq 'x64' -and $_.Scope -eq 'machine' }

if ($appInfo.Count -ne 1) {
    Write-Error "More than One Package found for $WpmPackageID"
    return
}

if ($UseEverGreen) {
    $evergreenAppInfo = Get-evergreenapp $EverGreenPackageID | Where-Object { $_.channel -eq 'Insider' -and $_.Architecture -eq 'x64' -and $_.Platform -eq 'win32-x64' }
    if ($evergreenAppInfo.Count -ne 1) {
        Write-Error "More than One Package found for $evergreenAppInfo"
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
    # TODO Check for MSIX or Appx
    # TODO fix this
    $wingetexeAppInfo = 
    if ($wingetexeAppInfo.Count -ne 1) {
        Write-Error "More than One Package found for $evergreenAppInfo"
    }
    else {
        if ([version]$wingetexeAppInfo.Version -gt [version]$appInfo.PackageVersion) {
            $appInfo.PackageVersion = $wingetexeAppInfo.Version
            $appInfo.InstallerUrl = $wingetexeAppInfo.URI
            $appInfo.InstallerSha256 = $wingetexeAppInfo.Sha256
            $appInfo.Architecture = $wingetexeAppInfo.Architecture
        }
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
    if (Test-CaaSha256Hash -Path $outFile -Sha256Hash $appInfo.InstallerSha256) {
        
    }
    else {
        Write-Error "SHA256Hash incorrect for downloaded file $outFile, stopping processing"
    }
}

#endregion

# Move-CaaFileToVersionPath -Path $outFile -PackageVersion $appInfo.PackageVersion -DestinationShare $installerShare -PackageIdentifier $appInfo.PackageIdentifier

#region Update template file

$formattedVersion = Format-CaaVersion -Version $appInfo.PackageVersion

$FullName = New-CaaMsixFullName -PackageIdentifier $appInfo.PackageIdentifier -Version $formattedVersion.Version -Architecture $appInfo.Architecture -CertHash $msixHash

$packageSaveLocation = Join-Path $tempPath ($FullName.Name + '.msix')
$templateSaveLocation = Join-Path $tempPath ($FullName.Name + '.xml')

$templateFile = $appInfo.PackageIdentifier + '.xml'

$templatePath = Join-Path $templateShare $templateFile

$silentInstall = Get-CaaSilentInstall -InstallerType $appInfo.InstallerType -InstallerSwitches $appInfo.InstallerSwitches.custom

$updateParams = @{
    Path                 = $templatePath
    InstallerPath        = $installerFilePath
    PackageSaveLocation  = $packageSaveLocation
    ComputerName         = $packagingMachine
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

if (-not (Test-WSman -ComputerName $packagingMachine)) {
    #Enter-PSSession -ComputerName $packagingMachine -UseSSL
    Write-Error "WinRM not avilable on $packagingMachine"
}
#TODO disable Windows search on remote machine

cmdkey /generic:$packagingMachine /user:$UserName /pass:$machinePass | Out-Null

Disconnect-CaaRdpSession -packagingMachine $packagingMachine -UserName $UserName

#TODO start minimised
mstsc /v:$packagingMachine

while ((qwinsta /server:$packagingMachine | Where-Object { $_ -like "*$userBasic*active*" }).Count -eq 0) {
    Start-Sleep 1
}

Start-Sleep 1

$outputPackage = Start-Process MSIXPackagingTool.exe -ArgumentList "create-package --template $templatePath --machinePassword $machinePass" -Wait -Passthru -NoNewWindow

If ($outputPackage.ExitCode -ne 0) {
    Write-Error 'TODO: Write_Error'
    Disconnect-CaaRdpSession -packagingMachine $packagingMachine -UserName $UserName
    return
}

Disconnect-CaaRdpSession -packagingMachine $packagingMachine -UserName $UserName

Set-CaaMsixCertificate -Path $packageSaveLocation -CertificatePath $CertPath -CertificatePassword $certPass

if (-not (Test-Path $packageSaveLocation)) {
    Write-Error "$packageSaveLocation could not be found"
    return
}

#endregion

$moveInfo = Move-CaaFileToVersionPath -Path $packageSaveLocation -PackageVersion $formattedVersion.Version -DestinationShare $msixShare -PackageIdentifier $appInfo.PackageIdentifier -PassThru

#region create App attch


#endregion

Write-Output 'Done'