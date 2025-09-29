#!/usr/bin/env bash
#
# Script Definitivo (v11) para Instalação Limpa e Robusta do Wazuh Docker
# - Inclui verificação de pré-requisitos inteligente e informativa.

set -euo pipefail

# --- CONFIGURAÇÕES GERAIS ---
WAZUH_VERSION="4.13.1"
STACK_DIR="$HOME/stacks/wazuh"
REPO_URL="https://github.com/wazuh/wazuh-docker.git"

# --- CORES E FUNÇÕES AUXILIARES ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m';
log_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[WARNING]${C_RESET} $1"; }
# Modificado para permitir múltiplas linhas no log_error
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

# MELHORIA: Função de verificação de pré-requisitos inteligente
check_command() {
    local cmd="$1"
    # Retorna 0 (sucesso) se o comando já existe
    command -v "$cmd" &>/dev/null && return 0

    log_warn "Comando '$cmd' não encontrado."

    # Tenta detectar a distribuição do SO
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        ID=${ID:-unknown}
    else
        ID="unknown"
    fi

    local install_instruction=""
    local pkg_name="$cmd"

    # Mapeia comandos para os nomes dos pacotes corretos
    case "$cmd" in
        python3) pkg_name="python3 python3-pip python3-venv" ;;
        pip) pkg_name="python3-pip" ;;
        shuf) pkg_name="coreutils" ;; # Geralmente já vem instalado
    esac

    # Gera a instrução de instalação para a distro detectada
    case $ID in
        ubuntu|debian)
            install_instruction="sudo apt update && sudo apt install -y $pkg_name"
            ;;
        fedora|centos|rhel)
            # Para Docker, o pacote geralmente é docker-ce
            if [ "$cmd" == "docker" ]; then pkg_name="docker-ce"; fi
            install_instruction="sudo dnf install -y $pkg_name"
            ;;
        *)
            install_instruction="Por favor, use o gerenciador de pacotes da sua distribuição para instalar '$pkg_name'."
            ;;
    esac

    log_error "Instalação de pré-requisito necessária. Por favor, execute o seguinte comando e rode o script novamente:\n\n  ${install_instruction}\n"
}

gen_pass() {
    local pass_length=20; local upper=$(tr -dc 'A-Z' < /dev/urandom | head -c 1)
    local lower=$(tr -dc 'a-z' < /dev/urandom | head -c 1); local digit=$(tr -dc '0-9' < /dev/urandom | head -c 1)
    local special=$(tr -dc '@#$%&*' < /dev/urandom | head -c 1); local rest=$(tr -dc 'A-Za-z0-9@#$%&*' < /dev/urandom | head -c $((pass_length - 4)))
    local combined="${upper}${lower}${digit}${special}${rest}"; echo "$combined" | fold -w1 | shuf | tr -d '\n'
}

# --- FLUXO PRINCIPAL ---
# PASSO 1: Pré-requisitos e compatibilidade do Docker Compose
log_info "Verificando pré-requisitos..."
for cmd in docker git python3 pip shuf sed rsync; do check_command "$cmd"; done
if ! groups "$USER" | grep -q '\bdocker\b'; then
    log_error "Usuário $USER não pertence ao grupo 'docker'. Execute 'sudo usermod -aG docker $USER', faça logout/login e rode novamente."
fi
if docker compose version &>/dev/null; then DC="docker compose";
elif docker-compose version &>/dev/null; then DC="docker-compose";
else log_error "Nenhuma versão do Docker Compose foi encontrada."; fi
log_success "Pré-requisitos atendidos (usando '$DC')."

# PASSO 2: Preparar diretório e clonagem temporária
log_info "Preparando o diretório da stack em ${STACK_DIR}..."
mkdir -p "$STACK_DIR"; TEMP_DIR=$(mktemp -d)
log_info "Clonando repositório Wazuh Docker (v$WAZUH_VERSION)..."
git -c advice.detachedHead=false clone --depth 1 --branch "v$WAZUH_VERSION" "$REPO_URL" "$TEMP_DIR" > /dev/null
log_info "Copiando apenas os arquivos essenciais para a stack..."
rsync -a "${TEMP_DIR}/single-node/" "$STACK_DIR/"; rm -rf "$TEMP_DIR"; cd "$STACK_DIR"
log_success "Estrutura da stack limpa criada em $(pwd)"

# PASSO 3: Gerar senhas e criar .env
log_info "Gerando senhas e criando arquivo .env..."
ADMIN_PASS=$(gen_pass); API_PASS=$(gen_pass); DASHBOARD_PASS=$(gen_pass)
cat > .env <<EOL
# Wazuh Version
WAZUH_VERSION=${WAZUH_VERSION}
# Portas customizáveis
WAZUH_DASHBOARD_PORT=443
# Senhas
INDEXER_PASSWORD='${ADMIN_PASS}'
API_PASSWORD='${API_PASS}'
DASHBOARD_PASSWORD='${DASHBOARD_PASS}'
EOL
chmod 600 .env; log_success "Arquivo .env criado."

# PASSO 4: Adaptar docker-compose.yml
log_info "Adaptando o docker-compose.yml..."
sed -i -e "s|INDEXER_PASSWORD=SecretPassword|INDEXER_PASSWORD=\${INDEXER_PASSWORD}|g" \
    -e "s|API_PASSWORD=MyS3cr37P450r.\*-|API_PASSWORD=\${API_PASSWORD}|g" \
    -e "s|DASHBOARD_PASSWORD=kibanaserver|DASHBOARD_PASSWORD=\${DASHBOARD_PASSWORD}|g" \
    -e "s|\"443:5601\"|\"\${WAZUH_DASHBOARD_PORT}:5601\"|g" \
    docker-compose.yml
log_success "docker-compose.yml adaptado."

# PASSO 5: Gerar certificados e corrigir permissões
log_info "Gerando certificados internos..."
$DC -f generate-indexer-certs.yml down -v 2>/dev/null || true
$DC -f generate-indexer-certs.yml run --rm generator
log_success "Certificados gerados."
log_info "Corrigindo dono e permissões dos arquivos..."
sudo chown -R "$USER":"$USER" ./config
find ./config -type d -exec chmod 700 {} \;
find ./config -type f -exec chmod 600 {} \;
log_success "Dono e permissões corrigidos."

# PASSO 6: Injetar hashes de senha
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

# PASSO 7: Configurar Host e Iniciar Stack
log_info "Ajustando vm.max_map_count de forma permanente..."
if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf > /dev/null
fi
sudo sysctl -p > /dev/null; log_success "Configuração do kernel aplicada."
log_info "Iniciando a stack Wazuh..."; $DC down -v --remove-orphans 2>/dev/null || true
$DC up -d; log_success "Comando de inicialização enviado."

# PASSO 8: Criar Scripts de Manutenção
log_info "Criando scripts de manutenção..."; cat > backup.sh <<'EOS'
#!/usr/bin/env bash
set -euo pipefail; DATE=$(date +%Y-%m-%d_%H-%M); STACK_DIR="$(cd "$(dirname "$0")" && pwd)"; BACKUP_DIR="${STACK_DIR}/backups"; mkdir -p "$BACKUP_DIR"
CONFIG_BACKUP_FILE="${BACKUP_DIR}/wazuh-config-backup-${DATE}.tgz"; VOLUMES_BACKUP_FILE="${BACKUP_DIR}/wazuh-volumes-backup-${DATE}.tgz"
echo "[INFO] Backup dos arquivos de configuração..."; tar -czf "${CONFIG_BACKUP_FILE}" -C "${STACK_DIR}" .env docker-compose.yml config *.sh
if docker compose version &>/dev/null; then DC="docker compose"; else DC="docker-compose"; fi
PROJECT_NAME=$($DC ps --format '{{.Name}}' | head -n1 | cut -d- -f1)
VOLUMES_TO_BACKUP=( $(docker volume ls --format '{{.Name}}' | grep "^${PROJECT_NAME}_" || true) )
if [ ${#VOLUMES_TO_BACKUP[@]} -eq 0 ]; then echo "[WARN] Nenhum volume Docker encontrado para backup."; exit 0; fi
echo "[INFO] Backup de ${#VOLUMES_TO_BACKUP[@]} volumes de dados..."; docker run --rm -v "${BACKUP_DIR}:/backup" $(for volume in "${VOLUMES_TO_BACKUP[@]}"; do echo "-v ${volume}:/data/${volume}:ro"; done) alpine tar czf "/backup/$(basename ${VOLUMES_BACKUP_FILE})" -C /data .
echo "[SUCCESS] Backup concluído!"
EOS
cat > restore.sh <<'EOS'
#!/usr/bin/env bash
set -euo pipefail; STACK_DIR="$(cd "$(dirname "$0")" && pwd)"; BACKUP_DIR="${STACK_DIR}/backups"
read -p "ATENÇÃO: Este script irá parar os containers e sobrescrever os dados atuais. Continuar? (s/n): " confirm && [[ "$confirm" == "s" ]] || exit 0
LATEST_VOL_BACKUP=$(ls -t "${BACKUP_DIR}"/wazuh-volumes-backup-*.tgz 2>/dev/null | head -n 1)
if [ -z "$LATEST_VOL_BACKUP" ]; then echo "[ERROR] Nenhum backup de volumes encontrado em ${BACKUP_DIR}."; exit 1; fi
echo "[INFO] Usando o backup de volumes mais recente: $LATEST_VOL_BACKUP"
if docker compose version &>/dev/null; then DC="docker compose"; else DC="docker-compose"; fi
echo "[INFO] Parando os serviços..."; $DC down
PROJECT_NAME=$($DC ps --format '{{.Name}}' | head -n1 | cut -d- -f1)
VOLUMES_TO_RESTORE=( $(docker volume ls --format '{{.Name}}' | grep "^${PROJECT_NAME}_" || true) )
echo "[INFO] Restaurando ${#VOLUMES_TO_RESTORE[@]} volumes..."; docker run --rm -v "${LATEST_VOL_BACKUP}:/backup.tgz:ro" $(for volume in "${VOLUMES_TO_RESTORE[@]}"; do echo "-v ${volume}:/data/${volume}"; done) alpine sh -c "cd /data && tar xzf /backup.tgz --strip-components=1"
echo "[INFO] Iniciando os serviços..."; $DC up -d
echo "[SUCCESS] Restauração concluída!"
EOS
chmod +x backup.sh restore.sh; log_success "Scripts backup.sh e restore.sh criados."

# PASSO 9: Verificação final e Mensagem
log_info "Aguardando a inicialização dos containers para verificação (até 60s)..."
for i in {1..12}; do
    PROJECT_NAME=$($DC ps --format '{{.Name}}' | head -n1 | cut -d- -f1)
    RUNNING_CONTAINERS=$($DC ps --status running | grep "${PROJECT_NAME}" | wc -l)
    if [ "$RUNNING_CONTAINERS" -eq 3 ]; then
        log_success "Todos os 3 containers estão no ar!"
        break
    fi
    sleep 5
done
if [ "$RUNNING_CONTAINERS" -ne 3 ]; then
    log_warn "Nem todos os containers subiram corretamente. Verifique os logs com: $DC logs"
fi

log_info "Exibindo logs iniciais do Indexer para validação..."
$DC logs --tail=20 wazuh.indexer

source .env; ip_host=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
echo; log_success "--------------------------------------------------------"
log_success " INSTALAÇÃO DO WAZUH CONCLUÍDA!"; log_success "--------------------------------------------------------"; echo
log_info "Status final dos containers:"; $DC ps; echo
log_info "Acesse o Dashboard Wazuh em: https://${ip_host}:${WAZUH_DASHBOARD_PORT}"
log_info "Usuário para login: admin"; log_info "Senha gerada: ${ADMIN_PASS}"; echo
log_warn "Guarde esta senha em um local seguro!"
log_info "Manutenção: ./backup.sh | ./restore.sh | ./upgrade.sh (upgrade.sh precisa ser criado)"