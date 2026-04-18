# 🚀 Quick Start - PQC Platform en 5 minutes

## Installation (< 5 min)

### Prérequis

```bash
# Vérifier que vous avez Docker et Docker Compose
docker --version      # >= 20.10
docker-compose --version  # >= 2.0
```

### Déploiement automatique

```bash
# 1. Extraire le ZIP
unzip pqc-platform.zip
cd pqc-platform

# 2. Rendre le script exécutable (Linux/Mac)
chmod +x scripts/deploy.sh

# 3. Lancer le déploiement
./scripts/deploy.sh

# OU sur Windows PowerShell
./scripts/deploy.bat
```

**C'est tout!** ✅

Le script va:
- ✅ Vérifier les prérequis
- ✅ Générer les certificats TLS
- ✅ Créer les configurations
- ✅ Télécharger les images Docker
- ✅ Démarrer tous les services
- ✅ Initialiser les bases de données
- ✅ Afficher les URL d'accès

## Accès immédiat

Après le déploiement, vous pouvez accéder à:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** | https://localhost:3000 | (auto login) |
| **API** | https://localhost:8080/api | Bearer token |
| **Vault** | http://localhost:8200 | pqc-dev-token-2024 |
| **Neo4j** | http://localhost:7474 | neo4j / (see .env) |
| **Elasticsearch** | https://localhost:9200 | elastic / (see .env) |

## Premiers pas

### 1. Uploader votre premier SBOM

```bash
# Via l'interface Web (recommandé)
# 1. Aller à https://localhost:3000
# 2. Cliquer sur "Upload SBOM"
# 3. Sélectionner un fichier SBOM (SPDX ou CycloneDX)
# 4. Attendre l'analyse

# Via l'API (alternative)
curl -X POST https://localhost:8080/api/v1/sbom/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@sbom.json" \
  -k
```

### 2. Voir l'analyse des risques

```bash
# Aller à https://localhost:3000/risk
# Ou via API:
curl https://localhost:8080/api/v1/risk/summary \
  -H "Authorization: Bearer $TOKEN" \
  -k | jq
```

### 3. Générer un plan de migration PQC

```bash
# Via l'interface:
# 1. Aller à https://localhost:3000/migration
# 2. Cliquer sur "Create Migration Plan"
# 3. Sélectionner votre SBOM
# 4. Choisir une stratégie (Hybrid, Parallel, Staged, Cutover)
# 5. Valider
```

## Commandes courantes

```bash
# Démarrer les services
docker-compose up -d

# Arrêter les services
docker-compose down

# Voir les logs
docker-compose logs -f pqc-backend

# Accéder à la base de données
docker-compose exec postgres psql -U pqc_user -d pqc_inventory

# Accéder à Neo4j
docker-compose exec neo4j cypher-shell -u neo4j

# Obtenir de l'aide
make help

# Vérifier la santé
make health
```

## Exemple SBOM

Vous avez besoin d'un SBOM pour tester? Voici un exemple minimal:

### CycloneDX JSON

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "version": 1,
  "components": [
    {
      "type": "library",
      "name": "openssl",
      "version": "3.0.0",
      "purl": "pkg:deb/debian/openssl@3.0.0?arch=amd64"
    },
    {
      "type": "library",
      "name": "libcrypto",
      "version": "1.1.1",
      "purl": "pkg:npm/crypto@1.1.1"
    }
  ]
}
```

### SPDX JSON

```json
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "2024-01-01T00:00:00Z",
    "creators": ["Tool: pqc-platform"]
  },
  "name": "My Project SBOM",
  "packages": [
    {
      "SPDXID": "SPDXRef-Package",
      "name": "openssl",
      "downloadLocation": "https://www.openssl.org",
      "filesAnalyzed": false
    }
  ]
}
```

## Troubleshooting

### "Cannot connect to Docker daemon"

```bash
# Démarrer Docker
docker daemon

# Ou vérifier qu'il est actif
docker ps
```

### "Port 8080 already in use"

```bash
# Trouver le processus qui utilise le port
lsof -i :8080

# Ou changer le port dans docker-compose.yml
sed -i 's/8080:8080/9090:8080/' docker-compose.yml
```

### "Database initialization failed"

```bash
# Nettoyer et recommencer
docker-compose down -v
./scripts/deploy.sh
```

### "Certificate verification failed"

Les certificats auto-signés génèrent un warning dans le navigateur:
- Cliquer sur "Avancé" ou "Advanced"
- Cliquer sur "Continuer vers localhost" ou "Proceed"

Ou accepter les certificats en curl:
```bash
curl -k https://localhost:8080/health
```

## Données de test

Le projet inclut des données de test:

```bash
# Charger les données de test
docker-compose exec postgres psql -U pqc_user -d pqc_inventory < /docker-entrypoint-initdb.d/test-data.sql

# Ou les générer via l'API
curl -X POST https://localhost:8080/api/v1/test/generate-data \
  -H "Authorization: Bearer $TOKEN" \
  -k
```

## Architecture rapide

```
                    Your Browser
                         |
                    https://3000
                         |
        ┌────────────────┼────────────────┐
        |                |                |
    React App      Nginx Proxy       WebSocket
        |                |                |
    localhost:3000  localhost:443    ws:8080
        |                |                |
        └────────────────┼────────────────┘
                         |
                  Backend (Go)
                 localhost:8080
                         |
        ┌────────────────┼────────────────┬────────────────┐
        |                |                |                |
    PostgreSQL         Neo4j           Redis         Elasticsearch
    :5432             :7687            :6379            :9200
```

## Prochaines étapes

Après le déploiement:

1. **Importer des SBOM réels** - tester avec vos projets
2. **Configurer l'authentification** - LDAP, OAuth2, etc.
3. **Intégrer CI/CD** - webhooks GitHub, GitLab, Jenkins
4. **Configurer le monitoring** - Prometheus, Grafana
5. **Mettre en place les backups** - base de données, certificats
6. **Déployer en Kubernetes** - voir `docs/KUBERNETES.md`

## Support

- 📖 Documentation complète: `README.md`
- 🔧 Configuration avancée: `docs/DEPLOYMENT.md`
- 🔐 Sécurité: `docs/SECURITY.md`
- 🚀 Kubernetes: `docs/KUBERNETES.md`
- 🐛 Issues: GitHub Issues
- 💬 Discussions: GitHub Discussions

## Version

```bash
make version
# Output: PQC Platform v1.0.0
```

---

**Bravo! Vous avez maintenant une plateforme PQC production-ready!** 🎉

Questions? Consultez la documentation ou créez une issue.
