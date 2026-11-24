<#
.SYNOPSIS
  Runs ONE artisan command with the exact release image against the database in an env file.

.DESCRIPTION
  Render free services have no shell or SSH, so migrations, migration status and seeding of the
  fictional lab accounts are run from your machine instead: a throwaway container from the same
  digest-pinned image, with the staging (or production) environment variables.
  The container is removed afterwards; nothing is written to your repo.

.EXAMPLE
  .\scripts\artisan-remote.ps1 -Image ghcr.io/me/repo/app@sha256:... -EnvFile .env.staging -Command "migrate:status"
.EXAMPLE
  .\scripts\artisan-remote.ps1 -Image ... -EnvFile .env.staging -Command "migrate --force"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][string]$EnvFile,
    [Parameter(Mandatory = $true)][string]$Command,
    [switch]$ConfirmProduction
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $EnvFile)) { throw "Env file not found: $EnvFile" }
if ($Image -notmatch '@sha256:[0-9a-f]{64}$') { throw "Use the approved digest-pinned image (name@sha256:...), not a tag: $Image" }

$envText = Get-Content -Raw -Path $EnvFile
if ($envText -match '(?m)^APP_ENV=production' -and -not $ConfirmProduction) {
    throw 'This env file targets PRODUCTION. Re-run with -ConfirmProduction if that is intended.'
}
$hostLine = Select-String -Path $EnvFile -Pattern '^DB_HOST=(.*)$' | Select-Object -First 1
$dbHost = if ($hostLine) { $hostLine.Matches[0].Groups[1].Value.Trim() } else { '(not set)' }

Write-Host "Image   : $Image"
Write-Host "Database: $dbHost (password not shown)"
Write-Host "Command : php artisan $Command"
Write-Host ''

& docker pull $Image
if ($LASTEXITCODE -ne 0) { throw 'Pull failed. For a private GHCR package run: docker login ghcr.io' }

$artisanArgs = $Command -split '\s+' | Where-Object { $_ }
& docker run --rm --env-file $EnvFile -e APP_DEBUG=false --entrypoint php $Image artisan @artisanArgs
exit $LASTEXITCODE
