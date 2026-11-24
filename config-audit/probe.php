<?php

// Application-context check: boots Laravel exactly as the running service does
// (so a cached configuration is honoured) and prints the EFFECTIVE settings as
// key=value lines. It never connects to the database. Secrets are reported as
// presence only, never as values.
// Run it through config-audit/audit.sh inside the container.

$root = getenv('APP_ROOT') ?: '/var/www/html';

require $root.'/vendor/autoload.php';
$app = require $root.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$bool = static fn ($value): string => $value ? 'true' : 'false';
$runtimeDebug = getenv('APP_DEBUG');
$connection = (string) config('database.default');

$lines = [
    'app.env' => (string) config('app.env'),
    'app.debug' => $bool(config('app.debug')),
    'app.url' => (string) config('app.url'),
    'app_key_present' => strlen((string) config('app.key')) > 0 ? 'yes' : 'no',
    'config_cached' => $app->configurationIsCached() ? 'yes' : 'no',
    'env.app_debug' => $runtimeDebug === false ? '' : strtolower((string) $runtimeDebug),
    'db.connection' => $connection,
    'db.host_present' => strlen((string) config("database.connections.{$connection}.host")) > 0 ? 'yes' : 'no',
    'db.username' => (string) config("database.connections.{$connection}.username"),
    'db.sslmode' => (string) (config("database.connections.{$connection}.sslmode") ?? ''),
    'release.version' => (string) config('release.version'),
    'release.commit' => (string) config('release.commit'),
];

foreach ($lines as $key => $value) {
    echo $key.'='.str_replace(["\r", "\n"], ' ', $value).PHP_EOL;
}
