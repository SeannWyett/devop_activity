#!/bin/sh
# Laboratory 9 configuration audit - run INSIDE the app container
# (config-audit/run-audit.ps1 copies this folder in and runs it for you).
#
# Output: one line per check, "<check_name> <PASS|FAIL|UNVERIFIED>", optionally followed
#         by an indented "note:" line (never contains a secret).
# Exit:   1 if any check FAILED, otherwise 0. UNVERIFIED does not fail the run;
#         it means the control cannot be observed from here.
# Usage:  sh audit.sh [path/to/baseline.example]

HERE=$(cd "$(dirname "$0")" && pwd)
BASELINE=${1:-$HERE/baseline.example}
APP_ROOT=${APP_ROOT:-/var/www/html}
export APP_ROOT
FAILED=0

if [ ! -r "$BASELINE" ]; then
  echo "baseline_readable FAIL"
  echo "  note: cannot read $BASELINE"
  exit 1
fi

# ---- helpers -------------------------------------------------------------------------
base() { grep -E "^$1=" "$BASELINE" | head -n 1 | cut -d= -f2- | tr -d '\r'; }

report() { # report <name> <PASS|FAIL|UNVERIFIED> [note]
  echo "$1 $2"
  if [ -n "$3" ]; then echo "  note: $3"; fi
  if [ "$2" = "FAIL" ]; then FAILED=1; fi
}

# ---- application context (effective Laravel settings) ---------------------------------
PROBE=$(php "$HERE/probe.php" 2>/dev/null)
get() { printf '%s\n' "$PROBE" | grep -E "^$1=" | head -n 1 | cut -d= -f2-; }

if [ -z "$PROBE" ]; then
  report app_context_probe FAIL "probe.php could not boot Laravel; config checks are UNVERIFIED"
else
  report app_context_probe PASS
fi

check_value() { # check_value <name> <actual> <expected>
  if [ -z "$PROBE" ]; then
    report "$1" UNVERIFIED "application context unavailable"
  elif [ "$2" = "$3" ]; then
    report "$1" PASS
  else
    report "$1" FAIL "expected '$3', effective value '$2'"
  fi
}

check_value debug_off "$(get app.debug)" "$(base APP_DEBUG)"
check_value app_env_label "$(get app.env)" "$(base APP_ENV)"

# Secrets: presence or absence only, never the value.
if [ -z "$PROBE" ]; then
  report app_key_present UNVERIFIED "application context unavailable"
elif [ "$(get app_key_present)" = "yes" ]; then
  report app_key_present PASS
else
  report app_key_present FAIL "APP_KEY is empty"
fi

# A stale configuration cache hides drift: cached value differs from the runtime env.
cached=$(get config_cached); envdbg=$(get env.app_debug); effdbg=$(get app.debug)
if [ -z "$PROBE" ]; then
  report config_cache_current UNVERIFIED "application context unavailable"
elif [ "$cached" = "yes" ] && [ -n "$envdbg" ] && [ "$envdbg" != "$effdbg" ]; then
  report config_cache_current FAIL "cached config differs from runtime env; run php artisan config:cache"
else
  report config_cache_current PASS
fi

# ---- database account ------------------------------------------------------------------
dbuser=$(get db.username)
if [ -z "$PROBE" ]; then
  report db_runtime_account UNVERIFIED "application context unavailable"
elif [ "$dbuser" = "root" ]; then
  report db_runtime_account FAIL "app connects as root"
elif [ "$dbuser" != "$(base DB_USERNAME)" ]; then
  report db_runtime_account FAIL "expected '$(base DB_USERNAME)', effective '$dbuser'"
else
  report db_runtime_account PASS
fi
report database_access_scope UNVERIFIED "grants are not queried from the app container; needs DBA access"

# ---- service identity ------------------------------------------------------------------
who=$(id -un)
if [ "$(id -u)" = "0" ]; then
  report service_user FAIL "service runs as root"
elif [ "$who" = "$(base SERVICE_USER)" ]; then
  report service_user PASS
else
  report service_user FAIL "expected '$(base SERVICE_USER)', running as '$who'"
fi

# ---- writable paths: writable by the service account, not world-writable ----------------
ok=1; why=""
for p in $(base WRITABLE_PATHS); do
  d="$APP_ROOT/$p"
  if [ ! -d "$d" ]; then ok=0; why="$why $p:missing"; continue; fi
  if [ ! -w "$d" ]; then ok=0; why="$why $p:not-writable-by-$who"; fi
  mode=$(stat -c %a "$d")
  other=$(printf '%s' "$mode" | tail -c 1)
  case "$other" in
    0|1|4|5) ;;
    *) ok=0; why="$why $p:world-writable($mode)" ;;
  esac
done
if [ "$ok" = "1" ]; then report writable_paths PASS; else report writable_paths FAIL "$why"; fi

# ---- document root (application side) ---------------------------------------------------
root=$(base DOCUMENT_ROOT)
if [ -f "$root/index.php" ] && [ ! -e "$root/.env" ] && [ ! -e "$root/composer.json" ]; then
  report document_root PASS
else
  report document_root FAIL "$root must contain index.php and must not contain .env or composer.json"
fi

# ---- secrets must not be baked into the image --------------------------------------------
if [ -e "$APP_ROOT/.env" ]; then
  report env_file_not_in_image FAIL ".env exists in the image; check .dockerignore"
else
  report env_file_not_in_image PASS
fi

echo "---"
if [ "$FAILED" = "0" ]; then echo "overall PASS"; else echo "overall FAIL"; fi
exit "$FAILED"
