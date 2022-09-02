# Docker Compose Stack

This is an experiment that uses `docker-compose` within a container to self-deploy
a stack of containers, along with `watchtower` to auto-update that stack.

The central conceit is that by using `watchtower` we can run the container built from this repo once on every host and
it, along with service containers, will be automatically updated. When this container is updated it will re-run
`docker-compose up`, which will start new services and remove old services as needed.

## Usage

1. Make a new empty GitHub repository for your stack config
2. `git clone https://github.com/peterkeen/docker-compose-stack`
3. `cd docker-compose-stack && git remote remove origin && git remote add origin git@github.com:yourusername/yourrepo.git`
4. `git push origin main`

On every host you want to use this on:

```bash
$ mkdir /var/lib/docker/stack_configs
$ docker run --init --restart=unless-stopped -d -it -v /var/lib/docker/stack_configs:/configs -v /var/run/docker.sock:/var/run/docker.sock -v /etc/hostname:/app/hostname:ro -e CONFIGS_DIR=/var/lib/docker/stack_configs --name dockerstack-root -l dockerstack-root ghcr.io/yourusername/yourrepo:main
```

### Caveats

* As written this only works on x86-64 linux. If you need to run in a different environment you'll need to update `Dockerfile` to pull the correct docker-compose release binary.

## Stacks

The idea of stacks is that we can use one repo to deploy to multiple hosts.
First we create a docker-compose file within `stacks/` for every different stack of containers we want to deploy. For example, here's `stacks/echo.yml`:

```yaml
services:
  http-echo:
    image: hashicorp/http-echo
    ports:
      - "5678:5678"
    command: "-text=foobarbaz"
```

Then we set a list of `stacks` in `hosts.yml` for every host like this:

```yaml
hosts:
  martin:
    stacks: ["echo"]
```

Every stack listed for a host is added as a `-f` argument to the `docker-compose` invocation, which merges every file together using its ordinary merge logic.

Stacks are similar in concept to Compose's built-in `profiles` concept with the important difference that if you remove a stack from a host those containers will be stopped and destroyed on next run.

## Configs

Configs live in `configs/` in named directories. Hosts can define what configs they want, and then those directories are copied to the host and made available for stacks to bind mount. The bind mounting does not happen automatically, you still have to specify the bind mounts you want to happen.

## Environments

Each host can optionally define a set of environment variables in the `environment` key as an array of strings. The contents of this array is written to a `.env` file before invoking `docker-compose`.

## Secrets

You can optionally create a file on the host at `/var/lib/docker/stack_configs/secrets`. This file is sourced in `start.sh` so can contain any valid `ash` statements. Secrets defined here are available for services, pre-start scripts, and crons. Generally you'd put a bunch of `export`s in, like this:

```
export SOME_SECRET=this-is-secret
export SOME_OTHER_SECRET=this-is-also-secret
```

## Pre-start scripts

A host can optionally define a `pre-start` key consisting of an array of script names to run. Each script must be executable and live in `scripts/`. Example:

in `scripts/testing-prestart.sh`:

```sh
#!/bin/sh

echo "this is a prestart script"
```

in `hosts.yml`:

```yaml
hosts:
  somehost:
    pre-start: ["testing-prestart.sh"]
```

## Crons

After executing `docker-compose up` `start.sh` will then exec itself to `crond`. Cron jobs are services defined in a stack with the `cron` profile:

in `stacks/test.yml`

```yaml
services:
  testcron:
    image: alpine
    profiles:
      - cron
```

Setting a profile means that this service will not automatically be started by `docker-compose` but it is available to be run. To define the cron schedule, set a host-level `crons` key like this:

```yaml
hosts:
  somehost:
    stacks: ["test"]
    crons:
      - schedule: "* * * * *"
        service: "testcron"
```
