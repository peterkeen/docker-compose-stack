FROM alpine:3

RUN apk update && apk add s6-portable-utils dcron tar yq docker
ADD https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-linux-x86_64 /usr/bin/docker-compose
RUN chmod +x /usr/bin/docker-compose
RUN mkdir /app
WORKDIR /app

ADD . /app

ENTRYPOINT ["/app/start.sh"]
