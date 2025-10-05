#!/usr/bin/env bash
#
# Script for Stable Wazuh Docker Installation
#
# Author: Alexandre Gnutzmann with help from goofy AIs that only cause trouble with so many errors.
# Date: 2025-09-29
# Version: 1.0
# 
# Backup and update scripts have not been tested yet. Use at your own risk.
# Known vulnerabilities: hardcoded-credentials (to maintain compatibility with the original repository) and clear-text-logging
# Protect your Docker environment properly to mitigate the risk.  
#


set -euo pipefail

# --- GENERAL SETTINGS ---
WAZUH_VERSION="4.13.1"; STACK_DIR="$HOME/stacks/wazuh"; REPO_URL="https://github.com/wazuh/wazuh-docker.git"

# --- COLORS AND HELPER FUNCTIONS ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m';
log_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[WARNING]${C_RESET} $1"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

check_command() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null && return 0
    log_warn "Command '$cmd' not found."
    if [ -f /etc/os-release ]; then
        source /etc/os-release; ID=${ID:-unknown};
    else
        ID="unknown"
    fi
    local install_instruction=""
    local pkg_name="$cmd"
    case "$cmd" in 
        python3) pkg_name="python3 python3-pip python3-venv" ;; 
        pip) pkg_name="python3-pip" ;; 
        shuf) pkg_name="coreutils" ;; 
    esac
    case $ID in 
        ubuntu|debian) install_instruction="sudo apt update && sudo apt install -y $pkg_name" ;;
        fedora|centos|rhel) 
            if [ "$cmd" == "docker" ]; then pkg_name="docker-ce"; fi
            install_instruction="sudo dnf install -y $pkg_name"
            ;;
        *) install_instruction="Please use your distribution's package manager to install '$pkg_name'." ;;
    esac
    log_error "Prerequisite installation required. Please run:\n\n  ${install_instruction}\n"
}

gen_pass() {
    local pass_length=20
    local upper=$(tr -dc 'A-Z' < /dev/urandom | head -c 1)
    local lower=$(tr -dc 'a-z' < /dev/urandom | head -c 1)
    local digit=$(tr -dc '0-9' < /dev/urandom | head -c 1)
    local special=$(tr -dc '@#$%&*' < /dev/urandom | head -c 1)
    local rest=$(tr -dc 'A-Za-z0-9@#$%&*' < /dev/urandom | head -c $((pass_length - 4)))
    local combined="${upper}${lower}${digit}${special}${rest}"
    echo "$combined" | fold -w1 | shuf | tr -d '\n'
}

# --- MAIN FLOW ---

log_info "Checking prerequisites..."
PYTHON_OK=true
if ! command -v python3 &>/dev/null || ! command -v pip &>/dev/null || ! python3 -c "import venv" &>/dev/null; then
    PYTHON_OK=false
fi

if [ "$PYTHON_OK" = "false" ]; then
    log_warn "One or more Python dependencies (python3, pip, venv) were not found."
    if [ -f /etc/os-release ]; then 
        source /etc/os-release; ID=${ID:-unknown};
    else 
        ID="unknown"
    fi
    install_instruction=""
    case $ID in
        ubuntu|debian) install_instruction="sudo apt update && sudo apt install -y python3 python3-pip python3-venv" ;;
        fedora|centos|rhel) install_instruction="sudo dnf install -y python3 python3-pip" ;; # dnf/yum usually includes venv
        *) install_instruction="Please install 'python3', 'python3-pip', and 'python3-venv' using your system's package manager." ;;
    esac
    log_error "Installation required. Please run the command below and run the script again:\n\n  ${install_instruction}\n"
fi

for cmd in docker git shuf sed rsync; do 
    check_command "$cmd"
done
if ! groups "$USER" | grep -q '\bdocker\b'; then 
    log_error "User $USER does not belong to the 'docker' group. Run 'sudo usermod -aG docker $USER', log out/in, and run again." 
fi
if docker compose version &>/dev/null; then 
    DC="docker compose"
elif docker-compose version &>/dev/null; then 
    DC="docker-compose"
else 
    log_error "No version of Docker Compose was found."
fi
log_success "Prerequisites met (using '$DC')."


log_info "Preparing the stack directory at ${STACK_DIR}..."
mkdir -p "$STACK_DIR"
TEMP_DIR=$(mktemp -d)
log_info "Cloning Wazuh Docker repository (v$WAZUH_VERSION)..."
git -c advice.detachedHead=false clone --depth 1 --branch "v$WAZUH_VERSION" "$REPO_URL" "$TEMP_DIR" > /dev/null
log_info "Copying only the essential files to the stack..."
rsync -a "${TEMP_DIR}/single-node/" "$STACK_DIR/"
rm -rf "$TEMP_DIR"
cd "$STACK_DIR"
log_success "Clean stack structure created in $(pwd)"

log_info "Generating passwords and creating .env file..."
ADMIN_PASS=$(gen_pass)
DASHBOARD_PASS=$(gen_pass)
cat > .env <<EOL
WAZUH_VERSION=${WAZUH_VERSION}
WAZUH_DASHBOARD_PORT=443
INDEXER_PASSWORD='${ADMIN_PASS}'
API_PASSWORD='MyS3cr37P450r.*-'
DASHBOARD_PASSWORD='${DASHBOARD_PASS}'
EOL
chmod 600 .env
log_success ".env file created."

log_info "Adapting docker-compose.yml with health checks..."
cp docker-compose.yml docker-compose.yml.orig
# Adapt passwords and ports
sed -i -e "s|INDEXER_PASSWORD=SecretPassword|INDEXER_PASSWORD=\${INDEXER_PASSWORD}|g" \
    -e "s|DASHBOARD_PASSWORD=kibanaserver|DASHBOARD_PASSWORD=\${DASHBOARD_PASSWORD}|g" \
    -e "s|\"443:5601\"|\"\${WAZUH_DASHBOARD_PORT}:5601\"|g" \
    docker-compose.yml
# Add Healthcheck for the Indexer
sed -i '/hostname: wazuh.indexer/a \
    healthcheck:\n\
      test: ["CMD-SHELL", "curl -k -u admin:\${INDEXER_PASSWORD} https://localhost:9200/_cluster/health?wait_for_status=yellow\&timeout=5s"]\n\
      interval: 10s\n\
      timeout: 5s\n\
      retries: 20' docker-compose.yml
# Add Healthcheck for the Manager (using the default API password)
sed -i '/hostname: wazuh.manager/a \
    healthcheck:\n\
      test: ["CMD-SHELL", "curl -k -u wazuh-wui:MyS3cr37P450r.*- https://localhost:55000/manager/info"]\n\
      interval: 10s\n\
      timeout: 5s\n\
      retries: 20' docker-compose.yml
# Modify the Dashboard to wait for health checks
sed -i '/depends_on:/a \
      wazuh.indexer:\n\
        condition: service_healthy\n\
      wazuh.manager:\n\
        condition: service_healthy' docker-compose.yml
sed -i '/- wazuh.indexer/d' docker-compose.yml
log_success "docker-compose.yml adapted."

log_info "Generating internal certificates..."
$DC -f generate-indexer-certs.yml down -v 2>/dev/null || true
$DC -f generate-indexer-certs.yml run --rm generator
log_success "Certificates generated."
log_info "Fixing file ownership and permissions..."
sudo chown -R "$USER":"$USER" ./config
find ./config -type d -exec chmod 700 {} \;
find ./config -type f -exec chmod 600 {} \;
log_success "Ownership and permissions fixed."

log_info "Updating password hashes in 'internal_users.yml'..."
venv_dir=".py_venv"
python3 -m venv "$venv_dir"
source "$venv_dir/bin/activate"
pip install --quiet "passlib==1.7.4" "bcrypt==3.2.2"
internal_users_file="./config/wazuh_indexer/internal_users.yml"
hash_admin=$(python3 -c "from passlib.hash import bcrypt; print(bcrypt.hash('$ADMIN_PASS'))")
hash_kibanaserver=$(python3 -c "from passlib.hash import bcrypt; print(bcrypt.hash('$DASHBOARD_PASS'))")
escaped_hash_admin=$(printf '%s\n' "$hash_admin" | sed 's:[][\\/.^$*]:\\&:g')
escaped_hash_kibanaserver=$(printf '%s\n' "$hash_kibanaserver" | sed 's:[][\\/.^$*]:\\&:g')
sed -i "/^admin:/,/^[^ ]/ s|^\(\s*hash:\s*\).*|\1\"$escaped_hash_admin\"|" "$internal_users_file"
sed -i "/^kibanaserver:/,/^[^ ]/ s|^\(\s*hash:\s*\).*|\1\"$escaped_hash_kibanaserver\"|" "$internal_users_file"
deactivate
rm -rf "$venv_dir"
log_success "Password hashes synchronized."

log_info "Setting vm.max_map_count permanently..."
if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf > /dev/null
fi
sudo sysctl -p > /dev/null
log_success "Kernel setting applied."

log_info "Starting the Wazuh stack (it may take a few minutes for health checks to pass)..."
$DC down -v --remove-orphans 2>/dev/null || true
$DC up -d
log_success "Start command sent."

log_info "Waiting for the Dashboard to be ready (5-minute timeout)..."
HEALTHY=false
for i in {1..30}; do 
    if $DC logs wazuh.dashboard 2>/dev/null | grep -q "Server running at"; then 
        log_success "Dashboard is up!"; 
        HEALTHY=true; 
        break; 
    fi
    echo -n "."
    sleep 10
done
echo
if [ "$HEALTHY" = "false" ]; then 
    log_error "The Dashboard did not start in time. Check the logs with: $DC logs wazuh.dashboard"
fi

source .env
ip_host=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
echo
log_success "--------------------------------------------------------"
log_success " WAZUH INSTALLATION COMPLETE!"
log_success "--------------------------------------------------------"
echo
log_info "Final container status:"; $DC ps; echo
log_info "Access the Wazuh Dashboard at: https://${ip_host}:${WAZUH_DASHBOARD_PORT}"
log_info "Login user: admin"
log_info "Generated password: ${ADMIN_PASS}"
echo
log_warn "Store this password in a safe place!"