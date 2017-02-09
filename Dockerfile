#
# Dockerfile for ocserv
#

FROM ubuntu:zesty
MAINTAINER stawidy <duyizhaozj321@yahoo.com>

RUN set -x \
    && apt-get update \
    && apt-get install -y ocserv iptables gnutls-bin \
    && sed -i 's/\.\/sample\.passwd/\/etc\/ocserv\/ocpasswd/' /etc/ocserv/ocserv.conf \
    && sed -i 's/\(max-same-clients = \)2/\110/' /etc/ocserv/ocserv.conf \
    && sed -i 's/\.\.\/tests/\/etc\/ocserv/' /etc/ocserv/ocserv.conf \
    && sed -i 's/#\(compression.*\)/\1/' /etc/ocserv/ocserv.conf \
    && sed -i 's/192.168.1.2/8.8.8.8/' /etc/ocserv/ocserv.conf \
    && sed -i 's/^route/#route/' /etc/ocserv/ocserv.conf \
    && sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \
    && sed -i 's/^auth/#auth/' /etc/ocserv/ocserv.conf \
    && echo 'auth = "plain[passwd=/etc/ocserv/ocpasswd]"' >> /etc/ocserv/ocserv.conf \
    && cd .. \
    && apt-get clean

COPY init.sh /init.sh
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME /etc/ocserv

ENV VPN_DOMAIN    your.domain.name
ENV VPN_NETWORK   10.0.6.0
ENV VPN_NETMASK   255.255.255.0
ENV TERM          xterm

EXPOSE 443/tcp 443/udp

ENTRYPOINT ["/entrypoint.sh"]
