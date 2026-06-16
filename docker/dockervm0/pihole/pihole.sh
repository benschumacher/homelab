#!/bin/sh
PIHOLE_VERSION=2026.06.0
(docker stop pihole && docker rm pihole) >/dev/null
docker run \
	--detach \
	--ip 172.15.0.3 \
	--network custom_bridge \
        --name pihole \
	--cap-add SYS_NICE \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/timezone:/etc/timezone:ro \
	-v pihole_conf:/etc/pihole \
	-v pihole_dnsmasq_conf:/etc/dnsmasq.d \
	-p "53:53/tcp" \
	-p "53:53/udp" \
	-p "80:80/tcp" \
	-p "443:443/tcp" \
        --restart=unless-stopped \
	--hostname pi.hole \
	-e "VIRTUAL_HOST=pi.hole" \
	-e "PROXY_LOCATION=pi.hole" \
	-e "TZ=$(cat /etc/timezone)" \
	-e "CORS_HOSTS=home.gleichmacher.us" \
	-e "FTLCONF_LOCAL_IPV4=192.168.11.12" \
	-e "FTLCONF_dns_listeningMode=ALL" \
	-e REFRESH_HOSTNAMES=IPV4 \
	pihole/pihole:${PIHOLE_VERSION}

#	--dns=127.0.0.1 --dns=1.1.1.1 \
#	-e FTLCONF_dns_upstreams="172.17.0.4#5053;1.0.0.3" \

