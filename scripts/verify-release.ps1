<#
.SYNOPSIS
  Confirms which version a Render service is running and logs the result.

.DESCRIPTION
  Polls <Url>/health until it reports the expected version (free Render services sleep after
  15 minutes and need about a minute to wake up, so the first call is slow). Prints the response
  and appends a row to release/deploy-log.csv with a local timestamp: use it for the smoke-test
  start, the faulty release, the rollback decision and the restore confirmation.

.EXAMPLE
  .\scripts\verify-release.ps1 -Url https://lab-staging.onrender.com -ExpectedVersion v1.4.0 -Note "after rollback"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [string]$ExpectedVersion = '',
    [int]$TimeoutSeconds = 300,
    [string]$Note = '',
    [string]$LogPath = 'release/deploy-log.csv'
)

$ErrorActionPreference = 'Continue'
$healthUrl = $Url.TrimEnd('/') + '/health'
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$health = $null

while ((Get-Date) -lt $deadline) {
    $raw = & curl.exe -sS --max-time 90 $healthUrl 2>$null
    try { $health = $raw | ConvertFrom-Json } catch { $health = $null }
    if ($health -and $health.status -eq 'ok' -and (-not $ExpectedVersion -or $health.version -eq $ExpectedVersion)) { break }
    $seen = if ($health) { "version=$($health.version) status=$($health.status)" } else { 'no response yet' }
    Write-Host "waiting... $seen"
    Start-Sleep -Seconds 10
}

$result = 'PASS'; $reason = ''
if (-not $health -or $health.status -ne 'ok') { $result = 'FAIL'; $reason = "no healthy response within $TimeoutSeconds s" }
elseif ($ExpectedVersion -and $health.version -ne $ExpectedVersion) { $result = 'FAIL'; $reason = "running '$($health.version)', expected '$ExpectedVersion'" }

$now = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
Write-Host ''
if ($health) { $health | ConvertTo-Json -Compress | Write-Host } else { Write-Host '(no response)' }
Write-Host "Result: $result $reason"
Write-Host "Time  : $now"

$dir = Split-Path -Parent $LogPath
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
[pscustomobject]@{
    checked_at = $now
    url        = $Url
    version    = $(if ($health) { $health.version } else { '' })
    commit     = $(if ($health) { $health.commit } else { '' })
    expected   = $ExpectedVersion
    result     = $result
    reason     = $reason
    note       = $Note
} | Export-Csv -Path $LogPath -Append -NoTypeInformation
Write-Host "Logged to $LogPath"

if ($result -ne 'PASS') { exit 1 }
exit 0
