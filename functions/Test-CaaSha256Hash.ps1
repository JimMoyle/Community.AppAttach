function Test-CaaSha256Hash {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [ValidateScript({
            if (-Not ($_ | Test-Path) ) { throw "File does not exist" }
            if (-Not ($_ | Test-Path -PathType Leaf) ) { throw "The Path argument must be a file. Folder paths are not allowed." }
            return $true
        })]
        [Alias('PSPath')]
        [System.String]$Path,

        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [ValidateScript({
            if  ($_ -notmatch "^[A-Fa-f0-9]{64}$"){
                throw "This doesn't appear to match a correct SHA256 format"
            }
            return $true
        })]
        [System.String]$Sha256Hash
    )
    
    begin {
        Set-StrictMode -Version Latest
    }
    
    process {
        $fileHash = Get-FileHash -Algorithm SHA256 -Path $Path
        $compareHash = $Sha256Hash
        if ($fileHash.Hash -eq $compareHash){
            Write-Output $true
        }
        else{
            Write-Output $false
        }
    }
    
    end {}
}