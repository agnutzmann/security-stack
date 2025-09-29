#!/usr/bin/env bash
#
# Script Definitivo (v15 - já foram mais de 40 na vdd :P)

set -euo pipefail

# --- CONFIGURAÇÕES GERAIS ---
WAZUH_VERSION="4.13.1"; STACK_DIR="$HOME/stacks/wazuh"; REPO_URL="https://github.com/wazuh/wazuh-docker.git"

# --- CORES E FUNÇÕES AUXILIARES ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m';
log_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }; log_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[WARNING]${C_RESET} $1"; }; log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

check_command() {
    local cmd="$1"; command -v "$cmd" &>/dev/null && return 0; log_warn "Comando '$cmd' não encontrado."
    if [ -f /etc/os-release ]; then source /etc/os-release; ID=${ID:-unknown}; else ID="unknown"; fi
    local install_instruction=""; local pkg_name="$cmd"
    case "$cmd" in python3) pkg_name="python3 python3-pip python3-venv" ;; pip) pkg_name="python3-pip" ;; shuf) pkg_name="coreutils" ;; esac
    case $ID in ubuntu|debian) install_instruction="sudo apt update && sudo apt install -y $pkg_name";; fedora|centos|rhel) if [ "$cmd" == "docker" ]; then pkg_name="docker-ce"; fi; install_instruction="sudo dnf install -y $pkg_name";; *) install_instruction="Por favor, use o gerenciador de pacotes da sua distribuição para instalar '$pkg_name'.";; esac
    log_error "Instalação de pré-requisito necessária. Por favor, execute:\n\n  ${install_instruction}\n"
}

gen_pass() {
    local pass_length=20; local upper=$(tr -dc 'A-Z' < /dev/urandom | head -c 1)
    local lower=$(tr -dc 'a-z' < /dev/urandom | head -c 1); local digit=$(tr -dc '0-9' < /dev/urandom | head -c 1)
    local special=$(tr -dc '@#$%&*' < /dev/urandom | head -c 1); local rest=$(tr -dc 'A-Za-z0-9@#$%&*' < /dev/urandom | head -c $((pass_length - 4)))
    local combined="${upper}${lower}${digit}${special}${rest}"; echo "$combined" | fold -w1 | shuf | tr -d '\n'
}

# --- FLUXO PRINCIPAL ---
log_info "Verificando pré-requisitos..."; for cmd in docker git python3 pip shuf sed rsync; do check_command "$cmd"; done
if ! groups "$USER" | grep -q '\bdocker\b'; then log_error "Usuário $USER não pertence ao grupo 'docker'. Execute 'sudo usermod -aG docker $USER', faça logout/login e rode novamente."; fi
if docker compose version &>/dev/null; then DC="docker compose"; elif docker-compose version &>/dev/null; then DC="docker-compose"; else log_error "Nenhuma versão do Docker Compose foi encontrada."; fi
log_success "Pré-requisitos atendidos (usando '$DC')."

log_info "Preparando o diretório da stack em ${STACK_DIR}..."; mkdir -p "$STACK_DIR"; TEMP_DIR=$(mktemp -d)
log_info "Clonando repositório Wazuh Docker (v$WAZUH_VERSION)..."
git -c advice.detachedHead=false clone --depth 1 --branch "v$WAZUH_VERSION" "$REPO_URL" "$TEMP_DIR" > /dev/null
log_info "Copiando apenas os arquivos essenciais para a stack..."; rsync -a "${TEMP_DIR}/single-node/" "$STACK_DIR/"; rm -rf "$TEMP_DIR"; cd "$STACK_DIR"
log_success "Estrutura da stack limpa criada em $(pwd)"

log_info "Gerando senhas e criando arquivo .env..."; ADMIN_PASS=$(gen_pass); DASHBOARD_PASS=$(gen_pass)
# CORREÇÃO FINAL: A senha da API não é mais gerada, usamos a senha padrão do Wazuh.
cat > .env <<EOL
WAZUH_VERSION=${WAZUH_VERSION}
WAZUH_DASHBOARD_PORT=443
INDEXER_PASSWORD='${ADMIN_PASS}'
API_PASSWORD='MyS3cr37P450r.*-'
DASHBOARD_PASSWORD='${DASHBOARD_PASS}'
EOL
chmod 600 .env; log_success "Arquivo .env criado."

log_info "Adaptando o docker-compose.yml..."; cp docker-compose.yml docker-compose.yml.orig
sed -i -e "s|INDEXER_PASSWORD=SecretPassword|INDEXER_PASSWORD=\${INDEXER_PASSWORD}|g" \
    -e "s|DASHBOARD_PASSWORD=kibanaserver|DASHBOARD_PASSWORD=\${DASHBOARD_PASSWORD}|g" \
    -e "s|\"443:5601\"|\"\${WAZUH_DASHBOARD_PORT}:5601\"|g" \
    docker-compose.yml
# Não precisamos mais substituir a API_PASSWORD, pois já estamos usando o valor padrão.
sed -i '/hostname: wazuh.indexer/a \
    healthcheck:\n\
      test: ["CMD-SHELL", "curl -k -u admin:\${INDEXER_PASSWORD} https://localhost:9200/_cluster/health?wait_for_status=yellow\&timeout=5s"]\n\
      interval: 10s\n\
      timeout: 5s\n\
      retries: 20' docker-compose.yml
sed -i '/hostname: wazuh.manager/a \
    healthcheck:\n\
      test: ["CMD-SHELL", "curl -k -u wazuh-wui:\${API_PASSWORD} https://localhost:55000/manager/info"]\n\
      interval: 10s\n\
      timeout: 5s\n\
      retries: 20' docker-compose.yml
sed -i '/depends_on:/a \
      wazuh.indexer:\n\
        condition: service_healthy\n\
      wazuh.manager:\n\
        condition: service_healthy' docker-compose.yml
sed -i '/- wazuh.indexer/d' docker-compose.yml
log_success "docker-compose.yml adaptado."

log_info "Gerando certificados internos..."; $DC -f generate-indexer-certs.yml down -v 2>/dev/null || true
$DC -f generate-indexer-certs.yml run --rm generator
log_success "Certificados gerados."; log_info "Corrigindo dono e permissões dos arquivos..."
sudo chown -R "$USER":"$USER" ./config; find ./config -type d -exec chmod 700 {} \;; find ./config -type f -exec chmod 600 {} \;
log_success "Dono e permissões corrigidos."

log_info "Atualizando hashes de senha em 'internal_users.yml'..."
venv_dir=".py_venv"; python3 -m venv "$venv_dir"; source "$venv_dir/bin/activate"
pip install --quiet "passlib==1.7.4" "bcrypt==3.2.2"
internal_users_file="./config/wazuh_indexer/internal_users.yml"
hash_admin=$(python3 -c "from passlib.hash import bcrypt; print(bcrypt.hash('$ADMIN_PASS'))")
hash_kibanaserver=$(python3 -c "from passlib.hash import bcrypt; print(bcrypt.hash('$DASHBOARD_PASS'))")
escaped_hash_admin=$(printf '%s\n' "$hash_admin" | sed 's:[][\\/.^$*]:\\&:g')
escaped_hash_kibanaserver=$(printf '%s\n' "$hash_kibanaserver" | sed 's:[][\\/.^$*]:\\&:g')
sed -i "/^admin:/,/^[^ ]/ s|^\(\s*hash:\s*\).*|\1\"$escaped_hash_admin\"|" "$internal_users_file"
sed -i "/^kibanaserver:/,/^[^ ]/ s|^\(\s*hash:\s*\).*|\1\"$escaped_hash_kibanaserver\"|" "$internal_users_file"
deactivate; rm -rf "$venv_dir"; log_success "Hashes de senha sincronizados."

log_info "Ajustando vm.max_map_count de forma permanente..."
if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf; then echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf > /dev/null; fi
sudo sysctl -p > /dev/null; log_success "Configuração do kernel aplicada."
log_info "Iniciando a stack Wazuh (pode levar alguns minutos para os health checks passarem)..."
$DC down -v --remove-orphans 2>/dev/null || true
$DC up -d; log_success "Comando de inicialização enviado."

log_info "Aguardando o Dashboard ficar pronto (timeout de 5 minutos)..."
HEALTHY=false; for i in {1..30}; do if $DC logs wazuh.dashboard 2>/dev/null | grep -q "Server running at"; then log_success "Dashboard está no ar!"; HEALTHY=true; break; fi; echo -n "."; sleep 10; done; echo
if [ "$HEALTHY" = "false" ]; then log_error "O Dashboard não iniciou a tempo. Verifique os logs com: $DC logs wazuh.dashboard"; fi

source .env; ip_host=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
echo; log_success "--------------------------------------------------------"
log_success " INSTALAÇÃO DO WAZUH CONCLUÍDA!"; log_success "--------------------------------------------------------"; echo
log_info "Status final dos containers:"; $DC ps; echo
log_info "Acesse o Dashboard Wazuh em: https://${ip_host}:${WAZUH_DASHBOARD_PORT}"
log_info "Usuário para login: admin"; log_info "Senha gerada: ${ADMIN_PASS}"; echo
log_warn "Guarde esta senha em um local seguro!"