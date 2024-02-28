function Set-CaaMsixCertificate {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [ValidateScript({
                if (-Not ($_ | Test-Path -PathType Leaf) ) { throw "The Path argument must be a file. Folder paths are not allowed." }
                if ($_ -notmatch "\.msix$|\.appx$|(?:\.msi|\.app)xbundle$") {
                    throw "The file specified must be an application package"
                }
                return $true
            }
        )]
        [Alias('PSPath')]
        [System.String]$Path,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$CertificatePath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [SecureString]$CertificatePassword,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Uri]$TimeStampUri = 'http://timestamp.digicert.com',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$Encryption = 'SHA256',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$SignToolPath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$Passthru
    )
    begin {
        Set-StrictMode -Version Latest
    }
    process {
        if (-not($SignToolPath)) {
            
            $SignToolPath = Get-ChildItem "$Env:ProgramFiles\WindowsApps" -Recurse -Include 'Signtool.exe'
            $fileInfo = $SignToolPath | Get-ChildItem | Where-Object {$_.DirectoryName -like "*Microsoft.MSIXPackagingTool_*_*_*_8wekyb3d8bbwe\SDK*"} | Select-Object -First 1
    
            Copy-Item $fileInfo.DirectoryName $env:Temp -Force
            $SignToolPath = "$env:TEMP\SDK\signtool.exe"
        }
        
        $output = Start-Process $SignToolPath -ArgumentList "sign /f $CertificatePath /p $(ConvertFrom-SecureString -AsPlainText $CertificatePassword) /fd $Encryption /tr $($TimeStampUri.AbsoluteUri) /td $Encryption $Path" -Wait -Passthru -NoNewWindow

        If ($output.ExitCode -ne 0){
            # https://blogs.blackmarble.co.uk/rfennell/a-fix-for-error-signersign-failed-2146958839-0x80080209-with-signtool-exe/
            Write-Error 'You MUST use the signtool.exe from the MSIX Packaging tool and the publisher name in the appxmanifest.xml file must match the certificate publisher exactly'
            return
        }
        if ($PassThru) {
            Write-Output $output | Select-Object ExitCode, HasExited, StartTime, ExitTime
        }
    }
    end {}
    
}