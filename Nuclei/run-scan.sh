#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: run-scan.sh (Versão 1.0.0)
# Função: Executa um scan Nuclei inteligente, dirigido por serviços,
#         com perfis de profundidade ('fast' ou 'full').
# Autor: Alexandre Gnutzmann (gnu-it.com)
# -----------------------------------------------------------------------------

set -euo pipefail

# --- Funções Auxiliares ---
print_usage() {
  echo "--------------------------------------------------------------------------------"
  echo "Scanner Nuclei Inteligente (run-scan.sh v1.1.1)"
  echo "--------------------------------------------------------------------------------"
  echo "Este script executa uma varredura de vulnerabilidades inteligente e dirigida por serviços."
  echo "Primeiro, ele mapeia os serviços ativos nos hosts e, em seguida, executa apenas os"
  echo "templates Nuclei relevantes para os serviços encontrados."
  echo ""
  echo "USO:"
  echo "  $0 <alvo> --profile [fast|full]"
  echo "  $0 -h | --help"
  echo ""
  echo "ARGUMENTOS:"
  echo "  <alvo>             O alvo a ser escaneado (ex: 192.168.1.0/24, example.com, lista.txt)."
  echo "  --profile [profile]  Define a profundidade da análise."
  echo ""
  echo "PERFIS DISPONÍVEIS:"
  echo "  fast               - Rápido e focado. Busca por vulnerabilidades críticas e de alto impacto."
  echo "                     (Ideal para verificações diárias e rápidas)."
  echo "  full               - Completo e aprofundado. Busca por um espectro maior de vulnerabilidades."
  echo "                     (Ideal para análises semanais ou de linha de base)."
  echo ""
  echo "EXEMPLOS:"
  echo "  # Executar um scan rápido na sub-rede local"
  echo "  $0 192.168.2.0/24 --profile fast"
  echo ""
  echo "  # Executar um scan completo em um domínio específico"
  echo "  $0 example.com --profile full"
  echo "--------------------------------------------------------------------------------"
}

check_dependencies() {
  for cmd in nmap docker jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "❌ Erro: Dependência '$cmd' não encontrada. Por favor, instale-a." >&2
      exit 1
    fi
  done
  echo "✅ Dependências (nmap, docker, jq) verificadas."
}

# --- Validação de Entrada (CORRIGIDA) ---
# Primeiro, verificamos casos que não precisam de todos os argumentos (ajuda ou nenhum argumento).
if [[ "$#" -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
  print_usage
  exit 0
fi

# Agora, validamos a estrutura para um scan real, que exige 3 argumentos.
if [[ "$#" -ne 3 || "$2" != "--profile" ]]; then
  echo "❌ Erro: Argumentos inválidos ou estrutura incorreta." >&2
  echo ""
  print_usage
  exit 1
fi

TARGET="$1"
PROFILE="$3"

check_dependencies

# --- Configuração de Variáveis ---
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${BASE_DIR}/nuclei-templates"
SCAN_DIR="${BASE_DIR}/scans/${PROFILE}/$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$SCAN_DIR/scan.log"
NMAP_XML_OUTPUT="$SCAN_DIR/nmap_results.xml"

# --- Seleção de Perfil de Scan ---
declare -a NUCLEI_ARGS
case "$PROFILE" in
  fast)
    echo "[*] Perfil selecionado: fast (Rápido, Alto Impacto)"
    NUCLEI_ARGS=(
      -s critical,high
      -tags cve,default-logins,misconfig,exposed-panel
      -etags fuzz,dos,generic
      -c 75
    )
    ;;
  full)
    echo "[*] Perfil selecionado: full (Completo, Aprofundado)"
    NUCLEI_ARGS=(
      -s critical,high,medium
      -tags cve,network,misconfig,vulnerability,tech,exposed
      -etags fuzz,dos
      -c 50
    )
    ;;
  *)
    echo "❌ Erro: Perfil '$PROFILE' inválido. Use 'fast' ou 'full'." >&2
    echo ""
    print_usage
    exit 1
    ;;
esac

# --- Lógica Principal ---
mkdir -p "$SCAN_DIR"
echo "[+] Diretório de resultados criado em: $SCAN_DIR"

echo "[*] [Passo 1/3] Descobrindo hosts ativos em '$TARGET'..."
ACTIVE_HOSTS_FILE="$SCAN_DIR/active_hosts.txt"
nmap -sn -n "$TARGET" -oG - | awk '/Up$/{print $2}' > "$ACTIVE_HOSTS_FILE"
HOST_COUNT=$(wc -l < "$ACTIVE_HOSTS_FILE")

if [[ "$HOST_COUNT" -eq 0 ]]; then
  echo "[!] Nenhum host ativo encontrado. Encerrando."
  rm -r "$SCAN_DIR"
  exit 0
fi

echo "[*] [Passo 2/3] Mapeando serviços nos $HOST_COUNT hosts ativos com Nmap..."
nmap -sV -iL "$ACTIVE_HOSTS_FILE" -oX "$NMAP_XML_OUTPUT" --open > /dev/null 2>&1

echo "[*] [Passo 3/3] Iniciando varredura inteligente com Nuclei..."
docker run --rm \
  -v "${SCAN_DIR}:/app/output:rw" \
  -v "${TEMPLATE_DIR}:/app/templates:ro" \
  projectdiscovery/nuclei:latest \
  -spm /app/output/nmap_results.xml \
  -t /app/templates/ \
  -je /app/output/resultado.json \
  "${NUCLEI_ARGS[@]}" \
  | tee "$LOG_FILE"

# Opcional: Geração de CSV e Envio para Wazuh
echo "[+] Scan completo. Resultados em: $SCAN_DIR"