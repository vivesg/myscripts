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


$tok = 0
$resp = try { 
  
    $tok = Invoke-WebRequest -UseBasicParsing -Uri "https://support.microsoft.com/supportformsapi/workspace/AccessTokens" `
        -Method "POST" `
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

$path = "/api/v1/workspaces/" + $wid + "/folders/external/files?filename=" + $filename
$myheader = @{
    "method"          = "PUT"
    "authority"       = "api.dtmnebula.microsoft.com"
    "scheme"          = "https"
    "path"            = $path
    "authorization"   = "Bearer " + $tok.accessToken
    "accept"          = "application/json, text/plain, */*"
    "overwrite"       = "false"
    "origin"          = "https://support.microsoft.com"
    "accept-encoding" = "gzip, deflate, br"
}

$uri = "https://api.dtmnebula.microsoft.com/api/v1/workspaces/" + $wid + "/folders/external/files/metadata?filename=" + $filename
$chunks = [int][Math]::Ceiling(([int]$sizeoffile) / 134217728)
$body = @"
{"chunkSize":134217728,"contentType":"text/xml","fileSize":$sizeoffile,"numberOfChunks":$chunks}
"@
Write-Host $body
$resp = try { 
    Invoke-WebRequest -UseBasicParsing -Uri $uri `
        -Method "PUT" `
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
    "method"          = "PATCH"
    "authority"       = "api.dtmnebula.microsoft.com"
    "scheme"          = "https"
    "path"            = $path
    "authorization"   = "Bearer " + $tok.accessToken
    "accept"          = "application/json, text/plain, */*"
    "chunkindex"      = "0"
    "accept-encoding" = "gzip, deflate, br"
}

$resp = try { 
    Invoke-RestMethod -Uri $uri -Method Patch -InFile $filelocation -Headers $header 
}
catch { $_.Exception.Response }

if ($resp.IsSuccessStatusCode -ne $false) {
    Write-Host "Success we succesfully uploaded the data "
}
else {
    Write-Host "Failure uploading the data"
}
