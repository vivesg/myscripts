#developed by gevivesh

#This scripts helps to upload a file to DTM 
#Please provide the URL Generated and the file name to be uploaded
#run like this .\uploadtoDTM.ps1 -url "https://support.microsoft.com/blabla......." -file "c:\file.ext"
# or run it on Azure VM Custom Script Extension as well

Param(
    [string]$url,
    [string]$file
)

#runnit on Run Powershell Script like this 
# $url = "https://support.microsoft.com/blabla"
# $file = "c:\folder\filename.ext"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$filelocation = $file
$filename = ((Get-Item $filelocation)).Name
$sizeoffile = ((Get-Item $filelocation)).length

$queryHash = @{}
foreach ($q in ($url -split '&')) {
    $kv = $($q + '=') -split '='
    $name = [uri]::UnescapeDataString($kv[0]).Trim()
    $queryHash[$name] = [uri]::UnescapeDataString($kv[1])
}


$wid = $queryHash['wid']
$to = $queryHash['https://support.microsoft.com/files?workspace']
$mybody = @"
{"workspaceToken":"$to","email":""}
"@


$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Mobile Safari/537.36 Edg/93.0.961.52"
$session.Cookies.Add((New-Object System.Net.Cookie("SMCsiteLang", "en-US", "/", ".support.microsoft.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("SMCsiteDir", "ltr", "/", ".support.microsoft.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("smcpartner", "smc", "/", "support.microsoft.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("MSCC", "NR", "/", ".microsoft.com")))


$tok = 0
$resp = try { 
  
    $tok = Invoke-WebRequest -UseBasicParsing -Uri "https://support.microsoft.com/supportformsapi/workspace/AccessTokens" `
        -Method "POST" `
        -WebSession $session `
        -Headers @{
        "sec-ch-ua"              = "`"Microsoft Edge`";v=`"93`", `" Not;A Brand`";v=`"99`", `"Chromium`";v=`"93`""
        "sec-ch-ua-mobile"       = "?1"
        "Accept"                 = "application/json, text/plain, */*"
        "Caller-Name"            = "Angular"
        "sec-ch-ua-platform"     = "`"Android`""
        "Origin"                 = "https://support.microsoft.com"
        "Sec-Fetch-Site"         = "same-origin"
        "Sec-Fetch-Mode"         = "cors"
        "Sec-Fetch-Dest"         = "empty"
        "Accept-Encoding"        = "gzip, deflate, br"
        "Accept-Language"        = "en-US,en;q=0.9"
    } `
        -ContentType "application/json" `
        -Body $mybody 
}
catch { $_.Exception.Response }
if ($resp.IsSuccessStatusCode -eq $false) {
    write-host $resp.Response
    Write-Host "Error getting token failed to upload data"
    exit
}

$tok = $tok.Content | ConvertFrom-Json

$uri = "https://api.dtmnebula.microsoft.com/api/v1/workspaces/" + $wid + "/folders/external/files/metadata?filename=" + $filename 
$path = "/api/v1/workspaces/" + $wid + "/folders/external/files?filename=" + $filename
$myheader = @{
    "method"                 = "PUT"
    "authority"              = "api.dtmnebula.microsoft.com"
    "scheme"                 = "https"
    "path"                   = $path
    "sec-ch-ua"              = "`"Microsoft Edge`";v=`"93`", `" Not;A Brand`";v=`"99`", `"Chromium`";v=`"93`""
    "authorization"          = "Bearer " + $tok.accessToken
    "accept"                 = "application/json, text/plain, */*"
    "caller-name"            = "Angular"
    "sec-ch-ua-mobile"       = "?1"
    "overwrite"              = "false"
    "sec-ch-ua-platform"     = "`"Android`""
    "origin"                 = "https://support.microsoft.com"
    "sec-fetch-site"         = "same-site"
    "sec-fetch-mode"         = "cors"
    "sec-fetch-dest"         = "empty"
    "referer"                = "https://support.microsoft.com/"
    "accept-encoding"        = "gzip, deflate, br"
    "accept-language"        = "en-US,en;q=0.9"
}

$uri = "https://api.dtmnebula.microsoft.com/api/v1/workspaces/" + $wid + "/folders/external/files/metadata?filename=" + $filename
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$chunks = [int][Math]::Ceiling(([int]$sizeoffile) / 134217728)
$body = @"
{"chunkSize":134217728,"contentType":"text/xml","fileSize":$sizeoffile,"numberOfChunks":$chunks}
"@

$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Mobile Safari/537.36 Edg/93.0.961.52"

$resp = try { 
    $allocate = Invoke-WebRequest -UseBasicParsing -Uri $uri `
        -Method "PUT" `
        -WebSession $session `
        -Headers $myheader `
        -ContentType "application/json" `
        -Body $body
}
catch { $_.Exception.Response } 
if ($resp.IsSuccessStatusCode -eq $false) {
    Write-Host "An error ocurred uploading the data "
    exit
}

$uri = "https://api.dtmnebula.microsoft.com/api/v1/workspaces/" + $wid + "/folders/external/files?filename=" + $filename

$header = @{
    "method"                 = "PATCH"
    "authority"              = "api.dtmnebula.microsoft.com"
    "scheme"                 = "https"
    "path"                   = $path
    "sec-ch-ua"              = "`"Microsoft Edge`";v=`"93`", `" Not;A Brand`";v=`"99`", `"Chromium`";v=`"93`""
    "authorization"          = "Bearer " + $tok.accessToken
    "accept"                 = "application/json, text/plain, */*"
    "caller-name"            = "Angular"
    "sec-ch-ua-mobile"       = "?1"
    "chunkindex"             = "0"
    "sec-ch-ua-platform"     = "`"Android`""
    "origin"                 = "https://support.microsoft.com"
    "sec-fetch-site"         = "same-site"
    "sec-fetch-mode"         = "cors"
    "sec-fetch-dest"         = "empty"
    "referer"                = "https://support.microsoft.com/"
    "accept-encoding"        = "gzip, deflate, br"
    "accept-language"        = "en-US,en;q=0.9"
}

$resp = try { 
    Invoke-RestMethod -Uri $uri -Method Patch -InFile $filelocation -Headers $header 
}
catch { $_.Exception.Response }

if ($resp.IsSuccessStatusCode -ne $false) {
    Write-Host "Success we succesfully uploaded the data "
}
else{
    Write-Host "Failure uploading the data"
}
