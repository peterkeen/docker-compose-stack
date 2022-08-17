FROM alpine:3

RUN apk update && apk add s6-portable-utils
ADD https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-linux-x86_64 /usr/bin/docker-compose
RUN chmod +x /usr/bin/docker-compose
RUN mkdir /app
ADD start.sh /app/start.sh

ADD docker-compose.yml /app/docker-compose.yml

CMD ["/app/start.sh"]
