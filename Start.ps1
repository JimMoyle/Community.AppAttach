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
$publisher = Get-PfxCertificate $certPath -Password $certPass
$msixHash = Get-CaaPublisherHash $publisher.Subject

$appInfo = Get-CaaWpmRestApp -Id $WpmPackageID | Where-Object {$_.Architecture -eq 'x64' -and $_.Scope -eq 'machine'}

$installerFileName = $appInfo.InstallerUrl.Split('/')[-1]

# Not using Join-Path as there are nore than 2 items
$installerFilePath = [IO.Path]::Combine($installerShare, $appInfo.PackageIdentifier, $appInfo.PackageVersion, $installerFileName)

if (-not (Test-Path $installerFilePath)){
    $outFile = Join-Path $env:TEMP $installerFileName
    Invoke-WebRequest -Uri $appInfo.InstallerUrl -OutFile $outFile
    Move-CaaFileToVersionPath -Path $outFile -PackageVersion $appInfo.PackageVersion -DestinationShare $installerShare -PackageIdentifier $appInfo.PackageIdentifier
}

$formattedVersion = Format-CaaVersion -Version $appInfo.PackageVersion

$FullName = New-CaaMsixFullName -PackageIdentifier $appInfo.PackageIdentifier -Version $formattedVersion.Version -Architecture $appInfo.Architecture -CertHash $msixHash

$packageSaveLocation = Join-Path $tempPath ($FullName.Name + '.msix')

$templateFile = $appInfo.PackageIdentifier + '.xml'

$templatePath = Join-Path $templateShare $templateFile

$appInfo | Update-CaaMptTemplate -Path $templatePath -InstallerPath $installerFilePath -PackageSaveLocation $packageSaveLocation -ComputerName $packagingMachine -UserName $UserName -Version $formattedVersion

$machinePass = Get-Content 'c:\JimM\machinePass.txt'

if (-not (Test-WSman -ComputerName $packagingMachine)) {
    #Enter-PSSession -ComputerName $packagingMachine -UseSSL
    Write-Error "WinRM not avilable on $packagingMachine"
}
#TODO disable Windows search on remote machine

& MSIXPackagingTool.exe create-package --template $templatePath --machinePassword $machinePass

if (Test-Path $packageSaveLocation) {
    Move-CaaFileToVersionPath -Path $packageSaveLocation -PackageVersion $formattedVersion.Version -DestinationShare $msixShare -PackageIdentifier $appInfo.PackageIdentifier
}
else{
    Write-Error "$packageSaveLocation could not be found"
}

Write-Output 'Done'