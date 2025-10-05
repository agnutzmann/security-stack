```markdown
# Nuclei Intelligent Automation — Service-Driven Scanning

Este projeto fornece um conjunto de scripts para executar varreduras de vulnerabilidade de forma automatizada, inteligente e eficiente usando **ProjectDiscovery Nuclei** com Docker.

A principal filosofia é a de **varredura dirigida por serviço**: em vez de executar milhares de templates de forma indiscriminada, os scripts primeiro utilizam o Nmap para descobrir quais serviços estão realmente ativos nos hosts-alvo e, em seguida, executam apenas os templates Nuclei relevantes para os serviços encontrados.

Este método reduz drasticamente o tempo de scan, minimiza erros de conexão e aumenta significativamente a precisão dos resultados.

---

## 🧩 Estrutura Lógica

A automação é dividida em duas responsabilidades principais, refletidas em dois scripts:

```
~/stacks/nuclei/
├── nuclei-templates/        # Repositório oficial de templates do Nuclei
├── scans/                   # Diretório de saída para todos os resultados
│   ├── fast/                # Resultados de scans com perfil 'fast'
│   └── full/                # Resultados de scans com perfil 'full'
├── run-scan.sh              # O script de scan inteligente e unificado
└── update-templates.sh      # Script para manter os templates atualizados
```

---

## 🚀 Setup Inicial (Primeira Utilização)

Para um usuário que nunca utilizou este ambiente, alguns passos de preparação são necessários. Os scripts são orquestradores e dependem de ferramentas que devem estar pré-instaladas.

Siga este guia para configurar seu ambiente do zero.

### Passo 1: Instalar Dependências

As seguintes ferramentas são necessárias. Em sistemas baseados em Debian/Ubuntu, utilize o comando abaixo:

```
sudo apt-get update && sudo apt-get install -y git nmap docker.io jq
```

- `git`: Para baixar e atualizar os templates do Nuclei.
- `nmap`: Para a descoberta inteligente de hosts e serviços.
- `docker`: Para executar o Nuclei em um ambiente isolado sem a necessidade de instalá-lo localmente.
- `jq`: Para processar os resultados em formato JSON.

### Passo 2: Configurar Permissões do Docker (Pós-instalação)

Para executar `docker` sem `sudo`, adicione seu usuário ao grupo `docker`:

```
sudo usermod -aG docker ${USER}
```

Atenção: É necessário **logout e login novamente** (ou reiniciar o sistema) para que a permissão tenha efeito.

### Passo 3: Baixar os Templates do Nuclei

Este é um passo único para obter a base de templates. Dentro do seu diretório de trabalho (ex: `~/stacks/nuclei`), execute:

```
git clone https://github.com/projectdiscovery/nuclei-templates.git ./nuclei-templates
```

O script `update-templates.sh` se encarregará de manter este diretório atualizado no futuro.

### Passo 4: Tornar os Scripts Executáveis

Após salvar os scripts `run-scan.sh` e `update-templates.sh` em seu diretório, dê permissão de execução:

```
chmod +x update-templates.sh run-scan.sh
```

Com estes quatro passos, o ambiente está **pronto para escanear**.

---

## 🔄 update-templates.sh

Um script simples e dedicado que mantém o repositório local de templates sincronizado com o repositório oficial.

**Uso:**  
Execute este script periodicamente para garantir que suas varreduras utilizem as definições de vulnerabilidade mais recentes.

```
./update-templates.sh
```

---

## 🚀 run-scan.sh — O Scanner Inteligente

Este é o script principal que executa a varredura inteligente. Ele requer dois argumentos principais: o **alvo** e um **perfil de scan** (`--profile`), que define a profundidade da análise.

**Uso:**

```
# Sintaxe
./run-scan.sh <alvo> --profile [fast|full]
```

### Perfis de Scan

| Perfil | Descrição | Casos de Uso |
| ------ | --------- | ------------|
| `fast` | Rápido e focado: busca apenas por vulnerabilidades críticas e de alto impacto. | Ideal para verificações diárias, rápidas ou integração em pipelines CI/CD. |
| `full` | Completo e aprofundado: inclui severidades médias e mais tags de análise. | Base para análises semanais/mensais ou investigações profundas. |

### Exemplos de Execução

```
# Scan rápido na sub-rede local
./run-scan.sh 192.168.2.0/24 --profile fast

# Scan completo em um domínio específico
./run-scan.sh example.com --profile full
```

Ao ser executado, o script exibe uma mensagem de ajuda detalhada se os argumentos estiverem incorretos ou se a ajuda for solicitada (`-h` ou `--help`).

---

## ⚙️ Fluxo de Trabalho Recomendado

1. **Setup Inicial:** Siga os passos da seção "Setup Inicial".
2. **Manutenção (Agendada):**
   - Configure uma tarefa cron para executar `update-templates.sh` diariamente.
     ```
     # Cron job para rodar todo dia às 05:00
     0 5 * * * /path/to/your/scripts/update-templates.sh
     ```
3. **Execução (Sob Demanda):**
   - Execute `run-scan.sh` com o alvo e perfil desejados conforme a necessidade.

---

## 🔒 Boas Práticas de Segurança

- Autorização: Nunca execute varreduras contra alvos sem autorização explícita.
- Atualização: Mantenha os templates sempre atualizados para garantir a detecção de novas vulnerabilidades.
- Rate-Limiting: Parâmetros nos perfis são ajustados para redes locais. Cuidado ao escanear a internet, considerando possíveis bloqueios.
- Gerenciamento de Resultados: Armazene em local seguro e versionado. Integre com SIEMs (Wazuh, Splunk) ou plataformas de correlação (OpenCTI, DefectDojo).

---

## Recursos

- [ProjectDiscovery Nuclei Templates](https://github.com/projectdiscovery/nuclei-templates)
- [Documentação Nuclei](https://nuclei.projectdiscovery.io/)
```
