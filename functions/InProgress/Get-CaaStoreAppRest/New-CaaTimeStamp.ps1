function New-CaaTimestamp {

    $date = Get-Date
    $dateExpiry = $date.AddMinutes(5)

    $output = @{
        #Created = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        Created = $date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        Expires = $dateExpiry.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        MessageID = (New-Guid).Guid
    }
    Write-Output $output
}