# 🛡️ Integração YARA com Wazuh Agent

Este guia descreve os passos mínimos necessários para ativar a detecção de malware com YARA nos agentes Wazuh usando a integração do projeto [`wazuh-yara`](https://github.com/ADORSYS-GIS/wazuh-yara).

---

## 1. 📦 Instalação do mecanismo YARA no agente - Client Endpoint

```bash
curl -SL --progress-bar https://raw.githubusercontent.com/ADORSYS-GIS/wazuh-yara/main/scripts/install.sh | sh
```

Esse comando:

- Instala o binário **YARA** (caso ainda não esteja presente)
- Cria o diretório `/var/ossec/wazuh-yara`
- Cria o script `yara.sh` para varredura automatizada
- Define a pasta de regras: `/var/ossec/ruleset/yara/rules/yara_rules.yar`
- Cria um cron job para execução periódica
- Define `/var/ossec/logs/yara.log` como arquivo de saída da varredura

---

## 2. 🖥️ Configuração do agente no `ossec.conf` - Client Endpoint

No arquivo de configuração do agente (`/var/ossec/etc/ossec.conf`), adicione:

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/ossec/logs/yara.log</location>
</localfile>
```

✅ Isso instrui o **Wazuh Agent** a monitorar o arquivo `yara.log`, que é gerado automaticamente pelo `yara.sh`.

---

## 3. ⚙️ Regra genérica no Manager (`local_rules.xml`) - Server Manager

No Wazuh Manager, adicione o seguinte bloco ao arquivo `/var/ossec/etc/rules/local_rules.xml`:

```xml
<group name="yara,command,">
  <rule id="108000" level="0">
    <if_sid>530</if_sid>
    <match>^[A-Z_0-9]+ /</match>
    <description>YARA generic grouping rule</description>
  </rule>

  <rule id="108001" level="12">
    <if_sid>108000</if_sid>
    <description>YARA alert: Malware detected based on rule output</description>
  </rule>
</group>
```

✅ Essa regra:

- Agrupa eventos de saída do comando YARA
- Gera alertas de severidade elevada para qualquer detecção
- Funciona com **qualquer regra `.yar` compatível**

---

## ✅ Resultado: Integração completa, modular e replicável

Com essa configuração:

- Detecta-se qualquer ameaça baseada em YARA
- Os alertas são enviados ao Manager e visíveis no Dashboard (Kibana/Wazuh UI)
- A estrutura é **portável e padronizada**, ideal para múltiplos endpoints

---