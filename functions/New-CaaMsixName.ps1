function New-CaaMsixName {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateScript({ if ($_ -like '*.*') { return $true }; throw 'Value must be PublisherName.AppName' })]
        [String]$PackageIdentifier,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateLength(13, 13)]
        [string]$CertHash,

        [Parameter(
            ParameterSetName = 'FullName',
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [Alias('PackageVersion')]
        [ValidateScript({ if ($_.ToString().Split('.').Count -eq 4) { return $true }; throw 'Value must be a four part version eg 1.2.3.4' })]
        [Version]$Version,

        [Parameter(
            ParameterSetName = 'FullName',
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateSet('x86', 'x64', 'neutral', 'ARM64', 'ARM')]
        [String]$Architecture

    )
    
    begin {}
    
    process {
        <##
        PublisherName: The name of the app’s publisher or developer.
        AppName: The name of the application itself.
        AppVersion: The version number of the app.
        architecture: Indicates whether the package is for x86, x64, neutral, ArRM4 or ARM.
        hash: A unique hash value generated based on the package certificate publisher

        PublisherName.AppName_AppVersion_architecture__hash
        AwesomeCorp.MyCoolApp_1.0.0.0_x64__abcdef123456

        Sometimes there is a ~ between the last two _ I don't know why.
        #>

        if ($PsCmdlet.ParameterSetName = 'FamilyName') {

            $name = "{0}_{3}" -f $identifier, $CertHash
        }
        else {
            $name = "{0}_{1}_{2}__{3}" -f $identifier, $Version.ToString(), $Architecture, $CertHash
        }

        $output = [PSCustomObject]@{
            PSTypeName = 'Caa.MsixName'
            Name       = $name
        }

        Write-Output $output
    }
    
    end {}
}