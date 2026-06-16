#!/bin/sh
BASE_DIR=$(dirname -- "$(readlink -f -- "$0")")
docker run --name=dnscrypt-proxy --hostname=dnscrypt-proxy \
	--detach --restart=unless-stopped --rm \
	--user="$(id -u nobody):$(id -g nobody)" \
	--volume="${BASE_DIR}/config/dnscrypt-proxy:/config" \
	--expose=5053/tcp --expose=5053/udp \
	--network=custom_bridge --ip=172.15.0.4 \
    klutchell/dnscrypt-proxy
