#!/usr/bin/env bash
#
# Script for Wazuh Agent Installation and Configuration
# Compatible with: Debian & Ubuntu
# Author: Alexandre Gnutzmann (gnu-it.com)
#

# --- SETTINGS ---
# IMPORTANT: Change this variable to your Wazuh Manager's IP.
WAZUH_MANAGER_IP='192.168.2.x'
# Agent version to be installed.
WAZUH_AGENT_VERSION='4.13.1'
# --- END OF SETTINGS ---

# Exits immediately if a command fails.
set -euo pipefail

# --- COLORS AND HELPER FUNCTIONS ---
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
log_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; exit 1; }

# --- INITIAL CHECK ---
# Ensures the script is run as root.
if [[ "${EUID}" -ne 0 ]]; then
  log_error "This script must be run as root. Use 'sudo'."
fi

# --- MAIN FLOW ---
log_info "Starting the installation of Wazuh Agent v${WAZUH_AGENT_VERSION}..."

# 1. Update packages and install dependencies
log_info "Updating package list and installing dependencies (wget)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update > /dev/null
apt-get install -y wget lsb-release > /dev/null
log_success "Dependencies installed."

# 2. Download the agent package
DEB_FILE="wazuh-agent_${WAZUH_AGENT_VERSION}_amd64.deb"
DEB_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${DEB_FILE}"

log_info "Downloading the agent package from ${DEB_URL}..."
wget -q "${DEB_URL}" -O "./${DEB_FILE}"
log_success "Download of package '${DEB_FILE}' complete."

# 3. Install the agent
log_info "Installing the agent and setting the Manager IP to: ${WAZUH_MANAGER_IP}..."
# The WAZUH_MANAGER variable is used by the installer to configure ossec.conf automatically.
WAZUH_MANAGER="${WAZUH_MANAGER_IP}" dpkg -i "./${DEB_FILE}"

# 4. Fix any potential broken dependencies
log_info "Checking and fixing dependencies..."
apt-get install -f -y > /dev/null
log_success "Installation finished."

# 5. Enable and start the agent service
log_info "Enabling and starting the Wazuh agent service..."
systemctl daemon-reload
systemctl enable wazuh-agent > /dev/null
systemctl start wazuh-agent
log_success "Agent service started and enabled on boot."

# 6. Check the final status
log_info "Checking the service status..."
sleep 2 # Waits a moment for the service to stabilize
systemctl status wazuh-agent --no-pager

echo
log_success "Wazuh Agent installation process complete!"

# Cleanup
rm -f "./${DEB_FILE}"