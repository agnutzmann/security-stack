Of course. Here is the English translation of the document.

# 🧠 Open Source Security Stacks

This document gathers best practices, tools, and recommendations for creating a **fully open-source**, lightweight, modern, and easy-to-integrate SOC and AppSec stack—ready for lab environments with up to **20 machines** or for initial deployment in client projects.

---

## 🛡️ 1. SOC / Threat Monitoring / Incident Response

### 🔧 Selected Tools

#### **Wazuh**
- The open-source reference for SIEM/HIDS.
- Coverage: logs, endpoint agents (host/container/cloud), compliance, integration with Osquery, Falco, Trivy, Yara, Checkov/KICS.
- Exports incidents/findings to **OpenCTI**.

#### **Security Onion**
- NIDS/network sensor (Suricata, Zeek, ELK).
- Traffic detection and analysis, alerts for SIEM/CTI, bidirectional integration with other systems.

#### **Osquery**
- Endpoint hunting, inventory, and SQL queries for compliance/audits.
- Integrated with Wazuh.

#### **Falco**
- Runtime threat detection in containers, Kubernetes, or Linux hosts.
- Integration with Wazuh / Security Onion.

#### **Trivy**
- Vulnerability scanner for containers, images, source code, IaC, secrets, SCA, and SBOM.
- Exports to Wazuh/AppSec/CTI.

#### **Yara**
- Forensic analysis and hunting for malware/artifacts.
- Can be automated by the SIEM/SOAR.

#### **OpenCTI & MISP**
- Threat Intelligence: collection/enrichment/context for IOCs and campaigns.
- Integrates findings from SIEM, scanners, and the cloud.

#### **Prowler**
- **AWS** auditing/compliance/hardening (the open-source CSPM reference).
- Exports reports to SIEM/CTI/SOAR.

#### **Steampipe**
- Multi-cloud/SaaS CSPM with SQL queries for posture, auditing, and compliance in AWS, Azure, GCP, Google Workspace, GitHub, Okta, etc.
- An excellent complement for maximum coverage.

#### **ScoutSuite**
- Lightweight, visual multi-cloud posture audit.
- Complementary reports and dashboards to Prowler/Steampipe.

#### **Tracecat (SOAR)**
- Lightweight and modern orchestration/playbooks, API/webhook/CI integration.
- Incident response automation with a visual builder.

---

### 📈 Coverage
- Logs, telemetry, vulnerabilities, compliance, cloud/SaaS/multicloud monitoring, runtime/behavioral, forensics/hunting, threat intelligence, automation, and artifact analysis.
- Maximum coverage: **host, container, network, cloud, SaaS, pipeline, artifacts, and code.**

### 🔗 Integration
- **Wazuh** centralizes inputs from Falco, Osquery, Trivy, and Yara.
- **Security Onion** covers the network and sends alerts to CTI/SOAR.
- **Prowler**, **Steampipe**, and **ScoutSuite** export reports to SIEM/CTI.
- **OpenCTI/MISP** centralizes and enriches IOCs.
- **Tracecat** automates responses and orchestrates playbooks.

### 🎯 Results
- Unified visibility across the entire digital surface (cloud, on-prem, SaaS, code).
- Correlated alerts, automated hunting, and incident reports.

### ⚖️ Overlaps
- **Prowler / Steampipe / ScoutSuite:** maximum CSPM coverage.
- **Wazuh × Osquery:** advanced endpoint hunting.
- **Falco × Trivy:** behavioral/runtime vs. static vulnerability.
- **Checkov/KICS × Trivy:** redundancy for IaC.

---

## 💻 2. AppSec / DevSecOps Stack

### 🔧 Selected Tools

#### **SonarQube (Community Edition)**
- Reference SAST: bugs, vulnerabilities, and code smells for multiple languages.
- Ideal for large projects and in-depth reviews.

#### **Semgrep**
- Modern SAST: fast, customizable, ideal for CI/CD.
- Language/framework-specific rules.

#### **OWASP ZAP**
- Reference DAST: dynamic scanning of apps and APIs.
- Web/CLI interface and CI/CD integration.

#### **Checkov**
- IaC Security: Terraform, CloudFormation, Kubernetes YAML, ARM.
- Detects secrets and compliance failures.

#### **KICS**
- IaC security complementary to Checkov.
- Extensive support for definitions.

#### **Clair**
- SCA for containers/images (infra vulnerabilities).

#### **Trivy**
- SCA/IaC/Images/Secrets: a multi-functional scanner in pipelines.

#### **Dependabot**
- Dependency SCA: alerts and automatic PRs on GitHub.

#### **Gitleaks / TruffleHog**
- Scanners to detect leaked/hardcoded secrets.

---

### 📈 Coverage
- SAST, DAST, SCA, IaC security, secrets detection, cloud-native compliance, containers, and CI/CD pipelines.

### 🔗 Integration
- All run integrated into the pipeline (Actions/Scripts/Docker).
- Structured outputs (JSON, CSV, SARIF, XML, HTML) connect to dashboards and alerts.

### 🎯 Results
- Preventive detection of vulnerabilities and misconfigurations.
- Automated compliance and integration with SIEM/CTI.

### ⚖️ Overlaps
- **SonarQube × Semgrep:** SAST with maximum coverage and speed.
- **Checkov / KICS / Trivy / Clair:** IaC + containers + infra security.

---

## ☁️ 3. CSPM & CASB (Cloud Posture & SaaS Security)

### 🔍 CSPM (Cloud Security Posture Management)
- **Prowler:** AWS auditing, the reference in posture/compliance.
- **Steampipe:** SQL queries for multi-cloud/M365/SaaS.
- **ScoutSuite:** lightweight/visual auditing for AWS, Azure, and GCP.

### 🧩 CASB (Cloud Access Security Broker) — *Optional*
- **OpenCASB:** monitoring of critical SaaS, shadow IT, and compliance.
- **Steampipe:** can act as a lightweight CASB via SaaS queries.

---

## 🧰 4. Recommended Lab Infrastructure (up to 20 machines)

| Host              | CPU      | RAM     | Disk   | Role                                       |
|-------------------|----------|---------|--------|--------------------------------------------|
| **Security Onion** | 4 vCPU   | 8–16GB  | 100GB+ | VM/baremetal with a promiscuous interface (NIDS) |
| **SOC Node** | 8 vCPU   | 16GB+   | 200GB+ | SIEM, CTI, automation, orchestration       |
| **DevSecOps Node** | 4–8 vCPU | 8–16GB  | 100GB+ | AppSec scanners and CI/CD pipelines        |
| **CTI Node** | 4 vCPU   | 8GB     | 60GB+  | OpenCTI/MISP, Threat Hunting               |
| **CSPM Node** | 2 vCPU   | 4GB     | 40GB+  | Prowler/Steampipe/ScoutSuite               |

> 💡 Total: **4 to 6 hosts/VMs**.
> With limited resources, group SOC/AppSec on 2–3 hosts (except for Security Onion, which should remain isolated).

---

## 🚀 5. Installation and Deployment

- **Docker Compose** for Wazuh, Osquery, Falco, Trivy, Yara, Tracecat, OpenCTI/MISP, Steampipe, ScoutSuite.
- **Security Onion** via ISO/VM.
- **AppSec:** scanners via containers or CI/CD runners.
- **CSPM:** schedule Prowler/Steampipe/ScoutSuite to export via API/webhook.
- **CASB:** deploy OpenCASB/Steampipe as needed.

---

## 🧩 6. Final Tips

- Automate AppSec scanners on every PR/merge/build.
- Automatically export critical findings to SIEM/CTI/SOAR.
- Use native dashboards and APIs for hunting and reporting.
- Add **CAPE** if you want dynamic malware analysis (forensic sandbox).

---

This stack covers the **entire security lifecycle**: code, builds, infrastructure, cloud-native, runtime, SIEM, network, CTI, automation, and response.
All **open-source, auditable, lightweight, and easily adaptable** for real production or multiple clients.