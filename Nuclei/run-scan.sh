#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: run-scan.sh (Version 1.2.0 - Polished)
# Function: Runs an intelligent, service-driven Nuclei scan by dynamically
#           building tags from Nmap results.
# Author: Alexandre Gnutzmann (gnu-it.com)
# -----------------------------------------------------------------------------

set -euo pipefail
# --- Helper Functions ---
print_usage() {
  echo "--------------------------------------------------------------------------------"
  echo "Intelligent Nuclei Scanner (run-scan.sh v1.2.0 - Polished)"
  echo "--------------------------------------------------------------------------------"
  echo "This script performs a smart, service-driven vulnerability scan. It first maps"
  echo "active services on hosts with Nmap, extracts service names as tags, and then"
  echo "runs Nuclei with those dynamic tags."
  echo ""
  echo "USAGE:"
  echo "  $0 <target> --profile [fast|full]"
  echo "  $0 -h | --help"
  echo ""
  echo "ARGUMENTS:"
  echo "  <target>           The target to scan (e.g., 192.168.1.0/24, example.com, list.txt)."
  echo "  --profile [profile]  Defines the depth of the analysis."
  echo ""
  echo "AVAILABLE PROFILES:"
  echo "  fast               - Quick and focused. Scans for critical and high-impact vulnerabilities."
  echo "  full               - Comprehensive and in-depth. Scans for a broader spectrum of issues."
  echo ""
  echo "EXAMPLES:"
  echo "  # Run a fast scan on the local subnet"
  echo "  $0 192.168.2.0/24 --profile fast"
  echo "--------------------------------------------------------------------------------"
}
check_dependencies() {
  for cmd in nmap docker jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "❌ Error: Dependency '$cmd' not found. Please install it." >&2
      exit 1
    fi
  done
  echo "✅ Dependencies (nmap, docker, jq) verified."
}
# --- Input Validation ---
if [[ "$#" -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
  print_usage
  exit 0
fi
if [[ "$#" -ne 3 || "$2" != "--profile" ]]; then
  echo "❌ Error: Invalid arguments or incorrect structure." >&2
  echo ""
  print_usage
  exit 1
fi
TARGET="$1"
PROFILE="$3"
check_dependencies
# --- Variable Setup ---
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${BASE_DIR}/nuclei-templates"
SCAN_DIR="${BASE_DIR}/scans/${PROFILE}/$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${SCAN_DIR}/scan.log"
NMAP_XML_OUTPUT="${SCAN_DIR}/nmap_results.xml"
# --- Scan Profile Selection ---
declare -a NUCLEI_ARGS
case "$PROFILE" in
  fast)
    echo "[*] Profile selected: fast (High-Impact)"
    NUCLEI_ARGS=(
      -s critical,high
      -tags cve,default-logins,misconfig,exposed-panel
      -etags fuzz,dos,generic
      -c 75
    )
    ;;
  full)
    echo "[*] Profile selected: full (Comprehensive)"
    NUCLEI_ARGS=(
      -s critical,high,medium
      -tags cve,network,misconfig,vulnerability,tech,exposed
      -etags fuzz,dos
      -c 50
    )
    ;;
  *)
    echo "❌ Error: Invalid profile '$PROFILE'. Use 'fast' or 'full'." >&2
    echo ""
    print_usage
    exit 1
    ;;
esac
# --- Main Logic ---
mkdir -p "$SCAN_DIR"
echo "[+] Results directory created: $SCAN_DIR"
echo "[*] [Step 1/3] Discovering active hosts in '$TARGET'..."
ACTIVE_HOSTS_FILE="${SCAN_DIR}/active_hosts.txt"
nmap -sn -n "$TARGET" -oG - | awk '/Up$/{print $2}' > "$ACTIVE_HOSTS_FILE"
HOST_COUNT=$(wc -l < "$ACTIVE_HOSTS_FILE")
if [[ "$HOST_COUNT" -eq 0 ]]; then
  echo "[!] No active hosts found. Exiting."
  rm -r "$SCAN_DIR"
  exit 0
fi
echo "[*] [Step 2/3] Mapping services on $HOST_COUNT active host(s) with Nmap..."
nmap -sV -iL "$ACTIVE_HOSTS_FILE" -oX "$NMAP_XML_OUTPUT" --open
if [[ ! -s "$NMAP_XML_OUTPUT" ]]; then
    echo "❌ Error: Nmap scan failed or found no open ports. Result file is empty." >&2
    exit 1
fi
echo "[*] [Step 3/3] Extracting service tags from Nmap results..."
DETECTED_TAGS=$(grep 'service name="' "$NMAP_XML_OUTPUT" | sed -e 's/.*service name="\([^"]*\)".*/\1/' -e 's/ssl\/http/http,ssl/' | sort -u | tr '\n' ',' | sed 's/,$//')
if [ -z "$DETECTED_TAGS" ]; then
    echo "[!] Could not detect any services to use as tags. Exiting."
    exit 1
fi
echo "[+] Services detected. Using for Nuclei tags: $DETECTED_TAGS"
# Add the detected tags and the explicit template path to the arguments array.
NUCLEI_ARGS+=( -tags "$DETECTED_TAGS" -t /root/nuclei-templates )
echo "[*] [Step 4/4] Starting intelligent scan with Nuclei..."
docker run --rm \
  -v "${SCAN_DIR}:/app/output:rw" \
  -v "${TEMPLATE_DIR}:/root/nuclei-templates:ro" \
  --entrypoint /usr/local/bin/nuclei \
  projectdiscovery/nuclei:latest \
  -l /app/output/active_hosts.txt \
  -je /app/output/resultado.json \
  "${NUCLEI_ARGS[@]}" \
  | tee "$LOG_FILE"
echo "[+] Scan complete. Results located in: $SCAN_DIR"