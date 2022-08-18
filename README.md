# Docker Compose Stack

This is an experiment that uses `docker-compose` within a container to self-deploy
a stack of containers, along with `watchtower` to auto-update that stack.

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

Every stack listed for a host is added as a `-f` argument to the `docker-compose` invocation, which merges every file together using it's ordinary merge logic.

Stacks are similar in concept to Compose's built-in `profiles` concept with the important difference that if you remove a stack from a host those containers will be stopped and destroyed on next run.

## First Run

```bash
$ docker run -d -it -v /var/run/docker.sock:/var/run/docker.sock -e HOSTNAME=$(hostname -s) ghcr.io/peterkeen/docker-compose-stack:main
```
