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
    $template.MsixPackagingToolTemplate.Installer.Path = $InstallerPath
    $template.MsixPackagingToolTemplate.SaveLocation.PackagePath = $PackageSaveLocation
    $template.MsixPackagingToolTemplate | Add-Member -MemberType NoteProperty -Name RemoteMachine -Value $null
    $template.MsixPackagingToolTemplate.RemoteMachine | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
    $template.MsixPackagingToolTemplate.RemoteMachine | Add-Member -MemberType NoteProperty -Name UserName -Value $UserName
    $template.MsixPackagingToolTemplate.RemoteMachine | Add-Member -MemberType NoteProperty -Name EnableAutoLogon -Value $true

    # Save the modified XML to the output path
    #$template.Save($Path)
}