function Convert-CaaMsixToDisk {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Path,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [Alias('DestPath')]
        [System.String]$DestinationPath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateSet('vhdx', 'cim')]
        [System.String[]]$Type = 'cim',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$PassThru,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$TempExpandPath = 'C:\TempExpand',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$NoMsixMgrUpdate,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [string]$MsixMgrLocation = 'C:\Program Files\MSIXMGR'       
    )

    begin {
        #requires -RunAsAdministrator
        Set-StrictMode -Version Latest

        if (-not ($NoMsixMgrUpdate)) {

            $zipLocation = Join-Path $env:TEMP 'Msixmgr.zip'

            Invoke-WebRequest https://aka.ms/msixmgr -OutFile $zipLocation

            if (-not (Test-Path $MsixMgrLocation)) {
                New-Item -ItemType Directory $MsixMgrLocation
            }

            Expand-Archive -Path $zipLocation -DestinationPath $MsixMgrLocation -Force

        }  
        
    } # begin
    process {
        $fileInfo = Get-ChildItem $Path
        $validExtensions = '.msix', '.msixbundle', '.appx', '.appxbundle'
        If ($validExtensions -notcontains $fileInfo.Extension) {
            Write-Error "$($fileInfo.Name) is not a valid file format"
            return
        }

        $manifest = Read-CaaMsixManifest -Path $Path

        $version = $manifest.Identity.Version

        $name = $manifest.Identity.Name

        if (Test-Path $TempExpandPath ) {
            Remove-Item $TempExpandPath -Force -Recurse -Confirm:$False
        }

        New-Item $TempExpandPath -ItemType Directory  | Out-Null

        Expand-Archive -Path $Path -DestinationPath $TempExpandPath 
       
        foreach ($extension in $Type) {

            $directoryPath = Join-Path $DestinationPath (Join-Path $name (Join-Path $version $extension ))
            $targetPath = (Join-Path $directoryPath $fileInfo.Name).Replace($fileInfo.Extension, ('.' + $extension))

            if (Test-Path $targetPath) {
                if ($PassThru) {
                    $out = [PSCustomObject]@{
                        FullName = $targetPath
                    }
                    Write-Output $out
                }
                continue
            }
            if (-not(Test-Path $directoryPath)) {
                New-Item -ItemType Directory $directoryPath | Out-Null
            }    
            
            $exePath = (Join-Path $MsixMgrLocation 'msixmgr.exe').ToString()

            $result = & $exePath -Unpack -packagePath $Path -destination $targetPath -applyacls -create -filetype $extension -rootDirectory apps

            switch ($true) {
                { $result -like "Successfully created the CIM file*" } { $completed = $true; break }
                { $result -like "Finished unpacking packages to*" } { $completed = $true; break }
                { $result -like "*Failed with HRESULT 0x8bad0003*" } {
                    Write-Error "Failed $Path due to vhdx size too small"; break}
                { $result -like "*Failed*" } {
                    $result -match "Failed with HRESULT (\S+) when trying to unpack"
                    $errorCode = $Matches[1]
                    Write-Error "$($fileInfo.Name) failed to extract to $extension with error code $errorCode"
                    break
                }
                Default {}
            }

            if ($completed -and $PassThru) {
                $output = [PSCustomObject]@{
                    FullName = $targetPath
                }
                Write-Output $output
            }        
        }

        Remove-Item $TempExpandPath -Force -Recurse -Confirm:$False

    } # process
    end {} # end
}  #function