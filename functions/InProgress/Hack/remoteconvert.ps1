#requires -modules 'powershell-yaml', 'microsoft.winget.client'

$TemplatePath = "C:\JimM\insiders-template.yaml"
$WingetId = 'Microsoft.SQLServerManagementStudio.21'
$ExportRootPath = "C:\JimM\WingetDownloads"
$CertHash = '3ap7qhtey6z62'
$ConverterMachineName = 'Target-0'
$UserName = 'jimadmin@jimoyle.com'

#script

$downloadFolder = Join-Path -Path $ExportRootPath -ChildPath $WingetId
$TemplateSaveLocation = Join-Path -Path $ExportRootPath -ChildPath ("$WingetId" + ".xml")

New-Item -Path $downloadFolder -ItemType Directory -Force | Out-Null

$download = Export-WinGetPackage -Id $WingetId -DownloadDirectory $downloadFolder -MatchOption Equals

if ($download.status -ne 'OK') {
    Write-Error "Failed to download package"
    return
}

$yamlfile = Get-ChildItem -Path $downloadFolder  | where-object {$_.Extension -eq '.yaml'}

$yaml = Get-Content -Raw -Path $yamlfile.FullName

$yamlObject = ConvertFrom-Yaml -Yaml $yaml

$version = $yamlObject.PackageVersion
$formattedVersion = (Format-CaaVersion -Version $version).Version
$fileName = New-CaaMsixName -PackageIdentifier $yamlObject.PackageIdentifier -CertHash $CertHash -Version $formattedVersion -Architecture $yamlObject.Installers.Architecture
$params = @{
    Path = $TemplatePath
    ComputerName = $ConverterMachineName
    UserName = $UserName
    Version = $formattedVersion
    TemplateSaveLocation = $TemplateSaveLocation
    InstallerSwitches = $yamlObject.Installers.InstallerSwitches.Silent + ' ' + $yamlObject.Installers.InstallerSwitches.Custom
    Publisher = $yamlObject.Publisher
    PublisherDisplayName = $yamlObject.PublisherDisplayName
    PackageDisplayName = $yamlObject.PackageDisplayName
    ShortDescription = $yamlObject.ShortDescription
    PackageSaveLocation = Join-Path -Path $downloadFolder -ChildPath $fileName
}
Update-CaaMptTemplate @params