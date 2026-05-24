#!/bin/bash
# SlowDNS over SSH Setup Script for Ubuntu/Debian by DEBBYZEUS
# 1. Update system packages
apt update -y && apt upgrade -y
apt install -y git wget curl build-essential golang iptables
# 2. Open necessary firewall ports
iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
# Forward traffic from public port 53 to internal port 5300 (DNSTT)
iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
# 3. Download and compile DNSTT (SlowDNS server)
cd /usr/local
git clone https://github.com
cd dnstt/dnstt-server
go build
# Move binary to system bin
cp dnstt-server /usr/local/bin/
# 4. Generate Cryptographic Private and Public Keys
cd /etc
mkdir -p slowdns
cd slowdns
dnstt-server -gen-key -privkey server.key -pubkey server.pub
# 5. Create Systemd Startup Service
# Replace '://nameserver.com' with your actual registered Nameserver domain
NS_DOMAIN="://nameserver.com" 
cat <<EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Over SSH Daemon
After=network.target
[Service]
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey /etc/slowdns/server.key -pubkey /etc/slowdns/server.pub ${NS_DOMAIN} 127.0.0.1:22
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
# 6. Enable and Start the SlowDNS Server
systemctl daemon-reload
systemctl enable slowdns
systemctl start slowdns
echo "-------------------------------------------------------"
echo "SlowDNS Setup Complete!"
echo "Your Nameserver (NS): ${NS_DOMAIN}"
echo "Your Public Key contents below (Copy this for your VPN App):"
cat /etc/slowdns/server.pub
echo "-------------------------------------------------------"

