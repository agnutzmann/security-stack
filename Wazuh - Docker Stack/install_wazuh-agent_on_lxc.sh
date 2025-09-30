#!/usr/bin/env bash
#
# Script para Instalação e Configuração do Agente Wazuh
# Compatível com: Debian & Ubuntu
#

# --- CONFIGURAÇÕES ---
# IMPORTANTE: Altere esta variável para o IP do seu Wazuh Manager.
WAZUH_MANAGER_IP='192.168.2.x'
# Versão do agente a ser instalada.
WAZUH_AGENT_VERSION='4.13.1'
# --- FIM DAS CONFIGURAÇÕES ---

# Sai imediatamente se um comando falhar.
set -euo pipefail

# --- CORES E FUNÇÕES AUXILIARES ---
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
log_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

# --- VERIFICAÇÃO INICIAL ---
# Garante que o script está sendo executado como root.
if [[ "${EUID}" -ne 0 ]]; then
  log_error "Este script precisa ser executado como root. Use 'sudo'."
fi

# --- FLUXO PRINCIPAL ---
log_info "Iniciando a instalação do Agente Wazuh v${WAZUH_AGENT_VERSION}..."

# 1. Atualiza os pacotes e instala dependências
log_info "Atualizando a lista de pacotes e instalando dependências (wget)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update > /dev/null
apt-get install -y wget lsb-release > /dev/null
log_success "Dependências instaladas."

# 2. Download do pacote do agente
DEB_FILE="wazuh-agent_${WAZUH_AGENT_VERSION}_amd64.deb"
DEB_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${DEB_FILE}"

log_info "Baixando o pacote do agente de ${DEB_URL}..."
wget -q "${DEB_URL}" -O "./${DEB_FILE}"
log_success "Download do pacote '${DEB_FILE}' concluído."

# 3. Instalação do agente
log_info "Instalando o agente e configurando o Manager IP para: ${WAZUH_MANAGER_IP}..."
# A variável WAZUH_MANAGER é usada pelo instalador para configurar o ossec.conf automaticamente.
WAZUH_MANAGER="${WAZUH_MANAGER_IP}" dpkg -i "./${DEB_FILE}"

# 4. Corrige possíveis dependências quebradas
log_info "Verificando e corrigindo dependências..."
apt-get install -f -y > /dev/null
log_success "Instalação finalizada."

# 5. Habilita e inicia o serviço do agente
log_info "Habilitando e iniciando o serviço do agente Wazuh..."
systemctl daemon-reload
systemctl enable wazuh-agent > /dev/null
systemctl start wazuh-agent
log_success "Serviço do agente iniciado e habilitado na inicialização."

# 6. Verifica o status final
log_info "Verificando o status do serviço..."
sleep 2 # Aguarda um momento para o serviço estabilizar
systemctl status wazuh-agent --no-pager

echo
log_success "Processo de instalação do Agente Wazuh concluído!"

# Limpeza
rm -f "./${DEB_FILE}"