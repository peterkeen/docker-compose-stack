FROM alpine:3

RUN apk update && apk add s6-portable-utils dcron tar yq docker
RUN mkdir /app
WORKDIR /app

ADD . /app

ENTRYPOINT ["/app/start.sh"]
