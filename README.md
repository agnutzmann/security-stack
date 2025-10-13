# 🧠 Open Source Security Stack – Modern SOC & AppSec Repository

This repository brings together **best practices**, leading open source tools, and technical recommendations for building a **fully open source**, streamlined, modern, and easily integrated security stack. The focus is on lab environments with up to **20 machines** or for initial deployment in client projects.

***

## 🔥 Key Differentials

- **Full Coverage:** Visibility and response for hosts, containers, network, cloud, SaaS, pipeline, artifacts, and code.
- **Intelligent Automation:** Playbook orchestration and automatic response with SOAR (Shuffle).
- **Rapid Adaptation:** Easy to expand, integrate, and adjust as the environment grows or requirements evolve.
- **Fully auditable:** 100% open source, secure, and reviewable code for audits and compliance.

***

## 🛡️ 1. SOC / Monitoring / Incident Response

### Selected Tools
| Tool             | Main Function                                                                              | Integration                                      |
|------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------|
| Wazuh            | Leading SIEM/HIDS, centralized logging, agents (host, container, cloud), compliance       | Integrates Falco, Osquery, Trivy, Yara into SIEM |
| Security Onion   | NIDS/Network sensor (Suricata, Zeek, ELK)                                                 | Alerts to SIEM and CTI                           |
| Osquery          | SQL queries for hunting, inventory, compliance                                            | Integrated with Wazuh                            |
| Falco            | Runtime threat detection for containers and Linux hosts                                   | Integrated with Wazuh and Security Onion         |
| Trivy            | Vulnerability scanner for containers, IaC, code, secrets, SCA, SBOM                       | Exports findings to SIEM/AppSec/CTI              |
| Yara             | Forensic artifact/malware hunting and analysis                                            | Orchestrated by SIEM/SOAR                        |
| OpenCTI/MISP     | Threat Intelligence (COI, campaigns, context)                                             | Centralizes IOCs from SIEM and scanners          |
| Prowler          | AWS audit/compliance (open source CSPM reference)                                         | Reports to SIEM/CTI/SOAR                         |
| Steampipe        | Multi-cloud/SaaS CSPM with SQL queries                                                    | Maximum compliance coverage                      |
| ScoutSuite       | Visual multi-cloud audit                                                                  | Complements Prowler/Steampipe                    |
| Shuffle (SOAR)   | Orchestration/automation (visual playbooks, integrations, rapid incident response)        | Centralizes automations                          |

***

## 💻 2. AppSec / DevSecOps

### Selected Tools
| Tool           | Main Function                                                   | Integration         |
|----------------|-----------------------------------------------------------------|---------------------|
| SonarQube      | Reference SAST, in-depth for large projects (bugs, vulns, code smells) | CI/CD, dashboards   |
| Semgrep        | Modern, fast, customizable SAST                                 | CI/CD, scripts      |
| OWASP ZAP      | DAST (dynamic scanning for apps/APIs)                          | CI/CD, SOAR alerts  |
| Checkov        | IaC security (Terraform, CF, K8s, ARM)                         | Alerts, CI/CD       |
| KICS           | Complementary IaC security                                      | CI/CD               |
| Clair          | SCA for containers/images                                       | CI/CD, repos        |
| Trivy          | SCA, IaC, images, secrets                                       | Pipelines, SIEM     |
| Dependabot     | Dependency SCA (automated GitHub PRs)                          | GitHub              |
| Gitleaks/TruffleHog | Detection of hardcoded/leaked secrets                      | CI/CD, alerts       |

***

## ☁️ 3. CSPM & CASB

| Tool        | Main Function                 |
|-------------|------------------------------|
| Prowler     | AWS auditing/posture          |
| Steampipe   | Multi-cloud/SaaS queries, compliance |
| ScoutSuite  | Visual audit AWS/Azure/GCP    |
| OpenCASB    | SaaS/shadow IT monitoring (optional) |

***

## 🧰 4. Recommended Infrastructure (lab up to 20 machines)

|Host                |CPU    |RAM    |Disk    |Function                              |
|--------------------|-------|-------|--------|--------------------------------------|
|Security Onion      |4 vCPU |16GB   |100GB+  |NIDS, network sensor (isolated)       |
|SOC/SOAR Node       |12 vCPU|24GB   |300GB+  |SIEM, CTI, automation, Shuffle.io     |
|DevSecOps Node      |6 vCPU |12GB   |120GB+  |AppSec scanners, CI/CD pipelines      |
|CTI Node            |6 vCPU |12GB   |80GB+   |OpenCTI/MISP, threat intelligence     |
|CSPM Node           |2 vCPU |4GB    |40GB+   |Prowler/Steampipe/ScoutSuite          |

**Tip:** Group SOC/AppSec roles on multiple hosts if resources are limited, keeping Security Onion isolated for maximum network integrity.

***

## 🚀 5. Installation & Orchestration

- **Docker Compose:** Wazuh, Osquery, Falco, Trivy, Yara, Shuffle, OpenCTI/MISP, Steampipe, ScoutSuite.
- **Security Onion:** Installation via dedicated ISO/VM.
- **AppSec:** Scanners via containers or CI/CD runners.
- **CSPM:** Scan scheduling via API/webhook.
- **CASB:** Deploy OpenCASB/Steampipe as needed.

***

## ⚙️ Recommendations & Next Steps

1. **Start gradually:** Begin with SIEM + NIDS, log collectors, and threat intelligence.
2. **Advance detection:** Add AppSec and CSPM layers as the environment grows.
3. **Implement automation:** Adopt basic SOAR/Shuffle workflows for operational gains.
4. **Review integrations & dashboards:** Ensure all solutions exchange alerts and intelligence in real time.
5. **Automate compliance:** Use APIs and playbooks to keep compliance always accurate.
6. **Document everything:** Register configs, playbooks, and lessons for continuous evolution.
7. **Adapt for production:** As new requirements arise, add automations, integrations, and nodes.

***

## 🌐 Official Resources & Recommended Documentation

- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [ISO/IEC 27001 - Annex A Controls](https://www.iso.org/isoiec-27001-information-security.html)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CISA/DISA Guidelines](https://www.cisa.gov/)
- [CSA Cloud Security Guidance](https://cloudsecurityalliance.org/)

***

## About

Tests, PoCs, and benchmarks with the best open source tools for corporate security. Ideal for those seeking **technological autonomy**, **high coverage**, and **continuous evolution** in modern SOC/AppSec environments.

***

**Contribute:** Suggestions, issues, and contributions are welcome!

***

**Developed by professionals for professionals. Auditable and automated security, with no vendor lock-in!**

***

**License:** MIT