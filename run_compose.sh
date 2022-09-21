#!/bin/sh

set -eo pipefail

echo "Running pre-start scripts"
scripts=$(yq '(.defaults.pre-start // []) *+ (.hosts[env(HOSTNAME)].pre-start // []) | join(" ")' hosts.yml)

for script in $scripts; do
    echo "Executing pre-start $script"
    scripts/$script
done

echo "Copying configs"
configs=$(yq '(.defaults.configs // []) *+ (.hosts.[env(HOSTNAME)].configs // []) | map("configs/" + .) | join(" ")' hosts.yml)

for config in $configs; do
    cp -a /app/$config /configs
done

echo "Creating .env file"
echo "__DOCKERSTACK_ENV=1" > /app/.env
envs=$(yq '(.defaults.environment // []) *+ (.hosts.[env(HOSTNAME)].environment // []) | join("\n")' hosts.yml)
printf "$envs" >> /app/.env

echo "Calculating CONFIGS_SHA"
export CONFIGS_SHA=$(tar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2022-01-01' -C / -cf - /configs /app/.env | sha256sum | cut -d' ' -f1)

echo "Determining stacks"
stacks=$(yq '(.defaults.stacks // []) *+ (.hosts.[env(HOSTNAME)].stacks // []) | map("-f stacks/" + . + ".yml") | join(" ")' hosts.yml)

base_docker_compose="/usr/bin/docker-compose --ansi never -f docker-compose.yml $stacks"

echo "Setting up crons"
crons=$(yq "(.defaults.crons // []) *+ (.hosts[env(HOSTNAME)].crons // []) | map(.schedule + \" cd /app && $base_docker_compose run --rm -T \" + .service + \" > /proc/1/fd/1 2>&1\") | join(\"\n\")" hosts.yml)
echo "$crons" > /etc/cron.d/dockerstack
echo "13 2 * * * docker image prune -f" > /etc/cron.d/dockerprune

echo "Running compose"
if [ -z "$1" ]; then
    exec $base_docker_compose up --no-color --remove-orphans --quiet-pull --detach
else
    exec $base_docker_compose "$@"
fi
