<#
.SYNOPSIS
  Deploys an exact, digest-pinned release to the local staging stack and verifies it.

.DESCRIPTION
  Used for Laboratory 8 for the first release, the faulty release and the rollback.
  It never builds anything: it pulls the images named by the approved release record
  (the workflow's job summary prints the exact command), starts compose.staging.yaml,
  waits for /health, shows migration status and appends a row to release/deploy-log.csv.

  Migrations are NOT run unless you pass -RunMigrations, so the migration decision
  stays a deliberate, recorded step.

.EXAMPLE
  .\deploy-staging.ps1 `
    -AppImage ghcr.io/seannwyett/devop_activity/app@sha256:<64 hex> `
    -WebImage ghcr.io/seannwyett/devop_activity/web@sha256:<64 hex> `
    -ExpectedVersion v1.4.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AppImage,
    [Parameter(Mandatory = $true)][string]$WebImage,
    [string]$ExpectedVersion = '',
    [switch]$RunMigrations,
    [int]$TimeoutSeconds = 120,
    [string]$Project = 'devops-staging',
    [int]$Port = 8081
)

$ErrorActionPreference = 'Stop'
Set-Location -Path (Split-Path -Parent $PSCommandPath)

function Assert-Ok([string]$What) {
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit code $LASTEXITCODE)." }
}

# ---- 1. Pre-flight: refuse unsafe or unapproved inputs --------------------------------
foreach ($f in 'compose.staging.yaml', '.env.staging', '.env.staging.db') {
    if (-not (Test-Path $f)) { throw "Missing $f. Create it from its .example file first." }
}
foreach ($ref in $AppImage, $WebImage) {
    if ($ref -notmatch '@sha256:[0-9a-f]{64}$') {
        throw "Image reference must be digest-pinned (name@sha256:...): $ref"
    }
}
$envText = Get-Content -Path '.env.staging' -Raw
if ($envText -notmatch '(?m)^APP_KEY=base64:\S+') { throw 'APP_KEY is missing in .env.staging (generate it once and keep it).' }
if ($envText -match '(?m)^APP_DEBUG=\s*true') { throw 'APP_DEBUG=true found in .env.staging. Staging must be false.' }
if ($envText -match '(?m)^(APP_VERSION|GIT_SHA)=') { throw 'Remove APP_VERSION/GIT_SHA from .env.staging; they come from the image.' }

# ---- 2. Select the approved artifact and start the stack -------------------------------
$env:APP_IMAGE = $AppImage
$env:WEB_IMAGE = $WebImage
$env:STAGING_PORT = "$Port"
$compose = @('compose', '-p', $Project, '-f', 'compose.staging.yaml',
             '--env-file', '.env.staging', '--env-file', '.env.staging.db')

Write-Host "Deploying to project '$Project' on 127.0.0.1:$Port"
Write-Host "  app: $AppImage"
Write-Host "  web: $WebImage"

& docker @compose pull app web
if ($LASTEXITCODE -ne 0) {
    throw "Pull failed. If the GHCR package is private, run: docker login ghcr.io (use a token with read:packages)."
}
& docker @compose up -d --remove-orphans
Assert-Ok 'docker compose up'

# ---- 3. Wait for /health -------------------------------------------------------------
$url = "http://127.0.0.1:$Port/health"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$health = $null
while ((Get-Date) -lt $deadline) {
    try {
        $health = Invoke-RestMethod -Uri $url -TimeoutSec 5
        if ($health.status -eq 'ok') { break }
    } catch {
        $health = $null
    }
    Start-Sleep -Seconds 3
}

# ---- 4. Migration status (and migrate only when asked) -------------------------------
Write-Host ''
Write-Host '--- migrate:status ---'
& docker @compose exec -T app php artisan migrate:status
Assert-Ok 'migrate:status'
if ($RunMigrations) {
    Write-Host '--- migrate --force (explicitly requested) ---'
    & docker @compose exec -T app php artisan migrate --force
    Assert-Ok 'migrate --force'
}

# ---- 5. Verify the running revision --------------------------------------------------
$result = 'PASS'
$reason = ''
if (-not $health -or $health.status -ne 'ok') {
    $result = 'FAIL'; $reason = "health check did not return ok within $TimeoutSeconds s"
} elseif ($ExpectedVersion -and $health.version -ne $ExpectedVersion) {
    $result = 'FAIL'; $reason = "running version '$($health.version)' does not match expected '$ExpectedVersion'"
}

$finished = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
Write-Host ''
Write-Host '--- /health ---'
if ($health) { $health | ConvertTo-Json -Compress | Write-Host } else { Write-Host '(no response)' }
Write-Host "Result: $result $reason"
Write-Host "Finished: $finished"

# ---- 6. Append to the deployment log (no secrets in here) ----------------------------
if (-not (Test-Path 'release')) { New-Item -ItemType Directory -Path 'release' | Out-Null }
$row = [pscustomobject]@{
    finished_at    = $finished
    project        = $Project
    app_image      = $AppImage
    web_image      = $WebImage
    health_version = $(if ($health) { $health.version } else { '' })
    health_commit  = $(if ($health) { $health.commit } else { '' })
    migrations     = $(if ($RunMigrations) { 'migrate --force run' } else { 'status only' })
    result         = $result
    reason         = $reason
}
$row | Export-Csv -Path 'release/deploy-log.csv' -Append -NoTypeInformation
Write-Host 'Logged to release/deploy-log.csv'

if ($result -ne 'PASS') { exit 1 }
exit 0
