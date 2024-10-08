<# 

    .SYNOPSIS
    This script connects to the Microsoft Windows Update Client Web Service to retrieve metadata and secure download URLs for MSIX or APPX file downloads from the Microsoft Store (MSStore). 
    It serves as an alternative when applications cannot be downloaded via the WinGet package manager.

    .DESCRIPTION
    The script is designed to interface with the Microsoft Windows Update Client Web Service (WUS) to access MSStore applications, bypassing the current limitations of WinGet by directly fetching MSIX files.
    
    **Process Overview**:
    - The script sends several SOAP requests to the Windows Update Client Web Service to retrieve secure download URLs for specific application files based on user input.
    - It first retrieves an authentication cookie from Microsoft's service, followed by sending requests for metadata (e.g., application version, file types).
    - The script filters the metadata to download files matching the provided architecture (`x64`, `x86`, `arm`, or `all`) and file extension (`msix`, `appx`, or `all`).
    - Upon finding valid files, the script downloads them and stores them in the specified directory.

    **Key Steps**:
    1. **Authentication**: 
       The script retrieves a cookie required for further API interactions with Microsoft’s services.
    2. **Metadata Request**: 
       It sends a SOAP request to obtain metadata and details of MSIX files available for the requested MSStore application.
    3. **Filtering Files**: 
       The script then filters the results by architecture and file type to download the correct application packages.
    4. **Downloading Files**: 
       Once filtered, the script fetches the secure download URLs and stores the files locally in the specified directory.

    .PARAMETERS
    - **$arch**: The target architecture (e.g., `x64`, `x86`, `arm`, or `all`).
    - **$installextension**: The file extension to filter (`msix`, `appx`, or `all`).
    - **$release_type**: The release type (e.g., `RP` for Release Preview).
    - **$download_dir**: The directory where downloaded files will be saved.
    - **$WinGetID**: The unique WinGet ID of the MSStore application to fetch.
    
    .PREREQUISITES
    - PowerShell 5.1 or later
    - Internet access to interact with Microsoft Update services
    - Proper permissions to interact with Windows Update Client Web Service and download MSStore applications

    .REFERENCE
    The script interacts with the Windows Update Client Web Service using SOAP requests. Detailed technical documentation can be found at:

    - [Windows Update Server Protocols - MS-WUSP](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wusp/36a5d99a-a3ca-439d-bcc5-7325ff6b91e2)
    - [MS-WUSP Request Methods](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wusp/6b654980-ae63-4b0d-9fae-2abb516af894)
    - [MS-WUSP Metadata Synchronization](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wusp/2f66a682-164f-47ec-968e-e43c0a85dc21)

    .EXAMPLE
    PS> .\Download-MSIXFromStore.ps1 -arch "x64" -installextension "msix" -WinGetID "9NRX63209R7B" -release_type "RP"

    This command will download an MSIX file for the specified MSStore application targeting the x64 architecture in Release Preview (RP).

    .NOTES
    - Ensure to run this script with appropriate permissions.
    - Microsoft Store applications are accessed via secure URLs, and the script handles authentication and metadata filtering accordingly.

    .VERSION
    Version: 1.2.1
    Date: 04-10-2024

    .CHANGES
    Version 1.0.0: 02-10-2024: Initial script release, implementing authentication, metadata filtering, and MSIX downloading.
    Version 1.1.0: 03-10-2024: Added support for multiple architectures and file extensions.
    Version 1.2.0: 03-10-2024: Improved logging and error handling for better diagnostics.
    Version 1.2.1: 04-10-2024: Added XML into the script rather than script reading content from external files.

    .ROADMAP
    - Integrate error reporting and logging for better diagnostics.
    - Look further into XML and see what other posibilities there are

    
    .AUTHOR
    Developed by James Stapleton as a workaround for scenarios where WinGet does not fully support MSStore applications.

#>

$scriptVersion = "1.2.1"
Write-Host "Running script version $scriptVersion"

Set-Location $PSScriptRoot

# Variables (replace with actual arguments)
$arch = "x64"            # Options: x64, x86, arm, all
$installExtension = "msix"  # Options: msix, appx, all
$releaseType = "RP"         # Options: retail, RP, WIS, WIF
$downloadDirectory = "C:\Downloads" # Location for file downloads
$wingetID = "9NRX63209R7B" # Change to correspond to required package ID from WinGet

# Verbose logging enabled
$VerbosePreference = "Continue"

#XML Start --------------------------------------------

$GetCookie_XML = @"
<Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/2003/05/soap-envelope">
	<Header>
		<Action d3p1:mustUnderstand="1"
			xmlns:d3p1="http://www.w3.org/2003/05/soap-envelope"
			xmlns="http://www.w3.org/2005/08/addressing">http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService/GetCookie</Action>
		<MessageID xmlns="http://www.w3.org/2005/08/addressing">urn:uuid:b9b43757-2247-4d7b-ae8f-a71ba8a22386</MessageID>
		<To d3p1:mustUnderstand="1"
			xmlns:d3p1="http://www.w3.org/2003/05/soap-envelope"
			xmlns="http://www.w3.org/2005/08/addressing">https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx</To>
		<Security d3p1:mustUnderstand="1"
			xmlns:d3p1="http://www.w3.org/2003/05/soap-envelope"
			xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
			<Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
				<Created>{timestamp-created}</Created>
				<Expires>{timestamp-expires}</Expires>
			</Timestamp>
			<WindowsUpdateTicketsToken d4p1:id="ClientMSA"
				xmlns:d4p1="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
				xmlns="http://schemas.microsoft.com/msus/2014/10/WindowsUpdateAuthorization">
				<TicketType Name="MSA" Version="1.0" Policy="MBI_SSL">
				</TicketType>
			</WindowsUpdateTicketsToken>
		</Security>
	</Header>
	<Body>
		<GetCookie xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
			<oldCookie>
			</oldCookie>
			<lastChange>2015-10-21T17:01:07.1472913Z</lastChange>
			<currentTime>{timestamp-created}</currentTime>
			<protocolVersion>1.40</protocolVersion>
		</GetCookie>
	</Body>
</Envelope>
"@


$WindowsUpdateInfoRequestContent_XML = @"
<s:Envelope xmlns:a="http://www.w3.org/2005/08/addressing"
	xmlns:s="http://www.w3.org/2003/05/soap-envelope">
	<s:Header>
		<a:Action s:mustUnderstand="1">http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService/SyncUpdates</a:Action>
                <a:RelatesTo>urn:uuid:{RelatesToUUID}</a:RelatesTo> 
		<a:To s:mustUnderstand="1">https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx</a:To>
		<o:Security s:mustUnderstand="1"
			xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
			<Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
				<Created>{timestamp-created}</Created>
				<Expires>{timestamp-expires}</Expires>
			</Timestamp>
			<wuws:WindowsUpdateTicketsToken wsu:id="ClientMSA"
				xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
				xmlns:wuws="http://schemas.microsoft.com/msus/2014/10/WindowsUpdateAuthorization">
				<TicketType Name="MSA" Version="1.0" Policy="MBI_SSL">
				</TicketType>
			</wuws:WindowsUpdateTicketsToken>
		</o:Security>
	</s:Header>
	<s:Body>
		<SyncUpdates xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
			<cookie>
				<Expiration>{cookieExipres}</Expiration>
				<EncryptedData>{cookie}</EncryptedData>
			</cookie>
			<parameters>
				<ExpressQuery>false</ExpressQuery>
				<InstalledNonLeafUpdateIDs>
					<int>1</int>
					<int>2</int>
					<int>3</int>
					<int>11</int>
					<int>19</int>
					<int>544</int>
					<int>549</int>
					<int>2359974</int>
					<int>2359977</int>
					<int>5169044</int>
					<int>8788830</int>
					<int>23110993</int>
				</InstalledNonLeafUpdateIDs>
				<OtherCachedUpdateIDs></OtherCachedUpdateIDs>
				<SkipSoftwareSync>false</SkipSoftwareSync>
				<NeedTwoGroupOutOfScopeUpdates>true</NeedTwoGroupOutOfScopeUpdates>
				<FilterAppCategoryIds>
					<CategoryIdentifier>
						<Id>{cat_id}</Id>
					</CategoryIdentifier>
				</FilterAppCategoryIds>
				<TreatAppCategoryIdsAsInstalled>true</TreatAppCategoryIdsAsInstalled>
				<AlsoPerformRegularSync>false</AlsoPerformRegularSync>
				<ComputerSpec/>
				<ExtendedUpdateInfoParameters>
					<XmlUpdateFragmentTypes>
						<XmlUpdateFragmentType>Extended</XmlUpdateFragmentType>
					</XmlUpdateFragmentTypes>
					<Locales>
						<string>en-US</string>
						<string>en</string>
					</Locales>
				</ExtendedUpdateInfoParameters>
				<ClientPreferredLanguages>
					<string>en-US</string>
				</ClientPreferredLanguages>
				<ProductsParameters>
					<SyncCurrentVersionOnly>false</SyncCurrentVersionOnly>
					<DeviceAttributes>BranchReadinessLevel=CB;CurrentBranch=rs_prerelease;OEMModel=Virtual Machine;FlightRing={release_type};AttrDataVer=21;SystemManufacturer=Microsoft Corporation;InstallLanguage=en-US;OSUILocale=en-US;InstallationType=Client;FlightingBranchName=external;FirmwareVersion=Hyper-V UEFI Release v2.5;SystemProductName=Virtual Machine;OSSkuId=48;FlightContent=Branch;App=WU;OEMName_Uncleaned=Microsoft Corporation;AppVer=10.0.22621.900;OSArchitecture=AMD64;SystemSKU=None;UpdateManagementGroup=2;IsFlightingEnabled=1;IsDeviceRetailDemo=0;TelemetryLevel=3;OSVersion=10.0.22621.900;DeviceFamily=Windows.Desktop;</DeviceAttributes>
					<CallerAttributes>Interactive=1;IsSeeker=0;</CallerAttributes>
					<Products/>
				</ProductsParameters>
			</parameters>
		</SyncUpdates>
	</s:Body>
</s:Envelope>
"@

$WindowsUpdateInfoRequestFileURL_XML = @"
<s:Envelope xmlns:a="http://www.w3.org/2005/08/addressing"
	xmlns:s="http://www.w3.org/2003/05/soap-envelope">
	<s:Header>
		<a:Action s:mustUnderstand="1">http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService/GetExtendedUpdateInfo2</a:Action>
		<a:MessageID>urn:uuid:{newMessageID}</a:MessageID>
		<a:To s:mustUnderstand="1">https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx/secured</a:To>
		<o:Security s:mustUnderstand="1"
			xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
			<Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
				<Created>{timestamp-created}</Created>
				<Expires>{timestamp-expires}</Expires>
			</Timestamp>
			<wuws:WindowsUpdateTicketsToken wsu:id="ClientMSA"
				xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
				xmlns:wuws="http://schemas.microsoft.com/msus/2014/10/WindowsUpdateAuthorization">
				<TicketType Name="MSA" Version="1.0" Policy="MBI_SSL">
				</TicketType>
			</wuws:WindowsUpdateTicketsToken>
		</o:Security>
	</s:Header>
	<s:Body>
		<GetExtendedUpdateInfo2 xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
			<updateIDs>
				<UpdateIdentity>
					<UpdateID>{UpdateID}</UpdateID>
					<RevisionNumber>{RevisionNumber}</RevisionNumber>
				</UpdateIdentity>
			</updateIDs>
			<infoTypes>
				<XmlUpdateFragmentType>FileUrl</XmlUpdateFragmentType>
				<XmlUpdateFragmentType>FileDecryption</XmlUpdateFragmentType>
			</infoTypes>
			<deviceAttributes>BranchReadinessLevel=CB;CurrentBranch=rs_prerelease;OEMModel=Virtual Machine;FlightRing={release_type};AttrDataVer=21;SystemManufacturer=Microsoft Corporation;InstallLanguage=en-US;OSUILocale=en-US;InstallationType=Client;FlightingBranchName=external;FirmwareVersion=Hyper-V UEFI Release v2.5;SystemProductName=Virtual Machine;OSSkuId=48;FlightContent=Branch;App=WU;OEMName_Uncleaned=Microsoft Corporation;AppVer=10.0.22621.900;OSArchitecture=AMD64;SystemSKU=None;UpdateManagementGroup=2;IsFlightingEnabled=1;IsDeviceRetailDemo=0;TelemetryLevel=3;OSVersion=10.0.22621.900;DeviceFamily=Windows.Desktop;</deviceAttributes>
		</GetExtendedUpdateInfo2>
	</s:Body>
</s:Envelope>
"@


#XML End --------------------------------------------


#----------------------------------------------------------------------------------------------
# Function to construct the URL and retrieve the WuCategoryId
function Get-WuCategoryId {
    param (
        [string]$wingetID
    )

    Write-Verbose "Constructing the URL for the WinGetID: $wingetID"
    $url = "https://storeedgefd.dsx.mp.microsoft.com/v9.0/products/$($wingetID)?market=US&locale=en-us&deviceFamily=Windows.Desktop"
    Write-Verbose "Fetching the response from $url"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json"
    $firstSku = $response.Payload.Skus[0]
    $fulfillmentData = $firstSku.FulfillmentData | ConvertFrom-Json
    Write-Verbose "WuCategoryId found: $($fulfillmentData.WuCategoryId)"
    return $fulfillmentData.WuCategoryId
}

$categoryID = Get-WuCategoryId -wingetID $wingetID

#----------------------------------------------------------------------------------------------
# Function to generate timestamps and message IDs
function Generate-TimestampsAndMessageID {
    Write-Verbose "Generating timestamps and MessageID."
    return @{
        Created = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        Expires = ([System.DateTime]::UtcNow.AddMinutes(5)).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        MessageID = [guid]::NewGuid().ToString()
    }
}

#----------------------------------------------------------------------------------------------
# Function to authenticate and get the authentication cookie
function Get-AuthenticationCookie {


    Write-Verbose "Generating timestamps for authentication cookie."
    $timestamps = Generate-TimestampsAndMessageID
    $created = $timestamps.Created
    $expires = $timestamps.Expires

    Write-Verbose "Reading and formatting the GetCookie_XML."
    $cookieContent = $GetCookie_XML `
                    -replace '{timestamp-created}', $created `
                    -replace '{timestamp-expires}', $expires

    Write-Verbose "Sending authentication request to Microsoft services."
    $response = Invoke-WebRequest -Uri "https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx" `
                                  -Method POST `
                                  -Body $cookieContent `
                                  -ContentType "application/soap+xml; charset=utf-8"

    Write-Verbose "Parsing authentication response XML."
    $xml = New-Object System.Xml.XmlDocument
    $xml.LoadXml($response.Content)
    return @{
        Cookie = $xml.Envelope.Body.GetCookieResponse.GetCookieResult.EncryptedData
        CookieExpires = $xml.Envelope.Body.GetCookieResponse.GetCookieResult.Expiration
        CreatedTimestamp = $xml.Envelope.Header.Security.Timestamp.Created
        ExpiresTimestamp = $xml.Envelope.Header.Security.Timestamp.Expires
        RelatesToUUID = $xml.Envelope.Header.RelatesTo
    }
}

#----------------------------------------------------------------------------------------------
# Function to make the Windows Update Info request
function Request-WindowsUpdateInfo {
    param (
        [string]$categoryID,
        [string]$releaseType,
        [hashtable]$cookieData
    )

    Write-Verbose "Generating timestamps for WindowsUpdateInfo request."
    $timestamps = Generate-TimestampsAndMessageID
    $created = $timestamps.Created
    $expires = $timestamps.Expires
    $newMessageID = $timestamps.MessageID

    Write-Verbose "Reading and formatting the WindowsUpdateInfoRequest.xml."
    $requestContent = $WindowsUpdateInfoRequestContent_XML `
                      -replace '{newMessageID}', $newMessageID `
                      -replace '{RelatesToUUID}', $cookieData.RelatesToUUID `
                      -replace '{timestamp-created}', $created `
                      -replace '{timestamp-expires}', $expires `
                      -replace '{cookieExipres}', $cookieData.CookieExpires `
                      -replace '{cookie}', $cookieData.Cookie `
                      -replace '{cat_id}', $categoryID `
                      -replace '{release_type}', $releaseType

    Write-Verbose "Sending WindowsUpdateInfo request."
    $response = Invoke-WebRequest -Uri "https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx" `
                                  -Method POST `
                                  -Body $requestContent `
                                  -ContentType "application/soap+xml; charset=utf-8"

    Write-Verbose "Parsing WindowsUpdateInfo XML response."
    [xml]$parsedXml = New-Object System.Xml.XmlDocument
    $parsedXml.LoadXml([System.Web.HttpUtility]::HtmlDecode($response.Content))
    return $parsedXml
}

#----------------------------------------------------------------------------------------------
# Function to parse updates and extract relevant data
function Parse-UpdateInfo {
    param (
        [xml]$updateXml,
        [string]$arch,
        [string]$installextension
    )

    Write-Verbose "Parsing update information and filtering based on architecture: $arch and file extension: $installextension."
    $results = @()
    $nsmgr = New-Object System.Xml.XmlNamespaceManager($updateXml.NameTable)
    $nsmgr.AddNamespace("ns", "http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService")

    # Select the UpdateInfo nodes
    $updateInfoNodes = $updateXml.SelectNodes("//ns:UpdateInfo", $nsmgr)

    foreach ($updateInfo in $updateInfoNodes) {
        $updateIdentityNode = $updateInfo.SelectSingleNode("ns:Xml/ns:UpdateIdentity", $nsmgr)
        $revisionNumber = $updateIdentityNode.Attributes["RevisionNumber"].Value
        $updateID = $updateIdentityNode.Attributes["UpdateID"].Value

        Write-Verbose "Processing UpdateID: $updateID, RevisionNumber: $revisionNumber"

        # Check for SecuredFragment
        $securedFragmentNode = $updateInfo.SelectSingleNode("ns:Xml/ns:Properties/ns:SecuredFragment", $nsmgr)
        $securedFragment = if ($securedFragmentNode) { "Secured URL Available" } else { "No SecuredFragment" }

        # Select the corresponding update details
        $updateDetails = $updateXml.Envelope.Body.SyncUpdatesResponse.SyncUpdatesResult.ExtendedUpdateInfo.Updates.Update | Where-Object { $_.ID -eq $updateInfo.ID }

        if ($updateDetails.Xml.Files.File) {
            foreach ($file in $updateDetails.Xml.Files.File) {
                $fileName = $file.FileName.ToLower()
                
                # Check if InstallerSpecificIdentifier exists (skip if it's null)
                if ($file.InstallerSpecificIdentifier) {
                    $installerIdentifier = $file.InstallerSpecificIdentifier.ToLower()
                } else {
                    $installerIdentifier = ""
                }

                # Apply filtering based on architecture and extension
                $isArchMatch = if ($arch -eq "all") {
                    $true
                } elseif ($installerIdentifier -ne "") {
                    $installerIdentifier -like "*$arch*"
                } else {
                    # If there's no InstallerSpecificIdentifier, we can't apply arch filtering strictly, so allow through
                    $true
                }

                $isExtensionMatch = if ($installextension -eq "all") {
                    $true
                } else {
                    $fileName -like "*.$installextension"
                }

                # Check if both architecture and extension match
                if ($isArchMatch -and $isExtensionMatch) {
                    Write-Verbose "File found matching criteria: $($file.FileName)"
                    $results += [pscustomobject]@{
                        FileName                    = $file.FileName
                        InstallerSpecificIdentifier = $installerIdentifier
                        RevisionNumber              = $revisionNumber
                        UpdateID                    = $updateID
                        SecuredFragment             = $securedFragment
                    }
                } else {
                    Write-Verbose "File does not match criteria: $($file.FileName)"
                }
            }
        } else {
            Write-Verbose "No files found for UpdateID: $updateID"
        }
    }

    # Return the filtered results
    return $results
}

#----------------------------------------------------------------------------------------------
# Function to download filtered .msix files
function Download-Files {
    param (
        [array]$filteredResults,
        [string]$downloadDirectory
    )

    Write-Verbose "Preparing to download files."
    $headers = @{"Content-Type" = "application/soap+xml; charset=utf-8"}
    $serviceUrl = "https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx/secured"

    if (-not (Test-Path -Path $downloadDirectory)) {
        Write-Verbose "Creating download directory: $downloadDirectory"
        New-Item -Path $downloadDirectory -ItemType Directory
    }

    foreach ($result in $filteredResults) {
        $timestamps = Generate-TimestampsAndMessageID
        $created = $timestamps.Created
        $expires = $timestamps.Expires
        $newMessageID = $timestamps.MessageID

        Write-Verbose "Reading and formatting FileDownloadRequest.xml for UpdateID: $($result.UpdateID)"
        $downloadRequest = $WindowsUpdateInfoRequestFileURL_XML `
                            -replace '{newMessageID}', $newMessageID `
                            -replace '{timestamp-created}', $created `
                            -replace '{timestamp-expires}', $expires `
                            -replace '{UpdateID}', $result.UpdateID `
                            -replace '{RevisionNumber}', $result.RevisionNumber

        $response = Invoke-WebRequest -Uri $serviceUrl -Method Post -Body $downloadRequest -Headers $headers
        [xml]$parsedResponse = $response.Content
        $fileUrls = $parsedResponse.Envelope.Body.GetExtendedUpdateInfo2Response.GetExtendedUpdateInfo2Result.FileLocations.FileLocation

        $fileNameToMatch = $result.FileName -replace "\.msix$"
        $matchingFileUrl = $fileUrls | Where-Object { $_.Url -like "*$fileNameToMatch*" }

        if ($matchingFileUrl) {
            $destinationFileName = "$($result.InstallerSpecificIdentifier).msix"
            $destinationPath = Join-Path -Path $downloadDirectory -ChildPath $destinationFileName

            Write-Verbose "Downloading file: $destinationFileName"
            Invoke-WebRequest -Uri $matchingFileUrl.Url -OutFile $destinationPath
            Write-Verbose "File downloaded to: $destinationPath"
        } else {
            Write-Verbose "No matching file found for: $fileNameToMatch"
        }
    }
}
#----------------------------------------------------------------------------------------------

# Example of calling the functions
$cookieData = Get-AuthenticationCookie
$updateXml = Request-WindowsUpdateInfo -categoryID $categoryID -releaseType $releaseType -cookieData $cookieData
$filteredResults = Parse-UpdateInfo -updateXml $updateXml -arch $arch -installExtension $installExtension
Download-Files -filteredResults $filteredResults -downloadDirectory $downloadDirectory
