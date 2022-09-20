#!/bin/sh

export HOSTNAME=$(cat /app/hostname)

echo "Loading secrets"
if test -f /configs/secrets; then
    . /configs/secrets
fi

if test -f /app/scripts/download_secrets.sh; then
    . /app/scripts/download_secrets.sh
fi

/app/run_compose.sh "$@"

if [ -z "$1" ]; then
    echo "Running cron"
    exec crond -f
fi
