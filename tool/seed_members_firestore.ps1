param(
    [string]$ProjectId = 'bhandari-pariwar',
    [string]$ApiKey = 'AIzaSyAL5HaR_-Ey1a8olyC1hDI0mGqmUpWj4go',
    [string]$AssetPath = 'assets/members_data.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Convert-ToFirestoreValue {
    param([Parameter(ValueFromPipeline = $true)] $Value)

    if ($null -eq $Value) {
        return @{ nullValue = $null }
    }

    if ($Value -is [bool]) {
        return @{ booleanValue = $Value }
    }

    if ($Value -is [int] -or $Value -is [long]) {
        return @{ integerValue = [string]$Value }
    }

    if ($Value -is [double] -or $Value -is [float] -or $Value -is [decimal]) {
        return @{ doubleValue = [double]$Value }
    }

    if ($Value -is [string]) {
        return @{ stringValue = $Value }
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $fields = @{}
        foreach ($key in $Value.Keys) {
            $fields[[string]$key] = Convert-ToFirestoreValue $Value[$key]
        }
        return @{ mapValue = @{ fields = $fields } }
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $values = @()
        foreach ($item in $Value) {
            $values += ,(Convert-ToFirestoreValue $item)
        }
        return @{ arrayValue = @{ values = $values } }
    }

    return @{ stringValue = [string]$Value }
}

function Convert-ToFirestoreFields {
    param([Parameter(Mandatory = $true)] [System.Collections.IDictionary]$Map)

    $fields = @{}
    foreach ($key in $Map.Keys) {
        if ($key -eq 'id') {
            continue
        }
        $fields[[string]$key] = Convert-ToFirestoreValue $Map[$key]
    }
    return $fields
}

function Get-AnonFirebaseToken {
    param(
        [Parameter(Mandatory = $true)] [string]$Key
    )

    $authUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$Key"
    $authBody = @{ returnSecureToken = $true } | ConvertTo-Json -Depth 5
    $response = Invoke-RestMethod -Method Post -Uri $authUrl -ContentType 'application/json' -Body $authBody
    return $response.idToken
}

function Get-MemberDocs {
    param(
        [Parameter(Mandatory = $true)] [string]$Project,
        [Parameter(Mandatory = $true)] [string]$Token
    )

    $baseUrl = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/members"
    $headers = @{ Authorization = "Bearer $Token" }

    try {
        $response = Invoke-RestMethod -Method Get -Uri $baseUrl -Headers $headers
        if ($null -eq $response.documents) {
            return @()
        }
        return @($response.documents)
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            return @()
        }
        throw
    }
}

function Remove-MemberDocs {
    param(
        [Parameter(Mandatory = $true)] [string]$Project,
        [Parameter(Mandatory = $true)] [string]$Token
    )

    $headers = @{ Authorization = "Bearer $Token" }
    $docs = Get-MemberDocs -Project $Project -Token $Token
    foreach ($doc in $docs) {
        Invoke-RestMethod -Method Delete -Uri ("https://firestore.googleapis.com/v1/" + $doc.name) -Headers $headers | Out-Null
    }
    return $docs.Count
}

function Write-MemberDocs {
    param(
        [Parameter(Mandatory = $true)] [string]$Project,
        [Parameter(Mandatory = $true)] [string]$Token,
        [Parameter(Mandatory = $true)] [string]$JsonPath
    )

    $headers = @{ Authorization = "Bearer $Token" }
    $jsonText = Get-Content -Raw -Path $JsonPath
    $decoded = $jsonText | ConvertFrom-Json -AsHashtable -Depth 100

    if ($decoded -is [System.Collections.IDictionary] -and $decoded.ContainsKey('members')) {
        $members = @($decoded['members'])
    } else {
        $members = @($decoded)
    }

    $count = 0
    foreach ($member in $members) {
        $memberMap = [hashtable]$member
        $id = [string]$memberMap['id']
        if ([string]::IsNullOrWhiteSpace($id)) {
            throw 'Each member must include a non-empty id.'
        }

        $fields = Convert-ToFirestoreFields -Map $memberMap
        $body = @{ fields = $fields } | ConvertTo-Json -Depth 100
        $docUrl = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/members/$id"
        Invoke-RestMethod -Method Patch -Uri $docUrl -Headers $headers -ContentType 'application/json' -Body $body | Out-Null
        $count++
    }

    return $count
}

$rootPath = Split-Path -Parent $PSScriptRoot
$resolvedAssetPath = Join-Path $rootPath $AssetPath

if (-not (Test-Path $resolvedAssetPath)) {
    throw "Seed asset not found: $resolvedAssetPath"
}

$token = Get-AnonFirebaseToken -Key $ApiKey
$removed = Remove-MemberDocs -Project $ProjectId -Token $token
$written = Write-MemberDocs -Project $ProjectId -Token $token -JsonPath $resolvedAssetPath

Write-Host "Removed $removed existing member documents."
Write-Host "Seeded $written member documents into members collection."