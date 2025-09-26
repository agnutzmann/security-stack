
## Plano de Implantação do Wazuh

### Topologia e Convenções

| Item | Valor |
| :--- | :--- |
| **VM** | `gnu-security-01` (4 vCPU, 8 GiB RAM) |
| **Usuário SSH/Admin** | `gnu` (membro do grupo `sudo` e `wazuh_stack_rw`) |
| **Usuário Docker/Serviço** | `wazuh` (membro do grupo `docker` e `wazuh_stack_rw`, shell `/usr/sbin/nologin`) |
| **Stack Path** | `/home/wazuh/stacks/wazuh` |
| **FQDN** | `wazuh.home.gnu-it.com` |
| **TLS** | Centralizado no **Traefik (VM Original)** via `File Provider` |

-----

### Fase I: Preparação da VM (`gnu-security-01`)

Esta fase estabelece o ambiente, instala o Docker e configura as permissões de acesso seguro.

#### Pré-checagens

1.  VM (`gnu-security-01`) provisionada com Ubuntu Server (LTS).
2.  Usuário `gnu` criado e com acesso SSH/`sudo`.

#### 1\. Instalação do Docker Engine e Compose

Instale o Docker, o CLI e o *plugin* do Compose V2 (comando `docker compose`).

```bash
# Como o usuário 'gnu'
sudo apt update && sudo apt upgrade -y
# Instalar pacotes de dependência
sudo apt install -y ca-certificates curl gnupg lsb-release

# Adicionar a chave GPG oficial do Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Configurar o repositório Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine, CLI e Compose Plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### 2\. Configuração de Usuários e Permissões

Criação dos usuários e grupos para isolamento de privilégios e acesso remoto via VS Code.

```bash
# 2a. Criar o grupo de compartilhamento e o usuário de serviço 'wazuh'
sudo groupadd wazuh_stack_rw 
sudo useradd -r -s /usr/sbin/nologin -g wazuh wazuh # Grupo principal é 'wazuh'

# 2b. Adicionar permissões aos usuários
sudo usermod -aG docker wazuh                 # 'wazuh' pode rodar docker
sudo usermod -aG wazuh_stack_rw wazuh         # 'wazuh' é membro do grupo de escrita
sudo usermod -aG wazuh_stack_rw gnu           # 'gnu' é membro do grupo de escrita (VS Code)

# 2c. Criar a estrutura de pastas e definir permissões estritas
sudo mkdir -p /home/wazuh/stacks/wazuh
sudo mkdir -p /home/wazuh/stacks/wazuh/{data/indexer,data/manager,config/manager,secrets}

# 2d. Definir propriedade e permissões de grupo
sudo chown -R wazuh:wazuh_stack_rw /home/wazuh
sudo chmod -R 770 /home/wazuh/stacks/wazuh # rwx para owner (wazuh) e grupo (wazuh_stack_rw)
sudo chmod g+s /home/wazuh/stacks/wazuh    # Garante que novos arquivos herdem o grupo

# 2e. Checar o PUID/PGID do usuário wazuh (para o .env)
id wazuh
# Pegue o valor do 'uid' e 'gid' (Ex: PUID=998, PGID=998)
```

#### 3\. Configuração do Firewall (UFW)

Garantir que as portas críticas sejam acessíveis pela LAN (`192.168.2.0/24`).

```bash
# Como o usuário 'gnu'
sudo ufw allow in on eth0 to any port 22 proto tcp comment "SSH Access"
sudo ufw allow in on eth0 to any port 5601 proto tcp from 192.168.2.0/24 comment "Wazuh Dashboard (Traefik access)"
sudo ufw allow in on eth0 to any port 1514 proto tcp comment "Wazuh Agents TCP"
sudo ufw allow in on eth0 to any port 1514 proto udp comment "Wazuh Agents UDP"
sudo ufw allow in on eth0 to any port 55000 proto tcp comment "Wazuh Cluster/Agent Control"
sudo ufw enable
```

-----

### Fase II: Deployment do Wazuh (Execução)

Esta fase é executada com as permissões do usuário **`wazuh`** (usuário de serviço).

#### 1\. Alternar Usuário e Preparar Secrets

```bash
# No terminal do VS Code (logado como gnu)
sudo -i -u wazuh
cd /home/wazuh/stacks/wazuh
```

Criação dos *secrets* e credenciais (certificados/senhas).

**a. Criar o arquivo de configuração para os certificados:** `config.yml`

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

**b. Rodar o *script* de geração de certificados/chaves:**

```bash
docker run --rm -it -v $(pwd)/config.yml:/app/config.yml \
  -v $(pwd)/secrets:/app/output \
  wazuh/wazuh-certs-tool:latest
```

**c. Gerar senhas fortes e criar `.env`:**

```bash
# Gere as senhas e armazene-as de forma segura
export INDEXER_PASSWORD=$(openssl rand -base64 12)
export DASHBOARD_PASSWORD=$(openssl rand -base64 12)

# Crie o .env com os valores estáticos (substitua PUID/PGID pelos valores checados no passo 2e da Fase I)
echo "TZ=America/Toronto" >> .env
echo "PUID=998" >> .env
echo "PGID=998" >> .env
echo "FQDN=wazuh.home.gnu-it.com" >> .env
echo "INDEXER_PASSWORD=$INDEXER_PASSWORD" >> .env
echo "DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD" >> .env
```

#### 2\. Criar Arquivo `docker-compose.yml` (Padrão Sem Versão)

Este arquivo não incluirá *labels* Traefik, expondo a porta `5601` diretamente para o *host*.

```yaml
name: wazuh
services:
  # 1. Wazuh Indexer
  wazuh-indexer:
    image: wazuh/wazuh-indexer:4.7.4
    container_name: wazuh_indexer
    env_file: .env
    hostname: wazuh-indexer
    environment:
      # Configurações internas do Indexer
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
      - ./secrets/certs:/usr/share/wazuh-indexer/certs:ro # Certificados
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
    image: wazuh/wazuh-manager:4.7.4
    container_name: wazuh_manager
    env_file: .env
    hostname: wazuh-manager
    environment:
      # Configurações de conexão com o Indexer
      - WAZUH_INDEXER_URL=wazuh-indexer:9200
      - WAZUH_INDEXER_USERNAME=admin
      - WAZUH_INDEXER_PASSWORD=${INDEXER_PASSWORD}
    volumes:
      - ./data/manager:/var/ossec # Dados do DB, configs, logs
      - ./secrets/certs:/var/ossec/etc/certs:ro
    ports: # Portas de agente e cluster
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
    image: wazuh/wazuh-dashboard:4.7.4
    container_name: wazuh_dashboard
    env_file: .env
    hostname: wazuh-dashboard
    environment:
      - OPENSEARCH_HOSTS=["https://wazuh-indexer:9200"]
      - WAZUH_INDEXER_USERNAME=admin
      - WAZUH_INDEXER_PASSWORD=${INDEXER_PASSWORD}
      - WAZUH_DASHBOARD_SERVER_HOST=0.0.0.0
    volumes:
      - ./secrets/certs:/etc/wazuh-dashboard/certs:ro
    ports: # Porta exposta para o Traefik (VM Original)
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

#### 3\. Executar Implantação e Verificação

```bash
# Como o usuário 'wazuh'
docker compose config # Validação
docker compose up -d

# Verificação (Aguarde o status 'healthy' para Manager e Indexer)
docker compose ps
```

-----

### Fase III: Configuração do Traefik (VM Original)

Esta fase é executada na sua VM de **containers original** (onde o Traefik está ativo) para rotear o tráfego.

#### 1\. Criar Configuração Dinâmica do Traefik

Crie o arquivo `wazuh.yml` no diretório do seu **File Provider** (`/etc/traefik/dynamic/wazuh.yml` ou similar).

```bash
# Como o usuário admin (com sudo) na VM do Traefik
sudo nano /etc/traefik/dynamic/wazuh.yml
```

**Conteúdo de `wazuh.yml`:**

Substitua `<IP_DA_GNU-SECURITY-01>` pelo IP da nova VM.

```yaml
http:
  routers:
    wazuh:
      rule: "Host(`wazuh.home.gnu-it.com`)"
      entrypoints:
        - websecure
      service: wazuh-service
      tls:
        certResolver: cloudflare # Garante TLS via Cloudflare DNS-01

  services:
    wazuh-service:
      loadBalancer:
        servers:
          # Roteia para a porta 5601 exposta diretamente na nova VM
          - url: "http://<IP_DA_GNU-SECURITY-01>:5601" 
```

#### 2\. Migração de Configurações (FIM, SCA, Grupos)

Após o Dashboard estar acessível em `https://wazuh.home.gnu-it.com`, realize a migração.

1.  **Stop do Manager:** `sudo -i -u wazuh docker compose stop wazuh-manager` na nova VM.
2.  **Cópia de Arquivos:** Copie o conteúdo do `ossec.conf` antigo e de regras customizadas (`local_rules.xml`) para o novo volume persistente:
      - `.../data/manager/etc/ossec.conf`
      - `.../data/manager/etc/rules/local_rules.xml`
3.  **Start do Manager:** `sudo -i -u wazuh docker compose up -d wazuh-manager`.
4.  **Configuração de Grupos:** Use o Dashboard para criar grupos de agentes (`linux-servers`, `windows-endpoints`) e configurar os arquivos `agent.conf` específicos dentro do volume: `.../data/manager/etc/groups/<nome_do_grupo>/agent.conf`.

-----

**Rollback:** Em caso de falha no *deployment* (Fase II), basta usar:

```bash
sudo -i -u wazuh
cd /home/wazuh/stacks/wazuh
docker compose down -v # Remove containers e volumes (CUIDADO: volumes/dados serão perdidos se não houver backup)
```

Podemos prosseguir com a **execução dos comandos da Fase I** na sua nova VM (`gnu-security-01`), começando pela instalação do Docker?