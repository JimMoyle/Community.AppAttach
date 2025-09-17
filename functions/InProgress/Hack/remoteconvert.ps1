function ConvertTo-Msix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplatePath,

        [Parameter(Mandatory,
        ValueFromPipeline=$true
        )]
        [string]$WingetId,

        [Parameter(Mandatory)]
        [string]$ExportRootPath,

        [Parameter(Mandatory)]
        [string]$CertHash,

        [Parameter(Mandatory)]
        [string]$ConverterMachineName,

        [Parameter(Mandatory)]
        [string]$UserName,

        [Parameter(Mandatory)]
        [string]$MachinePass,

        [Parameter(Mandatory)]
        [string]$CertPublisherName
    )
    begin {
        
        #requires -modules 'powershell-yaml', 'Microsoft.WinGet.Client'
        # Import required scripts
        . .\functions\InProgress\Hack\Update-CaaMptTemplate.ps1
        . .\functions\InProgress\Hack\New-CaaMsixName.ps1
        . .\functions\InProgress\Hack\Format-CaaVersion.ps1
    }
    process {


        $downloadFolder = Join-Path -Path $ExportRootPath -ChildPath $WingetId
        $TemplateSaveLocation = Join-Path -Path $downloadFolder -ChildPath ("$WingetId" + ".xml")

        New-Item -Path $downloadFolder -ItemType Directory -Force | Out-Null

        $download = Export-WinGetPackage -Id $WingetId -DownloadDirectory $downloadFolder -MatchOption Equals

        if ($download.status -ne 'OK') {
            Write-Error "Failed to download package"
            return
        }

        $yamlfile = Get-ChildItem -Path $downloadFolder -File | Where-Object { $_.Extension -eq '.yaml' }
        $installfile = Get-ChildItem -Path $downloadFolder -File | Where-Object { $_.Extension -ne '.yaml' -and $_.Extension -ne '.xml' }

        $yaml = Get-Content -Raw -Path $yamlfile.FullName
        $yamlObject = ConvertFrom-Yaml -Yaml $yaml

        $version = $yamlObject.PackageVersion
        $formattedVersion = (Format-CaaVersion -Version $version).Version
        $fileName = New-CaaMsixName -PackageIdentifier $yamlObject.PackageIdentifier -CertHash $CertHash -Version $formattedVersion -Architecture $yamlObject.Installers.Architecture

        $params = @{
            Path                 = $TemplatePath
            PackageName          = $yamlObject.PackageIdentifier
            PackageDisplayName   = $yamlObject.PackageName
            InstallerPath        = $installfile.FullName.ToString()
            ComputerName         = $ConverterMachineName
            UserName             = $UserName
            Version              = $formattedVersion
            TemplateSaveLocation = $TemplateSaveLocation
            InstallerSwitches    = $yamlObject.Installers.InstallerSwitches.Silent + ' ' + $yamlObject.Installers.InstallerSwitches.Custom
            PublisherName        = $CertPublisherName
            PublisherDisplayName = $yamlObject.Publisher
            ShortDescription     = $yamlObject.ShortDescription
            PackageSaveLocation  = Join-Path -Path $downloadFolder -ChildPath $fileName.Name
        }
        Update-CaaMptTemplate @params

        $outputPackage = Start-Process MSIXPackagingTool.exe -ArgumentList "create-package --template $TemplateSaveLocation --machinePassword $MachinePass" -Wait -Passthru -NoNewWindow
        Write-Output $outputPackage
        Remove-Item -Path $installfile.FullName -Force -Recurse
    }
    end {}
}

$params = @{
    TemplatePath         = 'C:\GitHub\Community.AppAttach-1\functions\InProgress\Hack\RemoteConvertTemplate.xml'
    #WingetId             = 'VideoLAN.VLC'
    ExportRootPath       = 'C:\JimM\WingetDownloads'
    CertHash             = '3ap7qhtey6z62'
    ConverterMachineName = 'Target-0'
    UserName             = 'JimAdmin@jimmoyle.com'
    MachinePass          = (Get-Content "C:\JimM\pass.txt")
    CertPublisherName    = 'CN=JimMoyleMsixCerts'
}

$jWingetIds = Get-Content 'C:\JimM\J.txt'
$jWingetIds | ConvertTo-Msix @params
