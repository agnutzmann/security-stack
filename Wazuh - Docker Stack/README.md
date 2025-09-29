# Wazuh Docker: Instalação Automatizada e Robusta

Este repositório contém um script de instalação automatizado para implantar uma stack completa do Wazuh (Manager, Indexer, Dashboard) usando Docker. O objetivo é fornecer um método rápido, seguro e de fácil manutenção para subir um ambiente Wazuh single-node em qualquer máquina Linux com Docker.

O script foi projetado para ser executado uma única vez, preparando todo o ambiente com as melhores práticas de segurança e gerando ferramentas para manutenção futura.

## ✨ Funcionalidades

-   **Automação Completa:** Instalação do zero com um único comando.
-   **Estrutura Limpa:** Cria um diretório de stack contendo apenas os arquivos essenciais para a operação, sem o "lixo" do repositório Git.
-   **Segurança por Padrão:**
    -   Gera senhas fortes e aleatórias para todos os componentes internos.
    -   Aplica permissões de arquivo restritivas (`chmod 700/600`) nos certificados e configurações, como exigido pelo plugin de segurança do Wazuh Indexer.
-   **Manutenção Simplificada:**
    -   Cria automaticamente scripts de `backup.sh` e `restore.sh` prontos para uso.
    -   O script `backup.sh` faz um backup completo tanto dos arquivos de configuração quanto dos volumes de dados do Docker.
    -   O script `restore.sh` automatiza a restauração do último backup de volumes.
-   **Configuração Persistente:** Garante que as configurações de kernel necessárias (`vm.max_map_count`) sobrevivam a uma reinicialização do servidor.
-   **Compatibilidade:** Detecta e utiliza automaticamente a versão correta do `docker compose` (v2) ou `docker-compose` (v1) presente no sistema.

## 📋 Pré-requisitos

O sistema host deve ter os seguintes pacotes instalados:
* Docker
* Docker Compose (v1 ou v2)
* Git
* Python 3 (geralmente os pacotes python3, python3-pip e python3-venv). O script usará estas ferramentas para criar um ambiente virtual temporário e seguro, sem instalar pacotes Python globalmente no sistema.
* `sed`, `rsync`, `shuf` (geralmente incluídos em `coreutils`)

O script verifica se o usuário atual pertence ao grupo `docker`.

## 🚀 Como Usar

1.  **Download do Script:**
    Faça o download do script `install.sh` deste repositório.

2.  **(Opcional) Customizar Variáveis:**
    Você pode editar as duas primeiras variáveis no script para alterar a versão do Wazuh ou o diretório de instalação:
    ```bash
    readonly WAZUH_VERSION="4.13.1"
    readonly STACK_DIR="$HOME/stacks/wazuh"
    ```

3.  **Dar Permissão de Execução:**
    ```bash
    chmod +x install.sh
    ```

4.  **Executar a Instalação:**
    ```bash
    ./install.sh
    ```
    O script cuidará de todo o resto. Ao final, ele exibirá o status dos containers, a URL de acesso e as credenciais geradas.

## 📁 Estrutura de Arquivos Pós-Instalação

Após a execução, o diretório `STACK_DIR` (`~/stacks/wazuh` por padrão) conterá:

-   `docker-compose.yml`: O arquivo de orquestração dos containers, já adaptado para usar senhas seguras.
-   `.env`: Arquivo com todas as senhas geradas. **Trate este arquivo como confidencial.**
-   `config/`: Diretório contendo todos os certificados e arquivos de configuração (`internal_users.yml`, etc.).
-   `backups/`: Diretório onde os backups serão salvos.
-   `backup.sh`: Script para executar um backup completo da stack.
-   `restore.sh`: Script para restaurar o último backup de dados.
-   `upgrade.sh`: Script auxiliar para facilitar o processo de upgrade de versão.

## 🔧 Manutenção

Os scripts a seguir são gerados automaticamente e devem ser executados de dentro do diretório da stack.

### Backup

Para criar um backup completo da configuração e dos dados:
```bash
./backup.sh
```
Dois arquivos `.tgz` serão criados no diretório `backups/`.

### Restauração

Para restaurar o último backup de dados (isso irá parar os containers e sobrescrever os dados atuais):
```bash
./restore.sh
```

### Upgrade

Para atualizar a versão do Wazuh:
1.  Edite o arquivo `.env` e altere a variável `WAZUH_VERSION`.
2.  Execute o script de upgrade:
    ```bash
    ./upgrade.sh
    ```
    O script fará um backup antes de iniciar o processo de atualização.

## 🛡️ Considerações de Segurança

-   **Senhas no Docker Inspect:** Este método de instalação usa variáveis de ambiente para passar as senhas para os containers, conforme a documentação oficial do Wazuh. Esteja ciente de que qualquer usuário com acesso ao socket do Docker no host pode inspecionar os containers (`docker inspect`) e ver as senhas em texto plano. Proteja o acesso ao seu host Docker.
-   **Criptografia de Backups:** O script de backup não criptografa os arquivos `.tgz` por padrão. Para ambientes de produção, considere adicionar uma etapa de criptografia usando `gpg` ou `age` após a criação do backup.

## 📄 Licença

Este projeto é de código aberto. Sinta-se à vontade para usar e modificar.
