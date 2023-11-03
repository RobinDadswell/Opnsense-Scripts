[CmdletBinding()]
param (
    [Parameter(
        Mandatory = $true
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ApiKey,
    [Parameter(
        Mandatory = $true
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $ApiSecret,
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'e.g. https://router.contoso.com'
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $OPNSenseURL
)


$secret = $ApiSecret | ConvertTo-SecureString -AsPlainText
$credential = [PSCredential]::New($ApiKey,$secret)

$unboundConfig = Invoke-RestMethod -Method Get -Uri "$OPNSenseUrl/api/unbound/settings/get" -Credential $credential -Authentication Basic
$whitelist = ($unboundConfig.unbound.dnsbl.whitelists | Get-Member).name.where({$_ -notin "Equals","GetHashCode","GetType","ToString"})

$365Urls = (Invoke-RestMethod -Method Get -Uri "https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7").urls

foreach ($url in $365Urls)
{
    if ($url -notin $whitelist)
    {
        #create
        $whitelist.Add($url)
    }<#
    else {
        $url
    }#>
}

$whitelistString = $whitelist -join ","

$unboundConfigObject = [PSCustomObject]@{
    unbound = [PSCustomObject]@{
        dnsbl = [PSCustomObject]@{
            whitelists = $whitelistString
        }
    }
}
$unboundConfig2 = $unboundConfigObject | ConvertTo-Json


Invoke-RestMethod -Method Post -Uri "$OPNSenseUrl/api/unbound/settings/set" -Credential $credential -Authentication Basic -Body $unboundConfig2 -ContentType "application/json"
