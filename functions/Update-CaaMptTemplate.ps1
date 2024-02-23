function Update-CaaMptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true)]
        [ValidateScript({
                if (-Not ($_ | Test-Path) ) { throw "File does not exist" }
                if (-Not ($_ | Test-Path -PathType Leaf) ) { throw "The Path argument must be a file. Folder paths are not allowed." }
                if ($_ -notlike "*.xml") {
                    throw "Template files must be in xml format, $_ does not have an xml extension"
                }
                return $true
            })]
        [Alias('PSPath')]
        [string]$Path,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$PackageSaveLocation,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$InstallerPath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$ComputerName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$UserName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [version]$PackageVersion,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$Publisher,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$PackageDisplayName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$ShortDescription
    )

    # Read the XML file
    $template = [xml](Get-Content -Path $Path)

    # Perform necessary changes to the XML

    # Replace the MsixPackagingToolTemplate namespace
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns", "http://schemas.microsoft.com/appx/msixpackagingtool/template/2018")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V2", "http://schemas.microsoft.com/msix/msixpackagingtool/template/1904")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V3", "http://schemas.microsoft.com/msix/msixpackagingtool/template/1907")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V4", "http://schemas.microsoft.com/msix/msixpackagingtool/template/1910")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V5", "http://schemas.microsoft.com/msix/msixpackagingtool/template/2001")

    # Save the modified XML to the output path
    $template.Save($Path)
    
    # Read the XML file
    $template = [xml](Get-Content -Path $Path)

    if ( $null -eq $template.MsixPackagingToolTemplate.RemoteMachine ) {
        #build new node by hand and force it to be an XML object with the relevant schema changes v2: v3: etc.
        $remoteXmlText = "<RemoteMachine ComputerName=`"$ComputerName`" Username=`"$UserName`"/>"
        [xml]$remoteXmlNode = "<dummySchema xmlns='http://schemas.microsoft.com/msix/msixpackagingtool/template/1904'>$remoteXmlText</dummySchema>"

        $foundNode = $template.MsixPackagingToolTemplate.Installer
        $importNode = $template.ImportNode($remoteXmlNode.dummySchema.RemoteMachine, $true)
        $template.MsixPackagingToolTemplate.InsertAfter($importNode, $foundNode)
    }
    else{
        $template.MsixPackagingToolTemplate.RemoteMachine.ComputerName = $ComputerName
        $template.MsixPackagingToolTemplate.RemoteMachine.UserName = $UserName
    }

    if ($ShortDescription){
        $template.MsixPackagingToolTemplate.PackageInformation.PackageDescription = $ShortDescription
    }

    if ($PackageVersion){
        $verCount = $PackageVersion.ToString().Split('.').Count
        if ($verCount -lt 4) {
            (4 - $verCount)..1 | ForEach-Object {
                $PackageVersion = $PackageVersion.ToString() + '.0'
            }
        }
        if ($verCount -gt 4) {
            $PackageVersion = $PackageVersion.ToString() -replace "^(\d+(?:\.\d+){0,3})(?:\.\d+)*$", $matches[1]
        }
        $template.MsixPackagingToolTemplate.PackageInformation.Version = $PackageVersion.ToString()
    }
    else{
        $template.MsixPackagingToolTemplate.PackageInformation.Version = $template.MsixPackagingToolTemplate.PackageInformation.Version++
    }

    if (-not ($PackageDisplayName)){
        $nameSplit = $template.MsixPackagingToolTemplate.PackageInformation.PackageName.Split('.')
        if ($nameSplit.Count -gt 1){
            (1 - $nameSplit.Count)..-1 | ForEach-Object {
                $PackageDisplayName += ($nameSplit[$_] + '.')
            }
        }
        $PackageDisplayName = $PackageDisplayName.TrimEnd('.')
    }
    
    $template.MsixPackagingToolTemplate.Installer.Path = $InstallerPath
    $template.MsixPackagingToolTemplate.SaveLocation.PackagePath = $PackageSaveLocation

    # Save the modified XML to the output path
    $template.Save($Path)
}