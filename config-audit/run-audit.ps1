<#
.SYNOPSIS
  Runs the full Laboratory 9 audit against a running staging (or clone) stack.

.DESCRIPTION
  1. Copies config-audit/ into the app container and runs audit.sh there
     (effective Laravel settings, service user, writable paths, document root, secrets).
  2. Runs the checks that can only be seen from the host with the docker CLI
     (database ports, published web port, nginx document root, running services).
  Prints "<check_name> PASS|FAIL|UNVERIFIED" lines and exits 1 if any check failed.

.EXAMPLE
  .\config-audit\run-audit.ps1 | Tee-Object -FilePath audit-before.txt

.EXAMPLE
  # Disposable clone on another port
  .\config-audit\run-audit.ps1 -Project devops-clone -ExposedPorts 127.0.0.1:8082
#>
[CmdletBinding()]
param(
    [string]$Project = 'devops-staging',
    [string]$ExposedPorts = ''
)

# Native commands write to stderr; keep going and check $LASTEXITCODE ourselves.
$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location -Path $repoRoot

$baselinePath = Join-Path $repoRoot 'config-audit/baseline.example'
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

$app = "$Project-app-1"
$web = "$Project-web-1"
$db = "$Project-db-1"

foreach ($c in $app, $web, $db) {
    $state = & docker inspect --format '{{.State.Running}}' $c 2>$null
    if ($LASTEXITCODE -ne 0 -or $state -ne 'true') {
        Write-Output "stack_running FAIL"
        Write-Output "  note: container $c is not running (project '$Project')"
        exit 1
    }
}

# ---- 1. inside the app container ---------------------------------------------------------
$dest = '/tmp/audit-' + (Get-Date -Format 'yyyyMMddHHmmss')
& docker cp (Join-Path $repoRoot 'config-audit') "${app}:${dest}" | Out-Null
if ($LASTEXITCODE -ne 0) { Report 'copy_audit_into_container' 'FAIL' 'docker cp failed'; exit 1 }

$inside = & docker exec $app sh "$dest/audit.sh" "$dest/baseline.example" 2>&1 | ForEach-Object { "$_" }
$insideCode = $LASTEXITCODE
foreach ($line in $inside) {
    if ($line -match '^(---|overall )') { continue }   # we print one combined summary below
    Write-Output $line
}
if ($insideCode -ne 0) { $script:failed = $true }

# ---- 2. host-side checks -------------------------------------------------------------------
# Database must not publish any port to the host.
$portsJson = & docker inspect --format '{{json .NetworkSettings.Ports}}' $db
$ports = $portsJson | ConvertFrom-Json
$published = @($ports.PSObject.Properties | Where-Object { $_.Value })
if ($published.Count -eq 0) { Report 'db_ports_not_published' 'PASS' }
else { Report 'db_ports_not_published' 'FAIL' ("published: " + (($published | ForEach-Object { $_.Name }) -join ', ')) }

# The web service must be published only where the baseline says.
$expectedExposed = $ExposedPorts
if (-not $expectedExposed) { $expectedExposed = Get-Base 'EXPOSED_PORTS' }
$bindings = @(& docker port $web 80/tcp 2>$null | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
if ($bindings.Count -eq 0) { Report 'web_exposure' 'FAIL' 'no published port found for web' }
elseif (@($bindings | Where-Object { $_ -ne $expectedExposed }).Count -eq 0) { Report 'web_exposure' 'PASS' }
else { Report 'web_exposure' 'FAIL' ("expected $expectedExposed, found " + ($bindings -join ', ')) }

# nginx must serve Laravel's public/ directory.
$expectedRoot = Get-Base 'DOCUMENT_ROOT'
$nginxConf = & docker exec $web nginx -T 2>&1 | ForEach-Object { "$_" }
$roots = @($nginxConf | Select-String -Pattern '^\s*root\s+(\S+);' | ForEach-Object { $_.Matches[0].Groups[1].Value })
if ($roots.Count -eq 0) { Report 'nginx_document_root' 'UNVERIFIED' 'no root directive found in nginx -T output' }
elseif (@($roots | Where-Object { $_ -ne $expectedRoot }).Count -eq 0) { Report 'nginx_document_root' 'PASS' }
else { Report 'nginx_document_root' 'FAIL' ("expected $expectedRoot, found " + ($roots -join ', ')) }

# Only the expected services may be running in this project.
$expectedNames = (Get-Base 'EXPECTED_SERVICES') -split '\s+' | Where-Object { $_ } | ForEach-Object { "$Project-$_-1" }
$running = @(& docker ps --filter "label=com.docker.compose.project=$Project" --format '{{.Names}}' | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
$extra = @($running | Where-Object { $expectedNames -notcontains $_ })
$missing = @($expectedNames | Where-Object { $running -notcontains $_ })
if ($extra.Count -eq 0 -and $missing.Count -eq 0) { Report 'unnecessary_services' 'PASS' }
else { Report 'unnecessary_services' 'FAIL' ("unexpected: [" + ($extra -join ', ') + "] missing: [" + ($missing -join ', ') + "]") }

# Cannot be observed on a local HTTP-only stack.
Report 'tls_certificate' 'UNVERIFIED' 'staging is plain HTTP on loopback; there is no certificate to check'
Report 'patching_and_firewall_ownership' 'UNVERIFIED' 'organisational control; describe the owner in the report'

# ---- combined result -------------------------------------------------------------------------
Write-Output '---'
if ($script:failed) { Write-Output 'overall FAIL'; exit 1 }
Write-Output 'overall PASS'
exit 0
