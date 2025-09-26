## Fase II: Deployment do Wazuh 4.13.1 (Execução)

Esta fase será executada como o usuário de serviço **`wazuh`**, que tem as permissões de Docker e acesso de escrita à pasta da *stack*.

### 1\. Alternar Usuário e Preparar Secrets

Entre no diretório da *stack* alternando para o usuário `wazuh`.

```bash
# No terminal do VS Code (logado como gnu)
sudo -i -u wazuh
cd /home/wazuh/stacks/wazuh
```

#### a. Criar o arquivo de configuração para os certificados: `config.yml`

Use seu editor (via VS Code ou `nano` no terminal) para criar o arquivo `config.yml` no diretório atual:

```bash
nano config.yml
```

**Conteúdo de `config.yml`:**

```yaml
nodes:
  - name: wazuh-manager
    ip: []
    roles:
      - master
  - name: wazuh-indexer
    ip: []
    roles:
      - master
      - data
      - ingest
  - name: wazuh-dashboard
    ip: []
    roles:
      - dashboard
```

#### b. Rodar o script de geração de certificados/chaves

Execute o *container* temporário para gerar os certificados internos de comunicação segura entre os componentes.

```bash
# Certifique-se de estar como o usuário 'wazuh'
docker run --rm -it -v $(pwd)/config.yml:/app/config.yml \
  -v $(pwd)/secrets:/app/output \
  wazuh/wazuh-certs-tool:latest
```

#### c. Gerar senhas fortes e criar `.env`

Gere senhas fortes para o Indexer e Dashboard e crie o arquivo `.env`, usando seus PUID/PGID e o FQDN.

```bash
# Gere as senhas e armazene-as de forma segura
export INDEXER_PASSWORD=$(openssl rand -base64 24)
export DASHBOARD_PASSWORD=$(openssl rand -base64 24)

# Crie o .env com os valores estáticos e os IDs corretos
echo "TZ=America/Toronto" >> .env
echo "PUID=999" >> .env
echo "PGID=987" >> .env
echo "FQDN=wazuh.home.gnu-it.com" >> .env
echo "INDEXER_PASSWORD=$INDEXER_PASSWORD" >> .env
echo "DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD" >> .env
```

> **NOTA:** Substitua as variáveis de ambiente com os valores estáticos gerados antes de rodar `docker compose`.

-----

### 2\. Criar Arquivo `docker-compose.yml`

Crie o arquivo `docker-compose.yml` no mesmo diretório.

```bash
nano docker-compose.yml
```

**Conteúdo de `docker-compose.yml` (Versão 4.13.1):**

```yaml
name: wazuh
services:
  # 1. Wazuh Indexer
  wazuh-indexer:
    image: wazuh/wazuh-indexer:4.13.1
    container_name: wazuh_indexer
    env_file: .env
    user: "${PUID}:${PGID}" # Executa com seu PUID/PGID
    hostname: wazuh-indexer
    security_opt:
      - no-new-privileges:true
    cap_drop: [ "ALL" ]
    environment:
      - WAZUH_INDEXER_NODE_NAME=wazuh-indexer
      - WAZUH_INDEXER_HOST=0.0.0.0
      - WAZUH_SECURITY_ADMIN_USERNAME=admin
      - WAZUH_SECURITY_ADMIN_PASSWORD=${INDEXER_PASSWORD}
      - WAZUH_TLS_CERTIFICATES_PATH=/usr/share/wazuh-indexer/certs
      - OPENSEARCH_JAVA_OPTS=-Xms4g -Xmx4g
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - ./data/indexer:/usr/share/wazuh-indexer/data # Persistência
      - ./secrets/certs:/usr/share/wazuh-indexer/certs:ro # Certificados (read-only)
    restart: unless-stopped
    networks:
      - wazuh_net
    healthcheck:
      test: ["CMD-SHELL", "curl -s -k --user admin:${INDEXER_PASSWORD} https://127.0.0.1:9200/_cluster/health | grep -q 'cluster_name' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  # 2. Wazuh Manager
  wazuh-manager:
    image: wazuh/wazuh-manager:4.13.1
    container_name: wazuh_manager
    env_file: .env
    hostname: wazuh-manager
    user: "${PUID}:${PGID}"
    security_opt:
      - no-new-privileges:true
    cap_drop: [ "ALL" ]
    environment:
      - WAZUH_INDEXER_URL=wazuh-indexer:9200
      - WAZUH_INDEXER_USERNAME=admin
      - WAZUH_INDEXER_PASSWORD=${INDEXER_PASSWORD}
    volumes:
      - ./data/manager:/var/ossec # Dados do DB, configs, logs
      - ./secrets/certs:/var/ossec/etc/certs:ro
    ports: 
      - "1514:1514/tcp"
      - "1514:1514/udp"
      - "55000:55000/tcp"
    restart: unless-stopped
    networks:
      - wazuh_net
    depends_on:
      wazuh-indexer:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:55000/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  # 3. Wazuh Dashboard
  wazuh-dashboard:
    image: wazuh/wazuh-dashboard:4.13.1
    container_name: wazuh_dashboard
    env_file: .env
    hostname: wazuh-dashboard
    security_opt:
      - no-new-privileges:true
    cap_drop: [ "ALL" ]
    environment:
      - OPENSEARCH_HOSTS=["https://wazuh-indexer:9200"]
      - WAZUH_INDEXER_USERNAME=admin
      - WAZUH_INDEXER_PASSWORD=${INDEXER_PASSWORD}
      - WAZUH_DASHBOARD_SERVER_HOST=0.0.0.0
    volumes:
      - ./secrets/certs:/etc/wazuh-dashboard/certs:ro
    ports:
      - "5601:5601/tcp"
    restart: unless-stopped
    networks:
      - wazuh_net
    depends_on:
      wazuh-manager:
        condition: service_healthy

networks:
  wazuh_net:
    driver: bridge
```

-----

### 3\. Executar Implantação e Verificação

Execute o *deployment* e monitore o *status*.

```bash
# Como o usuário 'wazuh' em /home/wazuh/stacks/wazuh
docker compose config # Validação sintática
docker compose up -d

# Verifique o status. Aguarde o status 'healthy'
docker compose ps
docker logs wazuh_dashboard -f
```
