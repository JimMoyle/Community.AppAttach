#requires -modules 'powershell-yaml', 'microsoft.winget.client'

. .\functions\InProgress\Hack\Update-CaaMptTemplate.ps1
. .\functions\Private\New-CaaMsixName.ps1
. .\functions\Private\Format-CaaVersion.ps1

$TemplatePath = "C:\GitHub\Community.AppAttach-1\functions\InProgress\Hack\RemoteConvertTemplate.xml"
$WingetId = 'Microsoft.SQLServerManagementStudio.21'
$ExportRootPath = "C:\JimM\WingetDownloads"
$CertHash = '3ap7qhtey6z62'
$ConverterMachineName = 'Target-0'
$UserName = 'jimadmin@jimoyle.com'
$machinePass = get-content "c:\jimm\pass.txt"

#script

$downloadFolder = Join-Path -Path $ExportRootPath -ChildPath $WingetId
$TemplateSaveLocation = Join-Path -Path $downloadFolder -ChildPath ("$WingetId" + ".xml")

New-Item -Path $downloadFolder -ItemType Directory -Force | Out-Null

$download = Export-WinGetPackage -Id $WingetId -DownloadDirectory $downloadFolder -MatchOption Equals

if ($download.status -ne 'OK') {
    Write-Error "Failed to download package"
    return
}

$yamlfile = Get-ChildItem -Path $downloadFolder  | where-object {$_.Extension -eq '.yaml'}
$installfile = Get-ChildItem -Path $downloadFolder  | where-object {$_.Extension -ne '.yaml' -and $_.Extension -ne '.xml'}

$yaml = Get-Content -Raw -Path $yamlfile.FullName

$yamlObject = ConvertFrom-Yaml -Yaml $yaml

$version = $yamlObject.PackageVersion
$formattedVersion = (Format-CaaVersion -Version $version).Version
$fileName = New-CaaMsixName -PackageIdentifier $yamlObject.PackageIdentifier -CertHash $CertHash -Version $formattedVersion -Architecture $yamlObject.Installers.Architecture
$params = @{
    Path = $TemplatePath
    PackageName = $yamlObject.PackageIdentifier
    PackageDisplayName = $yamlObject.PackageName
    InstallerPath = $Installfile.FullName.ToString()
    ComputerName = $ConverterMachineName
    UserName = $UserName
    Version = $formattedVersion
    TemplateSaveLocation = $TemplateSaveLocation
    InstallerSwitches = $yamlObject.Installers.InstallerSwitches.Silent + ' ' + $yamlObject.Installers.InstallerSwitches.Custom
    PublisherName = $yamlObject.Publisher
    PublisherDisplayName = $yamlObject.Publisher
    ShortDescription = $yamlObject.ShortDescription
    PackageSaveLocation = Join-Path -Path $downloadFolder -ChildPath $fileName
}
Update-CaaMptTemplate @params



$outputPackage = Start-Process MSIXPackagingTool.exe -ArgumentList "create-package --template $templatePath --machinePassword $machinePass" -Wait -Passthru -NoNewWindow