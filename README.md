# 🚀 PQC Transition & Crypto Inventory Platform

**Une plateforme complète, on-premise, pour gérer la transition vers la cryptographie post-quantique.**

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation rapide](#installation-rapide)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [API Documentation](#api-documentation)
- [Modules](#modules)
- [Sécurité](#sécurité)
- [Troubleshooting](#troubleshooting)
- [Contribution](#contribution)

## 🎯 Vue d'ensemble

La **PQC Transition & Crypto Inventory Platform** est une application d'entreprise déployable on-premise pour:

1. ✅ **Inventorier** les algorithmes cryptographiques utilisés (SBOM/CBOM)
2. ✅ **Analyser** les risques d'exposition aux attaques quantiques
3. ✅ **Planifier** la migration vers des algorithmes post-quantiques
4. ✅ **Suivre** la progression de la transition PQC
5. ✅ **Générer** des rapports de conformité (NIST, ANSSI, ETSI)
6. ✅ **Intégrer** avec les systèmes existants (CI/CD, CMDB, SIEM)

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│          Frontend (React)                │
│  Dashboard · SBOM Importer · Analyzer   │
└────────────────┬────────────────────────┘
                 │ HTTPS
┌────────────────▼────────────────────────┐
│  API Gateway (Nginx) + Auth             │
│  Rate Limiting · Zero Trust             │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Backend Services (Go Microservices)    │
│  • SBOM Engine      • Risk Analyzer     │
│  • CBOM Engine      • Migration Planner │
│  • Reporting        • Integration Layer │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼───┐  ┌────▼─────┐  ┌──▼──────┐
│   DB  │  │  Graph   │  │  Cache  │
│ (PG)  │  │ (Neo4j)  │  │(Redis)  │
└───────┘  └──────────┘  └─────────┘

Security Layer: Vault · TLS · RBAC · Audit Logs
```

**Stack Technique:**

- **Backend**: Go 1.21 (Echo framework)
- **Frontend**: React 18 + TypeScript
- **DB**: PostgreSQL 15 + Neo4j 5.13
- **Cache**: Redis 7.2
- **Secrets**: HashiCorp Vault
- **Logs**: Elasticsearch 8.10 (WORM)
- **API Gateway**: Nginx 1.25
- **Orchestration**: Docker Compose / Kubernetes

## 📦 Prérequis

- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0
- **OpenSSL**: >= 1.1.1
- **Memory**: Minimum 8GB RAM
- **Disk**: Minimum 50GB pour les données
- **Network**: HTTPS (TLS 1.3)

### Vérifier les prérequis:

```bash
docker --version      # Docker version
docker-compose --version
openssl version
free -h              # Vérifier RAM disponible
df -h /              # Vérifier espace disque
```

## 🚀 Installation rapide

### 1. Clone ou télécharge le projet

```bash
cd /opt
unzip pqc-platform.zip
cd pqc-platform
```

### 2. Rends le script exécutable

```bash
chmod +x scripts/deploy.sh
```

### 3. Déploie la plateforme

```bash
./scripts/deploy.sh
```

Le script va automatiquement:
- ✅ Vérifier les prérequis
- ✅ Générer les certificats TLS
- ✅ Créer le fichier `.env` avec mots de passe sécurisés
- ✅ Démarrer tous les conteneurs Docker
- ✅ Initialiser les bases de données
- ✅ Exécuter les health checks
- ✅ Afficher les informations d'accès

### 4. Accède à la plateforme

```
Frontend:  https://localhost:3000
API:       https://localhost:8080/api
Vault:     http://localhost:8200
Neo4j:     http://localhost:7474
```

## ⚙️ Configuration

### Variables d'environnement (`.env`)

Le fichier `.env` est généré automatiquement. Les paramètres importants:

```bash
# Database
DB_PASSWORD=...                    # PostgreSQL password
NEO4J_PASSWORD=...                 # Neo4j password
ELASTIC_PASSWORD=...               # Elasticsearch password
REDIS_PASSWORD=...                 # Redis password

# Security
JWT_SECRET=...                     # JWT signing key
JWT_EXPIRATION_HOURS=24            # Token validity
ENABLE_RBAC=true                   # Role-based access control

# PQC Settings
RECOMMENDED_PQC_KEM=ML-KEM-768    # Recommendation
RECOMMENDED_PQC_SIGNATURE=ML-DSA-65
PQC_MIGRATION_DEADLINE_YEARS=3     # Migration timeline

# Compliance
ANSSI_COMPLIANCE_MODE=true
HDS_COMPLIANCE_MODE=true
```

### Configuration Nginx

Fichier: `config/nginx/nginx.conf`

- SSL/TLS 1.3 minimum
- HTTP/2 support
- Rate limiting configurable
- Security headers
- GZIP compression

### Configuration PostgreSQL

Fichier: `config/postgres/init.sql`

- Tables SBOM/CBOM
- Triggers audit immuables
- Vue risk_summary
- Indexes optimisés

## 📚 Utilisation

### Importer un SBOM

```bash
curl -X POST https://localhost:8080/api/v1/sbom/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@sbom.json"
```

### Analyser les risques

```bash
curl https://localhost:8080/api/v1/risk/score/sbom-id \
  -H "Authorization: Bearer $TOKEN"
```

Réponse:
```json
{
  "overall_risk_level": "high",
  "vulnerable_components": 15,
  "pqc_ready_components": 3,
  "quantum_vulnerability_score": 0.72,
  "recommendation": "Migrer RSA-2048 vers ML-DSA-65"
}
```

### Générer un rapport de conformité

```bash
curl https://localhost:8080/api/v1/reports/compliance/sbom-id \
  -H "Authorization: Bearer $TOKEN" \
  > report.pdf
```

## 🔌 API Documentation

### Endpoints principaux

#### SBOM

| Methode | Endpoint | Description |
|---------|----------|-------------|
| POST   | `/api/v1/sbom/upload` | Importer un SBOM |
| GET    | `/api/v1/sbom/:id` | Récupérer un SBOM |
| GET    | `/api/v1/sbom` | Lister tous les SBOM |
| DELETE | `/api/v1/sbom/:id` | Supprimer un SBOM |

#### CBOM

| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET    | `/api/v1/cbom/:sbomId` | Récupérer le CBOM |
| POST   | `/api/v1/cbom/:sbomId/analyze` | Analyser le CBOM |
| GET    | `/api/v1/cbom/:sbomId/algorithms` | Lister les algos |

#### Risk Analysis

| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET    | `/api/v1/risk/score/:sbomId` | Score de risque |
| GET    | `/api/v1/risk/summary` | Résumé des risques |
| POST   | `/api/v1/risk/rescan` | Relancer l'analyse |

#### Migration Planning

| Methode | Endpoint | Description |
|---------|----------|-------------|
| POST   | `/api/v1/migration/plan` | Créer un plan |
| GET    | `/api/v1/migration/plan/:id` | Récupérer le plan |
| PUT    | `/api/v1/migration/plan/:id` | Mettre à jour |
| GET    | `/api/v1/migration/recommendations` | Recommandations PQC |

#### Reporting

| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET    | `/api/v1/reports/compliance/:sbomId` | Rapport compliance |
| GET    | `/api/v1/reports/executive` | Rapport exécutif |
| POST   | `/api/v1/reports/export` | Exporter (PDF/JSON) |

## 🧩 Modules

### 1. SBOM Engine
- Parse SPDX 2.3, CycloneDX 1.4
- Extraction dépendances
- Détection vulnérabilités (CVE)
- Mapping composants

### 2. CBOM Engine
- Détection automatique: RSA, ECC, AES, SHA, TLS, etc.
- Analyse niveau cryptographique
- Identification du niveau NIST
- Mapping usage (encryption, signature, hash)

### 3. PQC Risk Analyzer
- Scoring 0-1 pour vulnérabilité quantique
- Mapping NIST Quantum Security Levels
- Identification algorithmes obsolètes
- Recommendations d'upgrade

### 4. Migration Planner
- Recommandations: ML-KEM-768, ML-DSA-65
- Stratégies: Hybrid, Parallel, Staged, Cutover
- Roadmap génération
- Gestion crypto-agility

### 5. Dashboard & Reporting
- Vue executive (score global)
- Vue technique (par service)
- Export: PDF, JSON, XML
- Conformité: NIST, ANSSI, ETSI, HDS, NIS2

### 6. Integration Layer
- Webhooks GitHub, GitLab
- APIs Jenkins, ServiceNow
- SIEM: Splunk, ELK
- Kubernetes admission controller

## 🔐 Sécurité

### Zero Trust Internal Architecture

```
┌─ Authentication (Multi-factor)
├─ Authorization (RBAC/ABAC)
├─ Encryption in Transit (TLS 1.3)
├─ Encryption at Rest (AES-256)
├─ Secrets Management (Vault)
├─ Audit Logs (Immutable, WORM)
├─ Rate Limiting
├─ Input Validation (Schema)
└─ Output Encoding
```

### Certifications de sécurité

- ✅ TLS 1.3 obligatoire
- ✅ HMAC-SHA256 pour signatures
- ✅ AES-256-GCM pour chiffrement
- ✅ PBKDF2 pour dérivation clés
- ✅ Audit log immuables (Elasticsearch WORM)
- ✅ Secrets jamais loggés
- ✅ Rotation clés recommandée tous les 90 jours

### Conformité

- **NIST SP 800-235**: PQC Migration Recommendations
- **ANSSI**: Recommandations cryptographiques
- **ETSI QKD**: Quantum Key Distribution
- **HDS**: Hébergement Données Santé
- **NIS2**: Network Information Systems Security
- **RGPD**: Protection données personnelles

## 🛠️ Commandes utiles

### Démarrer

```bash
./scripts/deploy.sh                    # Déploiement complet
docker-compose up -d                   # Démarrer services
docker-compose ps                      # Status services
```

### Arrêter

```bash
docker-compose down                    # Arrêter tout
docker-compose down -v                 # Arrêter + supprimer volumes
```

### Logs

```bash
docker-compose logs -f pqc-backend     # Logs backend
docker-compose logs -f pqc-frontend    # Logs frontend
docker-compose logs pqc-postgres       # Logs PostgreSQL
```

### Database

```bash
docker-compose exec postgres psql -U pqc_user -d pqc_inventory
docker-compose exec neo4j cypher-shell
```

### Vault

```bash
curl http://localhost:8200/v1/sys/health  # Health check
./scripts/init-vault.sh                    # Initialiser Vault
```

## 🐛 Troubleshooting

### Les services ne démarrent pas

```bash
# Vérifier les logs
docker-compose logs

# Vérifier les ports occupés
lsof -i :8080
lsof -i :5432
lsof -i :7687

# Redémarrer proprement
docker-compose down
docker system prune
./scripts/deploy.sh
```

### PostgreSQL n'initialise pas

```bash
# Vérifier le volume
docker volume ls | grep pqc

# Supprimer et recréer
docker-compose down -v
./scripts/deploy.sh
```

### Certificats TLS expirés

```bash
# Régénérer
rm -f config/tls/server.*
./scripts/deploy.sh
```

### Problèmes de mémoire

```bash
# Vérifier la RAM disponible
free -h

# Réduire la RAM des services
# Dans docker-compose.yml:
# services:
#   pqc-backend:
#     mem_limit: 2g
```

## 📖 Documentation supplémentaire

- **API**: Voir `docs/API.md`
- **Deployment**: Voir `docs/DEPLOYMENT.md`
- **PQC Migration**: Voir `docs/PQC_MIGRATION.md`
- **Architecture**: Voir `docs/ARCHITECTURE.md`

## 🤝 Contribution

Les contributions sont bienvenues! Voir `CONTRIBUTING.md`

## 📄 License

MIT License - Voir `LICENSE`

## 📞 Support

- **Issues**: GitHub Issues
- **Email**: support@pqc-platform.io
- **Documentation**: https://docs.pqc-platform.io

---

**Dernière mise à jour**: 2024
**Version**: 1.0.0
**Status**: Production Ready ✅
# rg_CBOM
