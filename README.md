```markdown
# Open Source SOC & AppSec Stack — Guia Completo para Laboratório Moderno

Este documento traz tudo sobre as stacks SOC e AppSec modernas, 100% open source, leves e altamente integráveis, proporcionando máxima cobertura para ambientes até **20 máquinas**. Segue com orientações completas de implantação, integração, hardware, funções e overlaps, pronto para uso prático e distribuição para clientes.

---

## 1. SOC/Threat Monitoring/Incident Response Stack

### **Ferramentas Selecionadas**

- **Wazuh**
  - SIEM/HIDS líder open source: monitora logs, eventos, compliance, cloud, containers e endpoints.
  - Integração nativa: Osquery, Falco, Trivy, Yara, Checkov/KICS.
  - Exporta alertas/findings para OpenCTI (CTI).

- **Security Onion**
  - NIDS/Sensor de Rede: detecção/análise de tráfego, integra Suricata, Zeek, ELK.
  - Exporta eventos para OpenCTI, correlaciona ataques de rede com findings do SIEM.

- **Osquery**
  - Query e hunting em endpoints: inventário, compliance, auditoria e TTPs via SQL.
  - Integrado ao Wazuh.

- **Falco**
  - Runtime detection (containers/K8s/hosts): flag de execuções/processos suspeitos, syscalls, comportamentos indesejados.
  - Integra com Wazuh/Security Onion, gera alertas para CTI/SOAR.

- **Trivy**
  - Vulnerability scanner rápido para containers, imagens, arquivos, código-fonte, IaC e secrets.
  - Exporta findings para Wazuh/AppSec/CTI.

- **Yara**
  - Hunting/forense de malware: busca padrões, strings e artefatos em arquivos/processos.
  - Pode ser rodado pelos analistas ou por scripts automáticos disparados pelo SIEM/SOAR.

- **OpenCTI + MISP**
  - Plataforma de Threat Intelligence e compartilhamento de IOCs/campanhas.
  - Recebe findings de SIEM, scanners, Prowler/AppSec e eventos para enriquecimento/contexto.

- **Prowler**  
  - Auditoria, compliance e hardening **AWS** (CSPM referência open para AWS, cobertura máxima).
  - Exporta relatórios/falhas para SIEM/CTI/SOAR.

- **Steampipe**  
  - CSPM multi-cloud/SaaS, cobertura para AWS, Azure, GCP, Google Workspace, Okta, GitHub, etc.
  - Permite auditors/compliance personalizadas em SQL, dashboards, integra CI/CD.
  - Complementa o Prowler cobrindo múltiplos fornecedores, SaaS e postura DevOps.

- **ScoutSuite**  
  - Auditoria de postura para AWS, Azure, GCP, Alibaba.
  - Ferramenta leve, interface web/CLI, reports multi-cloud, cobre ângulos que Prowler e Steampipe podem não cobrir.

- **Tracecat (SOAR)**
  - Automação/playbooks leves, integra todos os demais (API/webhook/YAML), orquestra resposta, notificação, enrichments e mitigação.

---

### **Cobertura**

- Logs, telemetria, compliance, vulnerabilidade, runtime/behavioral, hunting, tráfego de rede, cloud posture (AWS/multicloud/SaaS), threat intelligence, automação de resposta, forense e análise de artefatos.
- Cobertura total: host, container, rede, cloud, SaaS, artefatos, código.

---

### **Integração**

- **Wazuh** centraliza Falco, Osquery, Trivy, Yara (via scripts ou módulo).
- **Security Onion** focado em rede, exporta para CTI/SOAR.
- **Prowler**, **Steampipe**, **ScoutSuite** rodam em schedule/pipelines, relatórios findings enviados por API/script para Wazuh, OpenCTI ou dashboards centralizados.
- **Trivy** findings alimentam SIEM e CTI.
- **Tracecat** orquestra automação.
- **OpenCTI/MISP** centralizam inteligência, enriquecimento e hunting.

---

### **Resultados**

- Detecção de ameaças (rede, host, cloud, containers, SaaS)
- Alertas correlacionados contextuais (via CTI)
- Hunting de artefatos/processos suspeitos (Yara)
- Compliance/hardening cloud/multicloud/SaaS
- Resposta orquestrada e automatizada

---

### **Overlaps**

- **Prowler, Steampipe, ScoutSuite** em CSPM: Juntas garantem cobertura máxima em AWS, multi-cloud, SaaS.
- **Falco x Trivy:** Falco cobre runtime/execuções, Trivy cobre vulnerabilidade/SCA/secrets de arquivos e imagens.
- **Osquery x Wazuh:** Osquery para advanced queries, Wazuh centraliza alertas/eventos.

---

## 2. AppSec/DevSecOps Stack

### **Ferramentas Selecionadas**

- **SonarQube (Community Edition)**
  - SAST referência, análise estática em múltiplas linguagens. Detecção de bugs, vulnerabilidades, alguns segredos, dívidas técnicas.

- **Semgrep**
  - SAST moderno: feedback rápido, regras customizadas, cobertura de linguagens modernas e padrões inseguros.

- **OWASP ZAP**
  - DAST padrão: scan dinâmico, API/web fuzzing, integração CI/CD, exporta resultados para SIEM/AppSec dashboards.

- **Checkov**
  - IaC Security: focado em Terraform, CloudFormation, Kubernetes YAML, ARM, detection de exposures/secrets, compliance.

- **KICS**
  - IaC Security extra, cobre ainda mais tipos de arquivo/config/language.

- **Clair**
  - SCA open para containers/images infra. Complementa Trivy em scanners.

- **Trivy**
  - SCA para containers, código, IaC, ficheiros, secrets; SBOM.

- **Dependabot**
  - SCA em dependências, automação GitHub, alertas automáticos.

- **Gitleaks/TruffleHog**
  - Detecção especializada de segredos em código/repos, complementa SAST/Trivy.

---

### **Cobertura**

- SAST, DAST, IAST (via Semgrep/possível AppSensor), SCA de containers/dependências/IaC, secrets leaks, vulnerabilidades containers, compliance na cloud.

---

### **Integração**

- **CI/CD pipelines:** SonarQube, Semgrep, Trivy, Checkov, KICS, OWASP ZAP, Gitleaks rodam em jobs/container, outputs para dashboards/SIEM/CTI.
- **AppSec dashboards:** Outputs reunidos, automação de findings em GitHub/CTI.
- **Outputs:** Relatórios JSON, CSV ou API/export para ingestão nos sistemas SOC, CTI e SOAR.

---

### **Resultados**

- Detecção preventiva de vulnerabilidades, falhas e segredos.
- Reports automatizados, correções contínuas por Dependabot.
- Compliance DevSecOps multi-cloud/app.

---

### **Overlaps**

- **SonarQube/Semgrep:** Ambos são SAST, juntos ampliam detecção.
- **Checkov/KICS/Trivy/Clair:** Cobrem áreas de IaC e containers, podem sobrepor alguns findings para máxima cobertura cloud-native.

---

## 3. CSPM & CASB (Cloud Posture & SaaS Security)

### **CSPM (Cloud Security Posture Management)**
- **Prowler:** Top para AWS.
- **Steampipe:** Multi-cloud/SaaS, compliance queries custom, dashboards, integra CI/CD.
- **ScoutSuite:** Auditoria multi-cloud, reports visualizáveis, complementa coverage de posture/hardening.

### **CASB (Cloud Access Security Broker)**
- **OpenCASB:** *Opcional*, implemente apenas se clientes precisarem de visibilidade/controle forte sobre SaaS (Drive, O365, Dropbox, etc.).
- **Steampipe:** Pode ser usado para queries SaaS e postura de serviços conhecidos, servindo como CASB leve.

---

## 4. Infraestrutura e Deploy

### **Hosts Recomendados (Lab para até 20 máquinas)**

| Host            | CPU      | RAM      | Disco     | Deploy                                     |
|-----------------|----------|----------|-----------|--------------------------------------------|
| Security Onion  | 4 vCPU   | 8–16GB   | 100GB+    | VM ou baremetal, interface rede promíscua   |
| SOC Node        | 8 vCPU   | 16GB+    | 200GB+    | Docker Compose/K8s, armazenamento persistente|
| DevSecOps Node  | 4–8 vCPU | 8–16GB   | 100GB+    | Docker Compose, runners para scanners       |
| CTI Node        | 4 vCPU   | 8GB      | 60GB+     | Docker Compose/OpenCTI-separated container  |
| CSPM Node       | 2 vCPU   | 4GB      | 40GB+     | Prowler/Steampipe/ScoutSuite/sched scans   |

Total mínimo:  
- **4 a 6 hosts/VMs** para máxima separação e performance; 2-3 se usar heavy containerização em lab.

---

## 5. Instalação/Deploy

- **SOC/CTI/CSPM:** Docker Compose para Wazuh, Osquery, Falco, Trivy, Tracecat, OpenCTI+MISP, Steampipe, ScoutSuite.  
- **Security Onion:** VM/dedicado.
- **AppSec:** Containers nos nodes CI/CD.
- **CSPM:** Prowler/Steampipe/ScoutSuite rodando via cron/jobs, outputs para SIEM/CTI/SOAR.
- **CASB:** OpenCASB/Steampipe rodando isolado, integrado se necessário.

---

**Com isso, sua stack cobre todo ambiente cloud, SaaS, infra, app, pipeline, rede e endpoint — tudo open source, moderno e auditável!**
```