```markdown
# Nuclei Intelligent Automation — Service-Driven Scanning

Este projeto fornece um conjunto de scripts para executar varreduras de vulnerabilidade de forma automatizada, inteligente e eficiente usando **ProjectDiscovery Nuclei** com Docker.

A principal filosofia é a de **varredura dirigida por serviço**: em vez de executar milhares de templates de forma indiscriminada, os scripts primeiro utilizam o **Nmap** para descobrir quais serviços estão realmente ativos nos hosts-alvo e, em seguida, executam apenas os templates Nuclei relevantes para os serviços encontrados.

Este método reduz drasticamente o tempo de scan, minimiza erros de conexão e aumenta significativamente a precisão dos resultados.

---

## 🧩 Estrutura Lógica

A automação é dividida em duas responsabilidades principais, refletidas em dois scripts:

```

\~/stacks/nuclei/
├── nuclei-templates/        \# Repositório oficial de templates do Nuclei
├── scans/                   \# Diretório de saída para todos os resultados
│   ├── fast/                \# Resultados de scans com perfil 'fast'
│   └── full/                \# Resultados de scans com perfil 'full'
├── run-scan.sh              \# O script de scan inteligente e unificado
└── update-templates.sh      \# Script para manter os templates atualizados

````

---

## 🚀 Setup Inicial (Primeira Utilização)

Para um usuário que nunca utilizou este ambiente, alguns passos de preparação são necessários. Os scripts são orquestradores e dependem de ferramentas que devem estar pré-instaladas.

Siga este guia para configurar seu ambiente do zero.

### Passo 1: Instalar Dependências

As seguintes ferramentas são necessárias. Em sistemas baseados em Debian/Ubuntu, utilize o comando abaixo:

```bash
sudo apt-get update && sudo apt-get install -y git nmap docker.io jq
````

  * **`git`**: Para baixar e atualizar os templates do Nuclei.
  * **`nmap`**: Para a descoberta inteligente de hosts e serviços.
  * **`docker`**: Para executar o Nuclei em um ambiente isolado sem a necessidade de instalá-lo localmente.
  * **`jq`**: Para processar os resultados em formato JSON.

### Passo 2: Configurar Permissões do Docker (Pós-instalação)

Para executar `docker` sem `sudo`, adicione seu usuário ao grupo `docker`:

```bash
sudo usermod -aG docker ${USER}
```

**Atenção:** Você precisa **fazer logout e login novamente** (ou reiniciar o sistema) para que esta permissão tenha efeito.

### Passo 3: Baixar os Templates do Nuclei

Este é um passo único para obter a base de templates. Dentro do seu diretório de trabalho (ex: `~/stacks/nuclei`), execute:

```bash
git clone [https://github.com/projectdiscovery/nuclei-templates.git](https://github.com/projectdiscovery/nuclei-templates.git) ./nuclei-templates
```

O script `update-templates.sh` se encarregará de manter este diretório atualizado daqui em diante.

### Passo 4: Tornar os Scripts Executáveis

Após salvar os scripts `run-scan.sh` e `update-templates.sh` em seu diretório, dê a eles permissão de execução:

```bash
chmod +x update-templates.sh run-scan.sh
```

Com estes quatro passos, seu ambiente está **pronto para escanear**.

-----

## 🔄 `update-templates.sh`

Um script simples e dedicado com uma única responsabilidade: manter o repositório local de templates do Nuclei sincronizado com o repositório oficial no GitHub.

**Uso:**
Execute este script periodicamente para garantir que suas varreduras utilizem as definições de vulnerabilidade mais recentes.

```bash
# Executar a atualização
./update-templates.sh
```

-----

## 🚀 `run-scan.sh` — O Scanner Inteligente

Este é o script principal que executa a varredura inteligente. Ele requer dois argumentos principais: o **alvo** e um **perfil de scan** (`--profile`), que define a profundidade da análise.

**Uso:**

```bash
# Sintaxe
./run-scan.sh <alvo> --profile [fast|full]
```

### Perfis de Scan

| Perfil | Descrição | Casos de Uso |
| :--- | :--- | :--- |
| `fast` | **Rápido e Focado:** Busca apenas por vulnerabilidades de severidade `critical` e `high` com tags de alto impacto (CVEs, logins padrão, painéis expostos, etc.). | Ideal para verificações diárias, rápidas e de baixo ruído ou para integração em pipelines de CI/CD. |
| `full` | **Completo e Aprofundado:** Inclui severidade `medium` e uma gama maior de tags para uma análise mais exaustiva (vulnerabilidades gerais, tecnologias, etc.). | Ideal para análises de linha de base, varreduras semanais/mensais ou quando uma investigação mais profunda é necessária. |

### Exemplos de Execução

```bash
# Executar um scan rápido na sub-rede local
./run-scan.sh 192.168.2.0/24 --profile fast

# Executar um scan completo em um domínio específico
./run-scan.sh example.com --profile full
```

Ao ser executado, o script exibe uma mensagem de ajuda detalhada se os argumentos estiverem incorretos ou se a ajuda for solicitada (`-h` ou `--help`).

-----

## ⚙️ Fluxo de Trabalho Recomendado

1.  **Setup Inicial:** Siga os passos da seção **"Setup Inicial (Primeira Utilização)"**.

2.  **Manutenção (Agendada):**

      * Configure uma tarefa `cron` para executar `update-templates.sh` diariamente.
        ```cron
        # Exemplo de cron job para rodar todo dia às 05:00
        0 5 * * * /path/to/your/scripts/update-templates.sh
        ```

3.  **Execução (Sob Demanda):**

      * Execute `run-scan.sh` com o alvo e o perfil desejados conforme a necessidade.

-----

## 🔒 Boas Práticas de Segurança

  * **Autorização:** Nunca execute varreduras contra alvos sem autorização explícita.
  * **Atualização:** Mantenha os templates atualizados para garantir a detecção de novas vulnerabilidades.
  * **Rate-Limiting:** Os parâmetros nos perfis são ajustados para redes locais. Tenha cuidado ao escanear alvos na internet para não sobrecarregar serviços ou ser bloqueado por WAFs.
  * **Gerenciamento de Resultados:** Armazene os resultados em um local seguro e versionado. Integre com ferramentas de SIEM (Wazuh, Splunk) ou plataformas de correlação (OpenCTI, DefectDojo).

-----

```
```