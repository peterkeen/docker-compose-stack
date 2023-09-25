FROM docker:cli

RUN apk add --no-cache s6-portable-utils dcron tar yq
RUN mkdir /app
RUN ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
WORKDIR /app

ADD . /app

ENTRYPOINT ["/app/start.sh"]
