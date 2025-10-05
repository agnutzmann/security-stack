# 🧠 Open Source Security Stacks

Este documento reúne as melhores práticas, ferramentas e recomendações para criar um stack SOC e AppSec **totalmente open source**, leve, moderno e fácil de integrar — pronto para ambientes de laboratório com até **20 máquinas** ou implantação inicial em projetos para clientes.

---

## 🛡️ 1. SOC / Threat Monitoring / Incident Response

### 🔧 Ferramentas Selecionadas

#### **Wazuh**
- SIEM/HIDS referência open source.  
- Cobertura: logs, agentes de endpoint (host/container/cloud), compliance, integração com Osquery, Falco, Trivy, Yara, Checkov/KICS.  
- Exporta incidentes/finding para **OpenCTI**.

#### **Security Onion**
- NIDS/sensor de rede (Suricata, Zeek, ELK).  
- Detecção e análise de tráfego, alertas para SIEM/CTI, integração bidirecional com outros sistemas.

#### **Osquery**
- Endpoint hunting, inventário e queries SQL para compliance/auditorias.  
- Integrado ao Wazuh.

#### **Falco**
- Runtime threat detection em containers, Kubernetes ou hosts Linux.  
- Integração com Wazuh / Security Onion.

#### **Trivy**
- Vulnerability scanner para containers, images, código-fonte, IaC, secrets, SCA e SBOM.  
- Exporta para Wazuh/AppSec/CTI.

#### **Yara**
- Análise forense e hunting de malware/artefatos.  
- Pode ser automatizado pelo SIEM/SOAR.

#### **OpenCTI & MISP**
- Threat Intelligence: coleta/enriquecimento/contexto de IOCs e campanhas.  
- Integra findings de SIEM, scanners e nuvem.

#### **Prowler**
- Auditoria/compliance/hardening **AWS** (CSPM referência open).  
- Exporta relatórios para SIEM/CTI/SOAR.

#### **Steampipe**
- CSPM multi-cloud/SaaS com queries SQL para postura, auditoria e compliance em AWS, Azure, GCP, Google Workspace, GitHub, Okta, etc.  
- Excelente complemento para máxima cobertura.

#### **ScoutSuite**
- Auditoria visual e leve de postura multi-cloud.  
- Relatórios e dashboards complementares a Prowler/Steampipe.

#### **Tracecat (SOAR)**
- Orquestração/playbooks leves e modernos, integração API/webhook/CI.  
- Automação de resposta a incidentes com visual builder.

---

### 📈 Cobertura
- Logs, telemetria, vulnerabilidades, compliance, monitoração cloud/SaaS/multicloud, runtime/behavioral, forense/hunting, threat intelligence, automação e análise de artefatos.  
- Cobertura máxima: **host, container, rede, cloud, SaaS, pipeline, artefatos e código.**

### 🔗 Integração
- **Wazuh** centraliza inputs de Falco, Osquery, Trivy e Yara.  
- **Security Onion** cobre rede e envia alertas a CTI/SOAR.  
- **Prowler**, **Steampipe** e **ScoutSuite** exportam relatórios para SIEM/CTI.  
- **OpenCTI/MISP** centraliza e enriquece IOCs.  
- **Tracecat** automatiza resposta e orquestra playbooks.

### 🎯 Resultados
- Visibilidade unificada de toda a superfície digital (cloud, on-prem, SaaS, código).  
- Alertas correlacionados, hunting automatizado e relatórios de incidentes.

### ⚖️ Overlaps
- **Prowler / Steampipe / ScoutSuite:** máxima cobertura CSPM.  
- **Wazuh × Osquery:** hunting avançado em endpoints.  
- **Falco × Trivy:** comportamento/runtime vs vulnerabilidade estática.  
- **Checkov/KICS × Trivy:** redundância para IaC.

---

## 💻 2. AppSec / DevSecOps Stack

### 🔧 Ferramentas Selecionadas

#### **SonarQube (Community Edition)**
- SAST referência: bugs, vulnerabilidades e code smells para múltiplas linguagens.  
- Ideal para projetos grandes e revisões profundas.

#### **Semgrep**
- SAST moderno: rápido, customizável, ideal para CI/CD.  
- Regras específicas por linguagem/framework.

#### **OWASP ZAP**
- DAST referência: scan dinâmico de apps e APIs.  
- Interface web/CLI e integração CI/CD.

#### **Checkov**
- Segurança de IaC: Terraform, CloudFormation, Kubernetes YAML, ARM.  
- Detecta segredos e falhas de compliance.

#### **KICS**
- Segurança de IaC complementar ao Checkov.  
- Suporte extenso a definições.

#### **Clair**
- SCA para containers/images (infra vulnerabilidades).

#### **Trivy**
- SCA/IaC/Images/Secrets: scanner multifuncional nas pipelines.

#### **Dependabot**
- SCA de dependências: alertas e PRs automáticos no GitHub.

#### **Gitleaks / TruffleHog**
- Scanners para detectar segredos vazados/hardcoded.

---

### 📈 Cobertura
- SAST, DAST, SCA, IaC security, secrets detection, compliance cloud-native, containers e pipelines CI/CD.

### 🔗 Integração
- Todos rodam integrados no pipeline (Actions/Scripts/Docker).  
- Outputs estruturados (JSON, CSV, SARIF, XML, HTML) conectam-se a dashboards e alertas.

### 🎯 Resultados
- Detecção preventiva de vulnerabilidades e falhas de configuração.  
- Compliance automatizado e integração com SIEM/CTI.

### ⚖️ Overlaps
- **SonarQube × Semgrep:** SAST com máxima cobertura e velocidade.  
- **Checkov / KICS / Trivy / Clair:** segurança IaC + containers + infra.

---

## ☁️ 3. CSPM & CASB (Cloud Posture & SaaS Security)

### 🔍 CSPM (Cloud Security Posture Management)
- **Prowler:** auditoria AWS, referência em posture/compliance.  
- **Steampipe:** queries SQL para multi-cloud/M365/SaaS.  
- **ScoutSuite:** auditoria leve/visual para AWS, Azure e GCP.

### 🧩 CASB (Cloud Access Security Broker) — *Opcional*
- **OpenCASB:** monitoração de SaaS críticos, shadow IT e compliance.  
- **Steampipe:** pode atuar como CASB leve via queries SaaS.

---

## 🧰 4. Infraestrutura Recomendada para Lab (até 20 máquinas)

| Host              | CPU      | RAM     | Disco   | Função                                     |
|-------------------|----------|---------|---------|--------------------------------------------|
| **Security Onion** | 4 vCPU   | 8–16GB  | 100GB+  | VM/baremetal com interface promíscua (NIDS) |
| **SOC Node**       | 8 vCPU   | 16GB+   | 200GB+  | SIEM, CTI, automação, orchestration         |
| **DevSecOps Node** | 4–8 vCPU | 8–16GB  | 100GB+  | Scanners AppSec e pipelines CI/CD           |
| **CTI Node**       | 4 vCPU   | 8GB     | 60GB+   | OpenCTI/MISP, Threat Hunting                |
| **CSPM Node**      | 2 vCPU   | 4GB     | 40GB+   | Prowler/Steampipe/ScoutSuite                |

> 💡 Total: **4 a 6 hosts/VMs**.  
> Com poucos recursos, agrupe SOC/AppSec em 2–3 hosts (exceto Security Onion, que deve ficar isolado).

---

## 🚀 5. Instalação e Deploy

- **Docker Compose** para Wazuh, Osquery, Falco, Trivy, Yara, Tracecat, OpenCTI/MISP, Steampipe, ScoutSuite.  
- **Security Onion** via ISO/VM.  
- **AppSec:** scanners via containers ou CI/CD runners.  
- **CSPM:** agendar Prowler/Steampipe/ScoutSuite para exportar via API/webhook.  
- **CASB:** implantar OpenCASB/Steampipe conforme necessidade.

---

## 🧩 6. Dicas Finais

- Automatize scanners AppSec a cada PR/merge/build.  
- Exporte findings críticos automaticamente para SIEM/CTI/SOAR.  
- Use dashboards nativos e APIs para hunting e relatórios.  
- Adicione **CAPE** se quiser análise dinâmica de malware (sandbox forense).

---

Essa stack cobre **todo o ciclo de vida de segurança**: código, builds, infraestrutura, cloud-native, runtime, SIEM, network, CTI, automação e resposta.  
Tudo **open source, auditável, leve e facilmente adaptável** para produção real ou múltiplos clientes.
