# Instalar Wazuh nos LXC:

```xml
su
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
apt-get update
apt-get install -y wget lsb-release
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.12.0-1_amd64.deb
WAZUH_MANAGER='192.168.2.251' dpkg -i ./wazuh-agent_4.12.0-1_amd64.deb
apt-get install -f
```

Edite o arquivo de configuração e substitua 'MANAGER_IP'

```xml
nano /var/ossec/etc/ossec.conf
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
ystemctl status wazuh-agent
```