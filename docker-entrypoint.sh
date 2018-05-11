#!/bin/sh

if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
	# No certification found, generate one
	mkdir /etc/ocserv/certs
	cd /etc/ocserv/certs
	certtool --generate-privkey --outfile ca-key.pem
	cat > ca.tmpl <<-EOCA
	cn = "$CA_CN"
	organization = "$CA_ORG"
	serial = 1
	expiration_days = $CA_DAYS
	ca
	signing_key
	cert_signing_key
	crl_signing_key
	EOCA
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca.pem
	certtool --generate-privkey --outfile server-key.pem
	cat > server.tmpl <<-EOSRV
	cn = "$SRV_CN"
	organization = "$SRV_ORG"
	expiration_days = $SRV_DAYS
	signing_key
	encryption_key
	tls_www_server
	EOSRV
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
fi

# Set ipv4-network & ipv4-netmask
sed -i  -e "s/^ipv4-network =.*/ipv4-network = ${VPN_NETWORK}/" \
        -e "s/^ipv4-netmask =.*/ipv4-netmask = ${VPN_NETMASK}/" \
        /etc/ocserv/ocserv.conf

# Set no-route
echo "no-route = 192.168.0.0/255.255.0.0" >> /etc/ocserv/ocserv.conf
echo "no-route = 10.0.0.0/255.0.0.0" >> /etc/ocserv/ocserv.conf
echo "no-route = 172.16.0.0/255.240.0.0" >> /etc/ocserv/ocserv.conf
echo "no-route = 127.0.0.0/255.0.0.0" >> /etc/ocserv/ocserv.conf

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Enable TUN device
mkdir -p /dev/net
rm -f /dev/net/tun
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Run OpennConnect Server
exec "$@"
