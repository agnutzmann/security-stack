# 📘 Wazuh Single Node

---

## 0️⃣ Pré-requisitos

* Docker e Docker Compose instalados.
* Usuário adicionado ao grupo `docker` para não precisar usar `sudo`:

```bash
sudo usermod -aG docker $USER
# Logout/login ou reiniciar o terminal
docker info
docker compose version
```

---

## 1️⃣ Preparação da stack

```bash
# Navegar para o diretório de stacks
cd ~/stacks

# Criar diretório da stack
mkdir -p wazuh
cd wazuh

# Clonar o repositório oficial do Wazuh Docker
git clone https://github.com/wazuh/wazuh-docker.git -b v4.13.1

# Mover conteúdo do single-node para a pasta da stack
mv wazuh-docker/single-node/* ./

# Limpar repositório original
rm -rf wazuh-docker
```

---

## 2️⃣ Estrutura de diretórios e permissões

```bash
# Persistência completa do /var/ossec
mkdir -p wazuh_data

# Dashboard: configs + custom assets
mkdir -p wazuh_dashboard/config
mkdir -p wazuh_dashboard/custom

# Configs e certificados
mkdir -p config/wazuh_indexer_ssl_certs
mkdir -p config/wazuh_indexer
mkdir -p config/wazuh_cluster
mkdir -p config/wazuh_dashboard

# Ajuste de permissões (UID 1000 = usuário do container Wazuh)
sudo chown -R 1000:1000 wazuh_data
sudo chmod -R 770 wazuh_data

sudo chown -R 1000:1000 wazuh_dashboard
sudo chmod -R 770 wazuh_dashboard
```

---

## 3️⃣ Arquivo `.env`

Crie `~/stacks/wazuh/.env`:

```env
# ========================
# Wazuh Environment Config
# ========================

# Credenciais do Indexer
INDEXER_USERNAME=admin
INDEXER_PASSWORD=SenhaForteIndexer

# API Manager
API_USERNAME=wazuh-wui
API_PASSWORD=SenhaForteAPI

# Dashboard
DASHBOARD_USERNAME=kibanaserver
DASHBOARD_PASSWORD=SenhaForteDashboard

# Java opts do Indexer
INDEXER_JAVA_OPTS=-Xms1g -Xmx1g

# Ports
WAZUH_MANAGER_PORT=55000
WAZUH_INDEXER_PORT=9200
WAZUH_DASHBOARD_PORT=443
```

> Troque as senhas de exemplo por senhas fortes.

---

## 4️⃣ Docker Compose (`docker-compose.yml`)

```yaml
services:
  wazuh.manager:
    image: wazuh/wazuh-manager
    hostname: wazuh.manager
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 655360
        hard: 655360
    ports:
      - "1514:1514"
      - "1515:1515"
      - "514:514/udp"
      - "${WAZUH_MANAGER_PORT}:55000"
    environment:
      - INDEXER_URL=https://wazuh.indexer:${WAZUH_INDEXER_PORT}
      - INDEXER_USERNAME=${INDEXER_USERNAME}
      - INDEXER_PASSWORD=${INDEXER_PASSWORD}
      - FILEBEAT_SSL_VERIFICATION_MODE=full
      - SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/root-ca.pem
      - SSL_CERTIFICATE=/etc/ssl/filebeat.pem
      - SSL_KEY=/etc/ssl/filebeat.key
      - API_USERNAME=${API_USERNAME}
      - API_PASSWORD=${API_PASSWORD}
    volumes:
      - ./wazuh_data:/var/ossec
      - ./config/wazuh_indexer_ssl_certs/root-ca-manager.pem:/etc/ssl/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.manager.pem:/etc/ssl/filebeat.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.manager-key.pem:/etc/ssl/filebeat.key
      - ./config/wazuh_cluster/wazuh_manager.conf:/wazuh-config-mount/etc/ossec.conf

  wazuh.indexer:
    image: wazuh/wazuh-indexer
    hostname: wazuh.indexer
    restart: always
    ports:
      - "${WAZUH_INDEXER_PORT}:9200"
    environment:
      - "OPENSEARCH_JAVA_OPTS=${INDEXER_JAVA_OPTS}"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-indexer/certs/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.indexer-key.pem:/usr/share/wazuh-indexer/certs/wazuh.indexer.key
      - ./config/wazuh_indexer_ssl_certs/wazuh.indexer.pem:/usr/share/wazuh-indexer/certs/wazuh.indexer.pem
      - ./config/wazuh_indexer_ssl_certs/admin.pem:/usr/share/wazuh-indexer/certs/admin.pem
      - ./config/wazuh_indexer_ssl_certs/admin-key.pem:/usr/share/wazuh-indexer/certs/admin-key.pem
      - ./config/wazuh_indexer/wazuh.indexer.yml:/usr/share/wazuh-indexer/opensearch.yml
      - ./config/wazuh_indexer/internal_users.yml:/usr/share/wazuh-indexer/opensearch-security/internal_users.yml

  wazuh.dashboard:
    image: wazuh/wazuh-dashboard
    hostname: wazuh.dashboard
    restart: always
    ports:
      - "${WAZUH_DASHBOARD_PORT}:5601"
    environment:
      - INDEXER_USERNAME=${INDEXER_USERNAME}
      - INDEXER_PASSWORD=${INDEXER_PASSWORD}
      - WAZUH_API_URL=https://wazuh.manager
      - DASHBOARD_USERNAME=${DASHBOARD_USERNAME}
      - DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD}
      - API_USERNAME=${API_USERNAME}
      - API_PASSWORD=${API_PASSWORD}
    volumes:
      - ./config/wazuh_indexer_ssl_certs/wazuh.dashboard.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.dashboard-key.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem
      - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-dashboard/certs/root-ca.pem
      - ./config/wazuh_dashboard/opensearch_dashboards.yml:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml
      - ./config/wazuh_dashboard/wazuh.yml:/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml
      - ./wazuh_dashboard/config:/usr/share/wazuh-dashboard/data/wazuh/config
      - ./wazuh_dashboard/custom:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom
    depends_on:
      - wazuh.indexer
    links:
      - wazuh.indexer:wazuh.indexer
      - wazuh.manager:wazuh.manager
```

---

## 5️⃣ Ajuste do Kernel (OpenSearch)

```bash
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## 6️⃣ Inicialização da stack

```bash
# Gerar certificados internos
docker compose -f generate-indexer-certs.yml run --rm generator

# Subir todos os serviços
docker compose up -d
```

---

## 7️⃣ Configuração do Firewall (ufw)

```bash
sudo ufw enable

# SSH
sudo ufw allow 22/tcp

# Wazuh Manager
sudo ufw allow 1514/tcp
sudo ufw allow 1514/udp
sudo ufw allow 1515/tcp
sudo ufw allow 514/udp
sudo ufw allow ${WAZUH_MANAGER_PORT}/tcp

# Wazuh Indexer (se necessário)
sudo ufw allow ${WAZUH_INDEXER_PORT}/tcp

# Dashboard
sudo ufw allow ${WAZUH_DASHBOARD_PORT}/tcp

# Verificar status
sudo ufw status verbose
```

> 🔒 Dica: restrinja acesso externo a 9200 (Indexer) e 55000 (Manager API) apenas a IPs confiáveis.

---

## 8️⃣ Verificação

```bash
# Status dos containers
docker compose ps

# Logs do Manager
tail -f wazuh_data/logs/ossec.log

# Dashboard (acesso web)
https://<IP_DA_VM_DOCKER>
```

---

## 9️⃣ Manutenção

* Todas as configs, decoders, rules e scripts customizados estão em `wazuh_data`.
* Dashboard configs: `wazuh_dashboard/config`
* Dashboard custom assets: `wazuh_dashboard/custom`

```bash
# Reiniciar o Manager após alterações
docker compose restart wazuh.manager
```

---

## 🔟 Backup

```bash
cat > backup_wazuh.sh <<'EOS'
#!/bin/bash
DATE=$(date +%F)
tar czf ~/stacks/wazuh/backups/wazuh-backup-$DATE.tgz ~/stacks/wazuh/wazuh_data ~/stacks/wazuh/wazuh_dashboard
EOS
chmod +x backup_wazuh.sh
(crontab -l 2>/dev/null; echo "0 2 * * * ~/stacks/wazuh/backup_wazuh.sh") | crontab -
```

---

## 11️⃣ Estrutura final da stack

```
stacks/wazuh/
├── docker-compose.yml
├── .env
├── config/
│   ├── wazuh_indexer_ssl_certs/
│   ├── wazuh_indexer/
│   ├── wazuh_cluster/
│   └── wazuh_dashboard/
├── wazuh_data/            
└── wazuh_dashboard/
    ├── config/              
    └── custom/             
```

---

# **versão totalmente automatizada**:

1. Gera **senhas aleatórias seguras** para Indexer, API e Dashboard.
2. Cria **diretórios com permissões corretas**.
3. Cria `.env` com as senhas já preenchidas.
4. Cria `docker-compose.yml` pronto.
5. Ajusta kernel (`vm.max_map_count`).
6. Gera certificados internos.
7. Sobe os containers.
8. Configura **firewall**.
9. Configura **backup automático diário** para `wazuh_data` e dashboard.

Segue o script completo:

```bash
#!/bin/bash

# ================================
# Script Wazuh Single Node Automático
# ================================

set -e

STACK_DIR=~/stacks/wazuh

# Função para gerar senha aleatória
gen_pass() {
  openssl rand -base64 16
}

# Gerar senhas
INDEXER_PASS=$(gen_pass)
API_PASS=$(gen_pass)
DASHBOARD_PASS=$(gen_pass)

echo "[1/14] Criando diretórios da stack..."
mkdir -p $STACK_DIR
cd $STACK_DIR
mkdir -p wazuh_data wazuh_dashboard/config wazuh_dashboard/custom
mkdir -p config/wazuh_indexer_ssl_certs config/wazuh_indexer config/wazuh_cluster config/wazuh_dashboard

echo "[2/14] Ajustando permissões (UID 1000)..."
sudo chown -R 1000:1000 wazuh_data wazuh_dashboard
sudo chmod -R 770 wazuh_data wazuh_dashboard

echo "[3/14] Clonando repositório oficial do Wazuh Docker..."
git clone https://github.com/wazuh/wazuh-docker.git -b v4.13.1
mv wazuh-docker/single-node/* ./
rm -rf wazuh-docker

echo "[4/14] Criando arquivo .env com senhas aleatórias..."
cat > .env <<EOL
# ========================
# Wazuh Environment Config
# ========================

INDEXER_USERNAME=admin
INDEXER_PASSWORD=${INDEXER_PASS}

API_USERNAME=wazuh-wui
API_PASSWORD=${API_PASS}

DASHBOARD_USERNAME=kibanaserver
DASHBOARD_PASSWORD=${DASHBOARD_PASS}

INDEXER_JAVA_OPTS=-Xms1g -Xmx1g

WAZUH_MANAGER_PORT=55000
WAZUH_INDEXER_PORT=9200
WAZUH_DASHBOARD_PORT=443
EOL

echo "[5/14] Criando docker-compose.yml..."
cat > docker-compose.yml <<'EOL'
services:
  wazuh.manager:
    image: wazuh/wazuh-manager
    hostname: wazuh.manager
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 655360
        hard: 655360
    ports:
      - "1514:1514"
      - "1515:1515"
      - "514:514/udp"
      - "${WAZUH_MANAGER_PORT}:55000"
    environment:
      - INDEXER_URL=https://wazuh.indexer:${WAZUH_INDEXER_PORT}
      - INDEXER_USERNAME=${INDEXER_USERNAME}
      - INDEXER_PASSWORD=${INDEXER_PASSWORD}
      - FILEBEAT_SSL_VERIFICATION_MODE=full
      - SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/root-ca.pem
      - SSL_CERTIFICATE=/etc/ssl/filebeat.pem
      - SSL_KEY=/etc/ssl/filebeat.key
      - API_USERNAME=${API_USERNAME}
      - API_PASSWORD=${API_PASSWORD}
    volumes:
      - ./wazuh_data:/var/ossec
      - ./config/wazuh_indexer_ssl_certs/root-ca-manager.pem:/etc/ssl/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.manager.pem:/etc/ssl/filebeat.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.manager-key.pem:/etc/ssl/filebeat.key
      - ./config/wazuh_cluster/wazuh_manager.conf:/wazuh-config-mount/etc/ossec.conf

  wazuh.indexer:
    image: wazuh/wazuh-indexer
    hostname: wazuh.indexer
    restart: always
    ports:
      - "${WAZUH_INDEXER_PORT}:9200"
    environment:
      - "OPENSEARCH_JAVA_OPTS=${INDEXER_JAVA_OPTS}"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-indexer/certs/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.indexer-key.pem:/usr/share/wazuh-indexer/certs/wazuh.indexer.key
      - ./config/wazuh_indexer_ssl_certs/wazuh.indexer.pem:/usr/share/wazuh-indexer/certs/wazuh.indexer.pem
      - ./config/wazuh_indexer_ssl_certs/admin.pem:/usr/share/wazuh-indexer/certs/admin.pem
      - ./config/wazuh_indexer_ssl_certs/admin-key.pem:/usr/share/wazuh-indexer/certs/admin-key.pem
      - ./config/wazuh_indexer/wazuh.indexer.yml:/usr/share/wazuh-indexer/opensearch.yml
      - ./config/wazuh_indexer/internal_users.yml:/usr/share/wazuh-indexer/opensearch-security/internal_users.yml

  wazuh.dashboard:
    image: wazuh/wazuh-dashboard
    hostname: wazuh.dashboard
    restart: always
    ports:
      - "${WAZUH_DASHBOARD_PORT}:5601"
    environment:
      - INDEXER_USERNAME=${INDEXER_USERNAME}
      - INDEXER_PASSWORD=${INDEXER_PASSWORD}
      - WAZUH_API_URL=https://wazuh.manager
      - DASHBOARD_USERNAME=${DASHBOARD_USERNAME}
      - DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD}
      - API_USERNAME=${API_USERNAME}
      - API_PASSWORD=${API_PASSWORD}
    volumes:
      - ./config/wazuh_indexer_ssl_certs/wazuh.dashboard.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.dashboard-key.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem
      - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-dashboard/certs/root-ca.pem
      - ./config/wazuh_dashboard/opensearch_dashboards.yml:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml
      - ./config/wazuh_dashboard/wazuh.yml:/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml
      - ./wazuh_dashboard/config:/usr/share/wazuh-dashboard/data/wazuh/config
      - ./wazuh_dashboard/custom:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom
    depends_on:
      - wazuh.indexer
    links:
      - wazuh.indexer:wazuh.indexer
      - wazuh.manager:wazuh.manager
EOL

echo "[6/14] Ajustando kernel (vm.max_map_count)..."
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "[7/14] Gerando certificados internos..."
docker compose -f generate-indexer-certs.yml run --rm generator

echo "[8/14] Inicializando stack..."
docker compose up -d

echo "[9/14] Configurando firewall (UFW)..."
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 1514/tcp
sudo ufw allow 1514/udp
sudo ufw allow 1515/tcp
sudo ufw allow 514/udp
sudo ufw allow ${WAZUH_MANAGER_PORT}/tcp
sudo ufw allow ${WAZUH_INDEXER_PORT}/tcp
sudo ufw allow ${WAZUH_DASHBOARD_PORT}/tcp
sudo ufw status verbose

echo "[10/14] Criando diretório de backups automáticos..."
mkdir -p backups

echo "[11/14] Criando script de backup diário..."
cat > backup_wazuh.sh <<'EOS'
#!/bin/bash
DATE=$(date +%F)
tar czf ~/stacks/wazuh/backups/wazuh-backup-$DATE.tgz ~/stacks/wazuh/wazuh_data ~/stacks/wazuh/wazuh_dashboard
EOS
chmod +x backup_wazuh.sh

echo "[12/14] Agendando cron job diário para backup às 2h..."
(crontab -l 2>/dev/null; echo "0 2 * * * $STACK_DIR/backup_wazuh.sh") | crontab -

echo "[13/14] Exibindo credenciais geradas:"
echo "INDEXER_PASSWORD=$INDEXER_PASS"
echo "API_PASSWORD=$API_PASS"
echo "DASHBOARD_PASSWORD=$DASHBOARD_PASS"

echo "[14/14] Script concluído! Acesse o Dashboard em https://<IP_DA_VM_DOCKER>"
```

---

💡 **Dicas finais:**

* Substitua `<IP_DA_VM_DOCKER>` pelo IP real da VM.
* Todos os dados do Wazuh estão em `wazuh


_data` (`/var/ossec`) e `wazuh_dashboard/config`+`custom`, facilitando manutenção via VS Code.

* Backups diários garantem segurança sem precisar entrar nos containers.



