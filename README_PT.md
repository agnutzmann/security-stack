# 🧠 Open Source Security Stack – Repositório Moderno SOC & AppSec

Este repositório reúne **boas práticas**, ferramentas open source de referência e recomendações técnicas para construir uma stack de segurança da informação **totalmente open source**, enxuta, moderna e de fácil integração. O foco são ambientes de laboratório com até **20 máquinas** ou implantação inicial em projetos de clientes.

***

## 🔥 Principais Diferenciais

- **Cobertura completa:** Visibilidade e resposta para hosts, containers, rede, nuvem, SaaS, pipeline, artefatos e código.
- **Automação inteligente:** Orquestração de playbooks e resposta automática com SOAR (Shuffle).
- **Adaptação rápida:** Fácil de expandir, integrar e ajustar conforme o crescimento ou requisitos do ambiente.
- **Tudo auditável:** 100% open source, seguro e com código revisável para auditorias e compliance.

***

## 🛡️ 1. SOC / Monitoramento / Resposta a Incidentes

### Ferramentas Selecionadas
| Ferramenta        | Função Principal                                                                             | Integração                                       |
|-------------------|----------------------------------------------------------------------------------------------|--------------------------------------------------|
| **Wazuh**         | SIEM/HIDS líder, centralização de logs, agentes (host, container, cloud), compliance        | Integra Falco, Osquery, Trivy, Yara em único SIEM|
| **Security Onion**| NIDS/Sensor de rede (Suricata, Zeek, ELK)                                                   | Alertas para SIEM e CTI                          |
| **Osquery**       | Queries SQL para hunting, inventário, conformidade                                          | Integrado ao Wazuh                               |
| **Falco**         | Detecção de ameaças em runtime em containers e hosts Linux                                  | Integrado com Wazuh e Security Onion             |
| **Trivy**         | Scanner de vulnerabilidades para containers, IaC, código, secrets, SCA, SBOM                | Exporta achados para SIEM/AppSec/CTI             |
| **Yara**          | Hunting e análise forense de malware/artefatos                                              | Orquestrado por SIEM/SOAR                        |
| **OpenCTI/MISP**  | Threat Intelligence (COI, campanhas, contexto)                                              | Centraliza IOCs de SIEM e scanners               |
| **Prowler**       | Auditoria/Compliance AWS (CSPM open source referência)                                      | Exporta relatórios para SIEM/CTI/SOAR            |
| **Steampipe**     | CSPM multi-cloud/SaaS com queries SQL                                                       | Cobertura máxima de compliance                   |
| **ScoutSuite**    | Auditoria visual multi-cloud                                                                | Complementa Prowler/Steampipe                    |
| **Shuffle (SOAR)**| Orquestração/Automação (Playbooks visuais, integrações e resposta ágil a incidentes)        | Centraliza automações entre todas soluções        |

***

## 💻 2. AppSec / DevSecOps

### Ferramentas Selecionadas
| Ferramenta      | Função Principal                                                       | Integração           |
|-----------------|-----------------------------------------------------------------------|----------------------|
| **SonarQube**   | SAST referência, em profundidade para grandes projetos (bugs, vuln, code smells) | CI/CD, dashboards    |
| **Semgrep**     | SAST moderno, rápido e customizável                                   | CI/CD, scripts       |
| **OWASP ZAP**   | DAST (scan dinâmico de apps/APIs)                                     | CI/CD, alertas SOAR  |
| **Checkov**     | Segurança IaC (Terraform, CF, K8s, ARM)                              | Alertas, CI/CD       |
| **KICS**        | Segurança IaC complementar                                            | CI/CD                |
| **Clair**       | SCA para containers/imagens                                           | CI/CD, repos         |
| **Trivy**       | SCA, IaC, images, secrets                                             | Pipelines, SIEM      |
| **Dependabot**  | SCA para dependências (automação PRs no GitHub)                      | GitHub               |
| **Gitleaks/TruffleHog** | Detecção de secrets hardcoded/vazados                         | CI/CD, alertas       |

***

## ☁️ 3. CSPM & CASB

| Ferramenta        | Função Principal                           |
|-------------------|--------------------------------------------|
| **Prowler**       | Auditoria e postura AWS                    |
| **Steampipe**     | Queries multi-cloud/SaaS, compliance       |
| **ScoutSuite**    | Auditoria visual AWS/Azure/GCP             |
| **OpenCASB**      | Monitoramento SaaS e Shadow IT (opcional)  |

***

## 🧰 4. Infraestrutura Recomendada (lab até 20 máquinas)

|Host                |CPU      |RAM      |Disco     |Função                                   |
|--------------------|---------|---------|----------|-----------------------------------------|
|Security Onion      |4 vCPU   |16GB     |100GB+    |NIDS, sensor de rede (isolado)           |
|SOC/SOAR Node       |12 vCPU  |24GB     |300GB+    |SIEM, CTI, automação, Shuffle.io         |
|DevSecOps Node      |6 vCPU   |12GB     |120GB+    |AppSec scanners, pipelines CI/CD         |
|CTI Node            |6 vCPU   |12GB     |80GB+     |OpenCTI/MISP, threat intelligence        |
|CSPM Node           |2 vCPU   |4GB      |40GB+     |Prowler/Steampipe/ScoutSuite             |

**Dica:** Agrupe funções SOC/AppSec em múltiplos hosts quando recursos forem limitados, mantendo Security Onion isolado para máxima integridade de rede.

***

## 🚀 5. Instalação e Orquestração

- **Docker Compose**: Wazuh, Osquery, Falco, Trivy, Yara, Shuffle, OpenCTI/MISP, Steampipe, ScoutSuite.
- **Security Onion**: Instalação via ISO/VM dedicada.
- **AppSec**: Scanners em containers ou runners CI/CD.
- **CSPM**: Agendamento de scans via API/webhook.
- **CASB**: Deploy de OpenCASB/Steampipe conforme necessidade.

***

## ⚙️ Recomendações e Próximos Passos

1. **Comece gradualmente:** Inicie com SIEM + NIDS, criadores de logs e threat intelligence.
2. **Evolua a detecção:** Acrescente camadas de AppSec e CSPM conforme o ambiente crescer.
3. **Implemente automação:** Adote workflows básicos no SOAR/Shuffle para ganho operacional.
4. **Revise integrações e dashboards:** Garanta que todas as soluções troquem alertas e inteligência em tempo real.
5. **Automatize compliance:** Utilize APIs e playbooks para manter a conformidade sempre atualizada.
6. **Documente tudo:** Registre configurações, playbooks e lições aprendidas para evolução contínua.
7. **Adapte para produção:** Conforme novos requisitos surgirem, adicione novas automações, integrações e nodes.

***

## 🌐 Recursos Oficiais e Documentação Recomendada

- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [ISO/IEC 27001 - Annex A Controls](https://www.iso.org/isoiec-27001-information-security.html)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CISA/DISA Guidelines](https://www.cisa.gov/)
- [CSA Cloud Security Guidance](https://cloudsecurityalliance.org/)

***

## Sobre

Testes, PoC e benchmarks com as melhores ferramentas open source para segurança corporativa. Ideal para quem busca **autonomia tecnológica**, **alta cobertura**, e **evolução contínua** em ambientes SOC/AppSec modernos.

***

**Colabore:** Sugestões, issues e contribuições são bem-vindas!

***

**Desenvolvido por profissionais para profissionais. Segurança da informação, auditável e automatizada, sem vendor lock-in!**

***

**Licença:** MIT