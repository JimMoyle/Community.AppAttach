function Update-CaaTemplateXml {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true)]
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
    $template.MsixPackagingToolTemplate.RemoteMachine.ComputerName = $ComputerName
    $template.MsixPackagingToolTemplate.RemoteMachine.UserName = $UserName
    $template.MsixPackagingToolTemplate.RemoteMachine.EnableAutoLogon = $true

    # Save the modified XML to the output path
    #$template.Save($Path)
}

Update-CaaTemplateXml 'D:\PoShCode\GitHub\Community.AppAttach\SampleTemplate.xml' -InstallerPath 'd:\myInstaller.exe' -PackageSaveLocation 'd:\myMsix.msix' -ComputerName 'myComputer' -UserName 'myUser'