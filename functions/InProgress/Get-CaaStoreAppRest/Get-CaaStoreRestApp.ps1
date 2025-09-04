function Get-CaaStoreRestApp {
	[CmdletBinding()]

	Param (
		[Parameter(
			Position = 0,
			ParameterSetName = 'Default',
			ValuefromPipelineByPropertyName = $true,
			ValuefromPipeline = $true,
			Mandatory = $true
		)]
		[Alias('Id', 'AppName')]
		[System.String]$StoreId,

		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[System.String]$StoreUri = "https://storeedgefd.dsx.mp.microsoft.com/v9.0/products",

		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[System.String]$StoreDeliveryUri = "https://storeedgefd.dsx.mp.microsoft.com/v9.0/products",

		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[System.String]$Market = "US",

		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[System.String]$Locale = "en-us",

		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[System.String]$DeviceFamily = "Windows.Desktop",

		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[ValidateSet('Msix', 'Appx', 'All')]
		[System.String]$InstallExtension = 'All',

		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[ValidateSet('x64', 'x86', 'arm', 'All')]
		[System.String]$Architecture = 'All',
        
		[Parameter(
			ParameterSetName = 'Default',
			ValuefromPipeline = $true
		)]
		[ValidateSet('RP', 'WIS', 'WIF', 'Retail')]
		[System.String]$ReleaseType = "RP"
	)

	begin {
		Set-StrictMode -Version Latest

		. functions\InProgress\Get-CaaStoreAppRest\New-CaaTimeStamp.ps1


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
	} # begin
	process {

		#Write-Verbose "Constructing the URL for the Store ID: $StoreId"
		$StoreUri = $StoreUri.TrimEnd('/')
		$StoreUri = $StoreUri + '/'
		$url = $StoreUri + $StoreId + '?market=' + $Market + '&locale=' + $Locale + '&deviceFamily=' + $DeviceFamily
		#Write-Verbose "Fetching the response from $url"
		$response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json"
		$firstSku = $response.Payload.Skus[0]
		$fulfillmentData = $firstSku.FulfillmentData | ConvertFrom-Json
		Write-Output $fulfillmentData

		#Write-Verbose "Generating timestamps for authentication cookie."
		$timeStamp = New-CaaTimeStamp
		$created = $timeStamp.Created
		$expires = $timeStamp.Expires

		#Write-Verbose "Reading and formatting the GetCookie_XML."
		$cookieContent = $GetCookie_XML -replace '{timestamp-created}', $created -replace '{timestamp-expires}', $expires

		$splatInvokeWebRequest = @{
			Uri         = $StoreDeliveryUri
			Method      = 'POST'
			Body        = $cookieContent
			ContentType = "application/soap+xml; charset=utf-8"
		}

		$response = Invoke-WebRequest @splatInvokeWebRequest

	} # process
	end {} # end
}  #function'

Get-CaaStoreRestApp -StoreId 9NBLGGH4VVNH