#!/bin/sh

echo "Determining stacks"
stacks=$(yq '.hosts.martin.stacks // [] | map("-f stacks/" + . + ".yml") | join(" ")' hosts.yml)

echo "Running compose"
/usr/bin/docker-compose --ansi never -f docker-compose.yml $stacks up --no-color --remove-orphans --quiet-pull --detach

echo "Pausing forever"
s6-pause
