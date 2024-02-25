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
        [String]$Path,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$InstallerPath,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$ComputerName,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$UserName,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateScript({ if ($_.ToString().Split('.').Count -eq 4) { return $true }; throw 'Version must have 4 numbers 1.2.3.4' })]
        [Alias('PackageVersion')]
        [Version]$Version,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$PackageSaveLocation,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$TemplateSaveLocation,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$PublisherName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$PublisherDisplayName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$PackageDisplayName,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [String]$ShortDescription
    )

    # Read the XML file
    $template = [xml](Get-Content -Path $Path)

    # Replace the MsixPackagingToolTemplate namespace as we need the more recent namespaces to make the full functionality of remote packaging work.
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns", "http://schemas.microsoft.com/appx/msixpackagingtool/template/2018")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V2", "http://schemas.microsoft.com/msix/msixpackagingtool/template/1904")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V3", "http://schemas.microsoft.com/msix/msixpackagingtool/template/1907")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V4", "http://schemas.microsoft.com/msix/msixpackagingtool/template/1910")
    $template.MsixPackagingToolTemplate.SetAttribute("xmlns:V5", "http://schemas.microsoft.com/msix/msixpackagingtool/template/2001")

    # Save the modified XML to the output path
    $template.Save($Path)
    
    # Read the XML file
    $template = [xml](Get-Content -Path $Path)

    $template.MsixPackagingToolTemplate.PackageInformation.Version = $Version.ToString()
    $template.MsixPackagingToolTemplate.Installer.Path = $InstallerPath
    $template.MsixPackagingToolTemplate.SaveLocation.PackagePath = $PackageSaveLocation

    if ($TemplateSaveLocation){
        $template.MsixPackagingToolTemplate.PackageInformation.TemplatePath = $TemplateSaveLocation
    }
    
    if ($ShortDescription){
        $template.MsixPackagingToolTemplate.PackageInformation.PackageDescription = $ShortDescription
    }

    if ($PublisherDisplayName){
        $template.MsixPackagingToolTemplate.PackageInformation.PublisherDisplayName = $PublisherDisplayName
    }

    if ($PublisherName){
        $template.MsixPackagingToolTemplate.PackageInformation.PublisherName = $PublisherName
    }

    if ($NoTemplate){
        $template.MsixPackagingToolTemplate.Settings.GenerateCommandLineFile = 'false'
    }

    # This section isn't there by default in the template so we need to create it if needed
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


    <##
    # TODO DeviceGuardSigning
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
   ##>

    if (-not ($PackageDisplayName)){
        $nameSplit = $template.MsixPackagingToolTemplate.PackageInformation.PackageName.Split('.')
        if ($nameSplit.Count -gt 1){
            (1 - $nameSplit.Count)..-1 | ForEach-Object {
                $PackageDisplayName += ($nameSplit[$_] + '.')
            }
        }
        $PackageDisplayName = $PackageDisplayName.TrimEnd('.')
    }


    # Save the modified XML to the output path
    $template.Save($Path)
}