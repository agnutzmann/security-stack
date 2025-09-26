
# 🛡️ Integração YARA com Wazuh

Este guia descreve os passos completos para integrar o mecanismo YARA com o Wazuh, incluindo detecção automatizada via FIM (File Integrity Monitoring) e respostas automáticas (Active Response).

---

## 📍 WAZUH SERVER

### 🔧 Regras no `local_rules.xml`

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

```xml
<group name="syscheck">
  <rule id="100300" level="1">
    <if_sid>550</if_sid>
    <field name="file">/tmp|/var/tmp|/var/www|/home</field>
    <description>File modified in sensitive directory: Sending it to Yara's scanning.</description>
  </rule>
  <rule id="100301" level="1">
    <if_sid>554</if_sid>
    <field name="file">/tmp|/var/tmp|/var/www|/home</field>
    <description>File added File in sensitive directory: Sending it to Yara's scanning</description>
  </rule>
</group>

<group name="yara">
  <rule id="108000" level="0">
    <decoded_as>yara_decoder</decoded_as>
    <description>Yara grouping rule</description>
  </rule>
  <rule id="108001" level="12">
    <if_sid>108000</if_sid>
    <match>wazuh-yara: INFO - Scan result: </match>
    <description>File "$(yara_scanned_file)" is a positive match. Yara rule: $(yara_rule)</description>
  </rule>
</group>
```

---

### 🔧 Decodificadores no `local_decoder.xml`

```bash
sudo nano /var/ossec/etc/decoders/local_decoder.xml
```

```xml
<decoder name="yara_decoder">
  <prematch>wazuh-yara:</prematch>
</decoder>

<decoder name="yara_decoder1">
  <parent>yara_decoder</parent>
  <regex>wazuh-yara: (\S+) - Scan result: (\S+) (.*)</regex>
  <order>log_type, yara_rule, yara_scanned_file</order>
</decoder>
```

---

### 🔧 Comando e Resposta Ativa no `ossec.conf`

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Adicionar dentro da tag `<ossec_config>`:

```xml
<command>
  <name>yara_linux</name>
  <executable>yara.sh</executable>
  <extra_args>-yara_path /usr/bin -yara_rules /var/ossec/ruleset/yara/rules/yara_rules.yar</extra_args>
  <timeout_allowed>no</timeout_allowed>
</command>

<active-response>
  <disabled>no</disabled>
  <command>yara_linux</command>
  <location>local</location>
  <rules_id>100300,100301</rules_id>
</active-response>
```

---

## 📍 WAZUH CLIENT (AGENTE)

### 📥 Instalação do YARA e scripts

```bash
sudo curl -SL --progress-bar https://raw.githubusercontent.com/ADORSYS-GIS/wazuh-yara/main/scripts/install.sh | sh
```

---

### ⚙️ Ativação da monitoração em diretórios críticos

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Adicionar os diretórios que serão monitorados:

```xml
<directories realtime="yes">/tmp,/var/tmp,/var/www</directories>
<directories check_all="yes" realtime="yes">/home/*/Downloads</directories>
```

---

## ✅ Resultado Esperado

- Arquivos criados ou modificados em diretórios críticos serão automaticamente escaneados com YARA.
- Detecções serão registradas em `/var/ossec/logs/active-responses.log`.
- Alertas serão enviados ao Wazuh Manager.
- Notificações de malware detectado serão exibidas no Dashboard.