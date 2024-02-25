function New-CaaMsixFullName {
    [CmdletBinding()]
    param (

        [Parameter(
            ParameterSetName = 'PackageIdentifier',
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateScript({ if ($_ -like '*.*') { return $true }; throw 'Value must be PublisherName.AppName' })]
        [string]$PackageIdentifier,

        [Parameter(
            ParameterSetName = 'Publisher AppName',
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateScript({ if ($_ -notmatch ' ') { return $true }; throw 'Value must not contain spaces.' })]
        [string]$Publisher,

        [Parameter(
            ParameterSetName = 'Publisher AppName',
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateScript({ if ($_ -notmatch ' ') { return $true }; throw 'Value must not contain spaces.' })]
        [string]$AppName,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [Alias('PackageVersion')]
        [ValidateScript({ if ($_.Split('.').Count -eq 4) { return $true }; throw 'Value must not contain spaces.' })]
        [version]$Version,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateSet('x86', 'x64', 'neutral', 'ARM64', 'ARM')]
        [version]$Architecture,

        [Parameter(
            Mandatory = $true,
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateLength(13)]
        [version]$CertHash

    )
    
    begin {
        
    }
    
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

        #This function only exists for the parameter validation

        switch ($PsCmdlet.ParameterSetName) {
            'PackageIdentifier' { $identifier = $PackageIdentifier; break }
            'Publisher AppName' {$identifier = $Publisher + '.' + $AppName; break}
            }

        $output = [PSCustomObject]@{
            PSTypeName = 'Caa.MsixFullName'
            Name = "{0}_{1}_{2}__{3}" -f $identifier, $Version.ToString(), $Architecture, $CertHash
        }

        Write-Output $output
    }
    
    end {
        
    }
}