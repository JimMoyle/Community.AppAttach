#requires -module selenium
#requires -module PSSQLite

function Get-CookiesPath {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    return (Get-ChildItem -Path $Path -Recurse -File | Where-Object { $_.Name -eq "cookies.sqlite" }).FullName
}

function Get-FirefoxCookies {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Url
    )

    If ($true) {
        $CookiesPath = Get-CookiesPath -Path "$env:APPDATA\Mozilla\Firefox\Profiles\"
        $Query = "SELECT * FROM moz_cookies WHERE host LIKE '%$Url%'"
        return Invoke-SqliteQuery -DataSource $CookiesPath -Query $Query
    }
    else {
        Write-Debug "Firefox is not installed. No cookies for the cookie monster :("
    }
}

$Cookies = Get-FirefoxCookies -Url "apps.microsoft.com"

function Set-Cookies {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [Object[]]$Cookies
    )

    $Cookies | ForEach-Object {
        try {
            $expiry = [datetime]::UnixEpoch.AddSeconds($_.expiry)
            Write-Debug "###############################################################"
            $seleniumCookie = New-Object OpenQA.Selenium.Cookie($_.name, $_.value, $_.host, $_.path, $expiry)
            Write-Debug $seleniumCookie
            $Script:Driver.Manage().Cookies.AddCookie($seleniumCookie)
        }
        catch {
            Write-Error "Cookies could not be accessed, so no cookies were replayed. No cookies for the cookie monster :("
        }
    }
}

$Script:Driver = Start-SeFirefox -Headless

$Script:Driver.Navigate().GoToUrl("https://login.microsoftonline.com")
$Script:Driver.Manage().Cookies.AllCookies | Select-Object name, domain, value

Set-Cookies -Cookies $Cookies -Debug
$Script:Driver.Manage().Cookies.AllCookies | Select-Object name, domain, value
