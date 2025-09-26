## Fase I: Preparação da VM (`gnu-security-01`)

### 1\. Instalação do Docker Engine e Compose

Execute estes comandos na sua nova VM (`gnu-security-01`), logado como o usuário administrativo (`gnu`).

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

### 2\. Configuração de Usuários e Permissões

Agora, configuraremos o usuário de serviço **`wazuh`** e as permissões de acesso compartilhado para o usuário **`gnu`**.

```bash
# 2a. Criar o grupo de escrita compartilhada e o usuário de serviço 'wazuh'
sudo groupadd wazuh_stack_rw 
sudo useradd -r -s /usr/sbin/nologin -g wazuh wazuh # Cria user e grupo 'wazuh'

# 2b. Adicionar permissões de grupo
sudo usermod -aG docker wazuh                 # 'wazuh' pode rodar docker
sudo usermod -aG wazuh_stack_rw wazuh         # 'wazuh' é membro do grupo de escrita
sudo usermod -aG wazuh_stack_rw gnu           # 'gnu' é membro do grupo de escrita (VS Code)

# 2c. Criar a estrutura de pastas e volumes
sudo mkdir -p /home/wazuh/stacks/wazuh
sudo mkdir -p /home/wazuh/stacks/wazuh/{data/indexer,data/manager,config/manager,secrets}

# 2d. Definir propriedade e permissões estritas para o grupo compartilhado
sudo chown -R wazuh:wazuh_stack_rw /home/wazuh
sudo chmod -R 770 /home/wazuh/stacks/wazuh
sudo chmod g+s /home/wazuh/stacks/wazuh    # Habilita SGID para herança de grupo

# 2e. Checar PUID/PGID do usuário wazuh (Anote esses IDs para o .env)
id wazuh
```

> **VERIFICAÇÃO:** Anote o **`uid`** e **`gid`** do usuário `wazuh` (geralmente é o mesmo ID, ex: `PUID=998`, `PGID=998`).

### 3\. Configuração do Firewall (UFW)

Garanta que o firewall libere as portas necessárias. Substitua **`eth0`** pela interface de rede correta da VM, se necessário.

```bash
# Como o usuário 'gnu'
sudo ufw allow in on eth0 to any port 22 proto tcp comment "SSH Access"
sudo ufw allow in on eth0 to any port 5601 proto tcp from 192.168.2.0/24 comment "Wazuh Dashboard (Traefik access)"
sudo ufw allow in on eth0 to any port 1514 proto tcp comment "Wazuh Agents TCP"
sudo ufw allow in on eth0 to any port 1514 proto udp comment "Wazuh Agents UDP"
sudo ufw allow in on eth0 to any port 55000 proto tcp comment "Wazuh Cluster/Agent Control"
sudo ufw enable
sudo ufw status verbose
```

