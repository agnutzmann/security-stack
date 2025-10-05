#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: update-templates.sh (Versão 1.0.0)
# Função: Atualiza o repositório de templates do Nuclei. 
#         Deve ser executado periodicamente (ex: via cron).
# Autor: Alexandre Gnutzmann (gnu-it.com)
# -----------------------------------------------------------------------------

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${BASE_DIR}/nuclei-templates"

echo "[*] Verificando repositório de templates em '$TEMPLATE_DIR'..."

if [[ ! -d "$TEMPLATE_DIR/.git" ]]; then
  echo "❌ Erro: O diretório não é um repositório git. Clone o repositório primeiro:" >&2
  echo "git clone https://github.com/projectdiscovery/nuclei-templates.git $TEMPLATE_DIR" >&2
  exit 1
fi

echo "[*] Atualizando templates via 'git pull'..."
if git -C "$TEMPLATE_DIR" pull --quiet; then
  echo "✅ Repositório de templates atualizado com sucesso."
else
  echo "[!] Falha ao atualizar templates. Verifique a conexão ou possíveis conflitos." >&2
  exit 1
fi

exit 0