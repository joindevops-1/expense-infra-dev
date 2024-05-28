#!/bin/bash

# Define variables
OPENVPN_USER="openvpn"
OPENVPN_PASSWORD="Abcd@1234"
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Update the package list
apt update -y

# Accept the OpenVPN Access Server license agreement and perform initial configuration
/usr/local/openvpn_as/bin/ovpn-init --force --batch <<EOF
yes
yes
1
secp384r1
secp384r1
943
443
yes
yes
yes
yes
Abcd@1234
Abcd@1234

EOF

# Wait for OpenVPN Access Server to start and initialize
while ! nc -z localhost 943; do
    echo "Waiting for OpenVPN Access Server to start..."
    sleep 2
done

# Set the OpenVPN user password using sacli
/usr/local/openvpn_as/scripts/sacli --user $OPENVPN_USER --new_pass $OPENVPN_PASSWORD SetLocalPassword

# Configure OpenVPN to push specific DNS servers to clients
/usr/local/openvpn_as/scripts/sacli ConfigPut vpn.server.dns.client "['$DNS1', '$DNS2']"
/usr/local/openvpn_as/scripts/sacli ConfigPut vpn.client.routing.reroute_dns true
/usr/local/openvpn_as/scripts/sacli ConfigPut vpn.client.routing.reroute_gw true

# Restart OpenVPN Access Server to apply changes
/usr/local/openvpn_as/scripts/sacli start

echo "OpenVPN Access Server configuration completed."

yes
yes
1
secp384r1
secp384r1
943
443
yes
yes
yes
yes
Abcd@1234
Abcd@1234
