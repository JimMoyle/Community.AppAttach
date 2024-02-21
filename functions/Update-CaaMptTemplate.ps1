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
                    throw "Template files must be in xml format, this file does not have an xml extension"
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
        [string]$UserName
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

    # Perform necessary changes to the XML


    #build new node by hand and force it to be an XML object
    [xml]$newNode = @"
<RemoteMachine ComputerName="$ComputerName" Username="$UserName" EnableAutoLogon="true"/>
"@
$foundNode = $template.MsixPackagingToolTemplate.Installer
$importNode = $template.ImportNode($newNode.RemoteMachine,$true)
$template.MsixPackagingToolTemplate.InsertAfter($importNode,$foundNode)
  
    <##
    $template.MsixPackagingToolTemplate.Installer.Path = $InstallerPath
    $template.MsixPackagingToolTemplate.SaveLocation.PackagePath = $PackageSaveLocation

    $template.MsixPackagingToolTemplate | Add-Member -NotePropertyName VirtualMachine -NotePropertyValue ''
    
    -NotePropertyMembers @{
        ComputerName = $ComputerName
        UserName = $UserName
        EnableAutoLogon = $true
    }


    $template.MsixPackagingToolTemplate.VirtualMachine | Add-Member -NotePropertyName ComputerName -NotePropertyValue $ComputerName
    $template.MsixPackagingToolTemplate.VirtualMachine | Add-Member -MemberType NoteProperty -Name UserName -Value $UserName
    $template.MsixPackagingToolTemplate.VirtualMachine | Add-Member -MemberType NoteProperty -Name EnableAutoLogon -Value $true

    ##>

    # Save the modified XML to the output path
    $template.Save($Path)
}