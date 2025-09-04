function Invoke-CustomWebRequest {
    param (
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method = "GET",

        [Parameter()]
        [hashtable]$Headers,

        [Parameter()]
        [hashtable]$Cookies,

        [Parameter()]
        [string]$Body,

        [Parameter()]
        [string]$ContentType = "application/json"
    )

    Add-Type -AssemblyName System.Net.Http

    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.UseCookies = $true
    $cookieContainer = New-Object System.Net.CookieContainer
    $handler.CookieContainer = $cookieContainer

    # Add custom cookies
    if ($Cookies) {
        foreach ($key in $Cookies.Keys) {
            $cookie = New-Object System.Net.Cookie($key, $Cookies[$key], "/", (New-Object System.Uri($Uri)).Host)
            $cookieContainer.Add((New-Object System.Uri($Uri)), $cookie)
        }
    }

    $client = New-Object System.Net.Http.HttpClient($handler)

    # Add headers
    if ($Headers) {
        foreach ($key in $Headers.Keys) {
            $client.DefaultRequestHeaders.Add($key, $Headers[$key])
        }
    }

    # Prepare request
    switch ($Method) {
        "GET" {
            $response = $client.GetAsync($Uri).Result
        }
        "POST" {
            $content = New-Object System.Net.Http.StringContent($Body, [System.Text.Encoding]::UTF8, $ContentType)
            $response = $client.PostAsync($Uri, $content).Result
        }
        "PUT" {
            $content = New-Object System.Net.Http.StringContent($Body, [System.Text.Encoding]::UTF8, $ContentType)
            $response = $client.PutAsync($Uri, $content).Result
        }
        "DELETE" {
            $response = $client.DeleteAsync($Uri).Result
        }
    }

    return $response.Content.ReadAsStringAsync().Result
}
