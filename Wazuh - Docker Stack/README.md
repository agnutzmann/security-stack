# Wazuh Docker: Instalação Automatizada e Robusta

Este repositório contém um script de instalação automatizado para implantar uma stack completa do Wazuh (Manager, Indexer, Dashboard) usando Docker. O objetivo é fornecer um método rápido, seguro e de fácil manutenção para subir um ambiente Wazuh single-node em qualquer máquina Linux com Docker.

O script foi projetado para ser executado uma única vez, preparando todo o ambiente com as melhores práticas de segurança e gerando ferramentas para manutenção futura.

## ✨ Funcionalidades

-   **Automação Completa:** Instalação do zero com um único comando.
-   **Verificação Inteligente de Pré-requisitos:** Detecta automaticamente as dependências ausentes e informa o comando exato de instalação para sistemas baseados em Debian/Ubuntu e Fedora/RHEL.
-   **Estrutura Limpa:** Cria um diretório de stack contendo apenas os arquivos essenciais para a operação, sem o "lixo" do repositório Git.
-   **Segurança por Padrão:**
    -   Gera senhas fortes e aleatórias para todos os componentes internos.
    -   Aplica permissões de arquivo restritivas (`chmod 700/600`) nos certificados e configurações, como exigido pelo plugin de segurança do Wazuh Indexer.
-   **Manutenção Simplificada:**
    -   Cria automaticamente scripts de `backup.sh`, `restore.sh` e um modelo de `upgrade.sh` prontos para uso.
    -   O script `backup.sh` faz um backup completo tanto dos arquivos de configuração quanto dos volumes de dados do Docker.
    -   O script `restore.sh` automatiza a restauração do último backup de dados.
-   **Configuração Persistente:** Garante que as configurações de kernel necessárias (`vm.max_map_count`) sobrevivam a uma reinicialização do servidor.
-   **Compatibilidade:** Detecta e utiliza automaticamente a versão correta do `docker compose` (v2) ou `docker-compose` (v1) presente no sistema.

## 📋 Pré-requisitos

O script foi projetado para rodar em sistemas Linux modernos e precisa das seguintes ferramentas para funcionar: Docker, Git e Python 3.

**Não se preocupe em verificar tudo manualmente.** Se alguma dependência estiver faltando, o próprio script irá detectar e informar o comando exato que você precisa executar para instalá-la.

## 🚀 Como Usar

1.  **Faça o download do script**
    Salve o arquivo `install.sh` em seu diretório home ou onde preferir.

2.  **Dê permissão de execução**
    ```bash
    chmod +x install.sh
    ```

3.  **Execute o script**
    ```bash
    ./install.sh
    ```
    -   Se alguma dependência estiver faltando, o script irá parar e fornecer o comando de instalação exato para o seu sistema. Basta copiar, colar, executar o comando sugerido e depois rodar o `./install.sh` novamente.
    -   Se todos os pré-requisitos estiverem atendidos, a instalação prosseguirá automaticamente até o final.

## 📁 Estrutura de Arquivos Pós-Instalação

Após a execução, o diretório de destino (`~/stacks/wazuh` por padrão) conterá:

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