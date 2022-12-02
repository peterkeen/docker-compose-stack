#!/bin/sh

export HOSTNAME=$(cat /app/hostname)

echo "Loading secrets"
if test -f /configs/secrets; then
    . /configs/secrets
fi

if test -f /app/scripts/download_secrets.sh; then
    echo "Downloading secrets"
    download_secrets=$(/app/scripts/download_secrets.sh)
    echo "$download_secrets" | sha512sum | tee /configs/download_secrets.sha
    eval "$download_secrets"
fi

/app/run_compose.sh "$@"

