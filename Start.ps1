$Functions = @( Get-ChildItem -Path Functions\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in $Functions) {
    Try {
        Write-Information "Importing $($Import.FullName)"
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

$UseEverGreen = $true

$EverGreenPackageID = 'MicrosoftVisualStudioCode'
$WpmPackageID = 'Microsoft.VisualStudioCode.Insiders'

$templateShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Templates\'
$installerShare = '\\avdtoolsmsix.file.core.windows.net\appattach\Installers\'
$msixShare = '\\avdtoolsmsix.file.core.windows.net\appattach\MSIXPackages\'
$certPath = "\\avdtoolsmsix.file.core.windows.net\appattach\Templates\JimAdmin.pfx"
$tempPath = $env:TEMP

$packagingMachine = 'AAPack-2.AVD.Tools'
$UserName = 'User2@avd.tools'
$timeStampServer = 'http://timestamp.digicert.com'

$certPass = ConvertTo-SecureString (Get-Content 'c:\JimM\certPass.txt') -AsPlainText -Force
$certInfo = Get-PfxCertificate $certPath -Password $certPass
$publisherName = ($certInfo -split '\r?\n')[1].Trim()
$msixHash = Get-CaaPublisherHash $publisherName
$PublisherDisplayName = $publisherName.Split(',')[0].Split('=')[-1]

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

$installerFileName = $appInfo.InstallerUrl.Split('/')[-1]

# Not using Join-Path as there are nore than 2 items
$installerFilePath = [IO.Path]::Combine($installerShare, $appInfo.PackageIdentifier, $appInfo.PackageVersion, $installerFileName)

if (Test-Path $installerFilePath){
    if (Test-CaaSha65Hash -Path $installerFilePath -Sha256Hash $appInfo.InstallerSha256) {
        $downloadInstaller = $false
    }
    else{
        Remove-Item $installerFilePath -Force -Confirm:$false
        $downloadInstaller = $true
    }
}

if ($downloadInstaller) {
    $outFile = Join-Path $env:TEMP $installerFileName
    Invoke-WebRequest -Uri $appInfo.InstallerUrl -OutFile $outFile
    if (Test-CaaSha65Hash -Path $outFile -Sha256Hash $appInfo.InstallerSha256) {
        Move-CaaFileToVersionPath -Path $outFile -PackageVersion $appInfo.PackageVersion -DestinationShare $installerShare -PackageIdentifier $appInfo.PackageIdentifier
    }
    else{
        Write-Error "SHA256Hash incorrect for downloaded file $outFile, stopping processing"
    }
}

$formattedVersion = Format-CaaVersion -Version $appInfo.PackageVersion

$FullName = New-CaaMsixFullName -PackageIdentifier $appInfo.PackageIdentifier -Version $formattedVersion.Version -Architecture $appInfo.Architecture -CertHash $msixHash

$packageSaveLocation = Join-Path $tempPath ($FullName.Name + '.msix')
$templateSaveLocation = Join-Path $tempPath ($FullName.Name + '.xml')

$templateFile = $appInfo.PackageIdentifier + '.xml'

$templatePath = Join-Path $templateShare $templateFile

$updateParams = @{
    Path                 = $templatePath
    InstallerPath        = $installerFilePath
    PackageSaveLocation  = $packageSaveLocation
    ComputerName         = $packagingMachine
    UserName             = $UserName
    Version              = $formattedVersion.Version
    PublisherName        = $publisherName
    PublisherDisplayName = $PublisherDisplayName
    TemplateSaveLocation = $templateSaveLocation
}

$appInfo | Update-CaaMptTemplate @updateParams

$machinePass = Get-Content 'c:\JimM\machinePass.txt'

if (-not (Test-WSman -ComputerName $packagingMachine)) {
    #Enter-PSSession -ComputerName $packagingMachine -UseSSL
    Write-Error "WinRM not avilable on $packagingMachine"
}
#TODO disable Windows search on remote machine

cmdkey /generic:$packagingMachine /user:$UserName /pass:$machinePass

mstsc /v:$packagingMachine

while ((qwinsta /server:$packagingMachine | Where-Object { $_ -like "*$userBasic*active*" }).Count -eq 0) {
    Start-Sleep 1
}

Start-Sleep 1

& MSIXPackagingTool.exe create-package --template $templatePath --machinePassword $machinePass

$userBasic = $userName.Split('@')[0]

$sessionInfo = qwinsta /server:$packagingMachine | Where-Object { $_ -like "*$userBasic*active*" }
$sessionId = $sessionInfo.split() | Where-Object { $_ -match "^\d+$" }
LOGOFF $sessionId /server:$packagingMachine


if (Test-Path $packageSaveLocation) {
    Move-CaaFileToVersionPath -Path $packageSaveLocation -PackageVersion $formattedVersion.Version -DestinationShare $msixShare -PackageIdentifier $appInfo.PackageIdentifier
}
else {
    Write-Error "$packageSaveLocation could not be found"
}

Write-Output 'Done'