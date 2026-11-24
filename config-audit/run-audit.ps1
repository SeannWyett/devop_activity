<#
.SYNOPSIS
  Runs the Laboratory 9 audit against a release image and, optionally, its live URL.

.DESCRIPTION
  Render free services have no shell, so the configuration audit runs in a THROWAWAY container
  started from the exact release image (a disposable clone). It never connects to a database.

  1. Image checks (docker CLI): the image runs as the baseline service user.
  2. Container checks: audit.sh inside the container with the environment from -EnvFile
     (effective Laravel settings, TLS mode, DB account, writable paths, document root, secrets).
  3. Live checks (only with -Url): health, HTTPS redirect, certificate validity, no debug output.

  Prints "<check_name> PASS|FAIL|UNVERIFIED" lines; exits 1 if any check failed.

.PARAMETER Image
  Digest-pinned image, e.g. ghcr.io/owner/repo/app@sha256:<64 hex> (a tag also works for practice).
.PARAMETER EnvFile
  A dotenv file with the values Render uses (.env.staging). Real secrets stay on your machine.
.PARAMETER Baseline
  File name inside config-audit/ (default baseline.example; baseline.production.example for production).
.PARAMETER CacheConfig
  Run "php artisan config:cache" first, then audit. Used for the Lab 9 drift/cache demonstration.

.EXAMPLE
  .\config-audit\run-audit.ps1 -Image ghcr.io/me/repo/app@sha256:... -EnvFile .env.staging -Url https://lab-staging.onrender.com | Tee-Object audit-before.txt
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Image,
    [string]$EnvFile = '',
    [string]$Baseline = 'baseline.example',
    [string]$Url = '',
    [switch]$CacheConfig
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$auditDir = Join-Path $repoRoot 'config-audit'
$baselinePath = Join-Path $auditDir $Baseline
if (-not (Test-Path $baselinePath)) { Write-Output "baseline_readable FAIL"; Write-Output "  note: $baselinePath not found"; exit 1 }
if ($EnvFile -and -not (Test-Path $EnvFile)) { Write-Output "env_file FAIL"; Write-Output "  note: $EnvFile not found"; exit 1 }

$script:failed = $false
function Report([string]$Name, [string]$Status, [string]$Note = '') {
    Write-Output "$Name $Status"
    if ($Note) { Write-Output "  note: $Note" }
    if ($Status -eq 'FAIL') { $script:failed = $true }
}
function Get-Base([string]$Key) {
    $m = Select-String -Path $baselinePath -Pattern "^$Key=(.*)$" | Select-Object -First 1
    if ($m) { return $m.Matches[0].Groups[1].Value.Trim() }
    return ''
}

# ---- 1. image-level check --------------------------------------------------------------------
& docker pull $Image 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    # A locally built practice image is fine; only fail if it does not exist locally either.
    & docker image inspect $Image 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Report 'image_available' 'FAIL' "cannot pull or find $Image (docker login ghcr.io for private packages)"; exit 1 }
}
$imgUser = (& docker image inspect --format '{{.Config.User}}' $Image).Trim()
$wantUser = Get-Base 'SERVICE_USER'
if (-not $imgUser -or $imgUser -eq 'root' -or $imgUser -eq '0') { Report 'image_user_nonroot' 'FAIL' "image default user is '$imgUser'" }
elseif ($imgUser -eq $wantUser) { Report 'image_user_nonroot' 'PASS' }
else { Report 'image_user_nonroot' 'FAIL' "expected '$wantUser', image user '$imgUser'" }

# ---- 2. configuration audit inside a throwaway container -----------------------------------
$dockerArgs = @('run', '--rm')
if ($EnvFile) { $dockerArgs += @('--env-file', $EnvFile) }
$dockerArgs += @('-v', "${auditDir}:/audit:ro", '--entrypoint', 'sh', $Image, '-c')
$inner = "sh /audit/audit.sh /audit/$Baseline"
if ($CacheConfig) { $inner = "php artisan config:cache > /dev/null 2>&1; $inner" }
$dockerArgs += $inner

$inside = & docker @dockerArgs 2>&1 | ForEach-Object { "$_" }
$insideCode = $LASTEXITCODE
foreach ($line in $inside) {
    if ($line -match '^(---|overall )') { continue }   # one combined summary is printed below
    Write-Output $line
}
if ($insideCode -ne 0) { $script:failed = $true }

# ---- 3. live checks (optional) ----------------------------------------------------------------
if ($Url) {
    $base = $Url.TrimEnd('/')
    $uri = [Uri]$base
    $tmp = [IO.Path]::GetTempFileName()

    # Free Render services sleep; the first request can take about a minute.
    $healthRaw = & curl.exe -sS --max-time 120 "$base/health" 2>$null
    try { $health = $healthRaw | ConvertFrom-Json } catch { $health = $null }
    if ($health -and $health.status -eq 'ok') { Report 'live_health' 'PASS' "version $($health.version), commit $($health.commit)" }
    else { Report 'live_health' 'FAIL' "no healthy /health response from $base" }

    if ($uri.Scheme -eq 'https') {
        # HTTP must redirect to HTTPS.
        $r = & curl.exe -s -o NUL --max-time 30 -w '%{http_code} %{redirect_url}' "http://$($uri.Host)/" 2>$null
        if ($r -match '^30[1278] https://') { Report 'live_https_redirect' 'PASS' }
        elseif ($r -match '^000') { Report 'live_https_redirect' 'UNVERIFIED' 'plain-HTTP port did not answer' }
        else { Report 'live_https_redirect' 'FAIL' "http answered: $r" }

        # Certificate validity and remaining lifetime.
        try {
            $script:sslErrors = $null
            $tcp = New-Object System.Net.Sockets.TcpClient($uri.Host, 443)
            $cb = [System.Net.Security.RemoteCertificateValidationCallback]{ param($s, $c, $ch, $e) $script:sslErrors = $e; $true }
            $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, $cb)
            $ssl.AuthenticateAsClient($uri.Host)
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)
            $days = [int]($cert.NotAfter - (Get-Date)).TotalDays
            $minDays = [int](Get-Base 'MIN_CERT_DAYS')
            $ssl.Dispose(); $tcp.Close()
            if ("$script:sslErrors" -ne 'None') { Report 'tls_certificate' 'FAIL' "certificate validation: $script:sslErrors" }
            elseif ($days -lt $minDays) { Report 'tls_certificate' 'FAIL' "expires in $days days (minimum $minDays); subject $($cert.Subject)" }
            else { Report 'tls_certificate' 'PASS' "valid, $days days left, issuer $($cert.Issuer)" }
        } catch {
            Report 'tls_certificate' 'UNVERIFIED' "could not read certificate: $($_.Exception.Message)"
        }
    } else {
        Report 'live_https_redirect' 'FAIL' "URL is not https: $base"
        Report 'tls_certificate' 'FAIL' 'no TLS on this URL'
    }

    # Debug mode must not leak a stack trace on an error page.
    $code = & curl.exe -s -o $tmp --max-time 60 -w '%{http_code}' "$base/lab9-this-route-does-not-exist" 2>$null
    $body = Get-Content -Raw -Path $tmp -ErrorAction SilentlyContinue
    Remove-Item $tmp -ErrorAction SilentlyContinue
    if ($code -ne '404') { Report 'live_no_debug_output' 'UNVERIFIED' "expected 404, got $code" }
    elseif ($body -match 'Whoops|Stack trace|vendor/laravel|Illuminate\\') { Report 'live_no_debug_output' 'FAIL' 'error page exposes framework internals' }
    else { Report 'live_no_debug_output' 'PASS' }
} else {
    Report 'tls_certificate' 'UNVERIFIED' 'run with -Url to check the live certificate'
}

Report 'platform_patching_and_firewall' 'UNVERIFIED' 'owned by Render (platform) and Supabase (database); describe the shared responsibility in the report'

# ---- combined result -------------------------------------------------------------------------
Write-Output '---'
if ($script:failed) { Write-Output 'overall FAIL'; exit 1 }
Write-Output 'overall PASS'
exit 0
