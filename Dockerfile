FROM    golang:alpine3.8 AS build

WORKDIR /go/src/github.com/adnanh/webhook
ENV     WEBHOOK_VERSION 2.6.9

RUN     apk add --update -t build-deps curl libc-dev gcc libgcc
RUN     curl -L --silent -o webhook.tar.gz https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz \
    &&  tar -xzf webhook.tar.gz --strip 1 \
    &&  go get -d \
    &&  go build -o /usr/local/bin/webhook \
    &&  apk del --purge build-deps \
    &&  rm -rf /var/cache/apk/* \
    &&  rm -rf /go

FROM    alpine:3.8

ENV     dumb-init-version v1.2.2

COPY    --from=build /usr/local/bin/webhook /usr/local/bin/webhook
COPY    start.sh /usr/local/bin/start.sh

RUN     apk update \
    &&  apk upgrade \
    &&  apk add curl wget vim bash jq inotify-tools \
    &&  curl -L --silent -o /usr/local/bin/kubectl https://www.cnrancher.com/download/kubectl/kubectl_amd64-linux  \
    &&  wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${dumb-init-version}/dumb-init_${dumb-init-version}_amd64 \
    &&  chmod +x /usr/local/bin/dumb-init /usr/local/bin/start.sh /usr/local/bin/kubectl \ 
    &&  mkdir -p /etc/webhook \
    &&  touch /etc/webhook/hooks.json \
    &&  rm -rf /var/cache/apk/*  \
    &&  echo 104857600 > /proc/sys/fs/inotify/max_user_watches


VOLUME  /etc/webhook
WORKDIR /etc/webhook

EXPOSE  9000

#ENTRYPOINT  ["/usr/local/bin/webhook"]
#CMD         ["-verbose", "-hooks=/etc/webhook/hooks.json", "-hotreload"]

ENTRYPOINT   ["/usr/bin/dumb-init", "--"]
CMD          ["bash", "-c", "/usr/local/bin/webhook -verbose -hooks=/etc/webhook/hooks.json -hotreload && exec start.sh"]
