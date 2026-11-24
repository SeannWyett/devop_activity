#!/bin/sh
# Container entrypoint for the Render image.
# Render injects PORT (default 10000); nginx must listen on it.
set -eu

: "${PORT:=10000}"
export PORT

# Report a missing key by NAME only; never print secret values.
if [ -z "${APP_KEY:-}" ]; then
  echo "render-entrypoint: WARNING APP_KEY is not set; Laravel will fail on encrypted features" >&2
fi

envsubst '${PORT}' < /etc/nginx/nginx.conf.template > /tmp/nginx.conf

exec supervisord -c /etc/supervisor/render.conf
