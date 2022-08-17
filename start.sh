#!/bin/sh

echo "Running compose"
/usr/bin/docker-compose --ansi never -f /app/docker-compose.yml up --no-color --remove-orphans --quiet-pull --detach

echo "Pausing forever"
s6-pause
