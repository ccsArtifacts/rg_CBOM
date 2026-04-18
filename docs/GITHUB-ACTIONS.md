# GitHub Actions - Complete Testing & CI/CD Guide

## 📋 Overview

La plateforme PQC est configurée avec **5 workflows GitHub Actions** pour:

✅ **Backend Tests** - Tests Go, lint, security scan  
✅ **Frontend Tests** - Tests React, TypeScript, Jest  
✅ **Integration Tests** - Full stack testing avec Docker  
✅ **Security Scan** - SAST, secrets, dépendances  
✅ **Quality & Release** - Code quality, releases, Docker publish  

---

## 🚀 Quick Setup

### 1. Fork le repository sur GitHub

```bash
git clone https://github.com/YOUR-USERNAME/pqc-platform.git
cd pqc-platform
```

### 2. Activer GitHub Actions

```
Settings → Actions → Allow all actions and reusable workflows
```

### 3. Configurer les secrets (optionnel)

```
Settings → Secrets and variables → Actions → New repository secret
```

Secrets recommandés:

```
SNYK_TOKEN          → Token Snyk security (optionnel)
SONAR_TOKEN         → SonarQube token (optionnel)
CODECOV_TOKEN       → Codecov token (optionnel)
```

### 4. Faire un commit et voir les workflows

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

Allez à l'onglet **Actions** de votre repository pour voir les workflows en action!

---

## 🔄 Workflows en détail

### 1. **Backend Tests** (`backend-tests.yml`)

**Déclenché par:**
- Push sur `main` ou `develop` (fichiers backend)
- Pull request vers `main` ou `develop`

**Tests effectués:**

```yaml
✓ go fmt          → Format checking
✓ go vet          → Vetted code
✓ golangci-lint   → Linting rules
✓ Unit tests      → Coverage minimum 70%
✓ Race detector   → Detect race conditions
✓ Gosec           → Security scanning
✓ Binary build    → Compilation success
```

**Durée:** ~3-5 minutes

**Résultats visibles:**
- ✅ Test coverage report
- ✅ Codecov upload
- ✅ Security findings

---

### 2. **Frontend Tests** (`frontend-tests.yml`)

**Déclenché par:**
- Push sur `main` ou `develop` (fichiers frontend)
- Pull request vers `main` ou `develop`

**Tests effectués:**

```yaml
✓ ESLint          → Code linting (Node 18.x + 20.x)
✓ TypeScript      → Type checking
✓ Jest tests      → Unit tests (coverage ≥70%)
✓ Build           → Production build
✓ Bundle size     → Size analysis
✓ npm audit       → Dependency vulnerabilities
✓ Snyk            → Security scanning
```

**Durée:** ~2-4 minutes

**Résultats visibles:**
- ✅ Test reports per Node version
- ✅ Coverage badge
- ✅ Build artifacts

---

### 3. **Integration Tests** (`integration-tests.yml`)

**Déclenché par:**
- Push sur `main` ou `develop`
- Tous les pull requests

**Tests effectués:**

```yaml
Services testés:
✓ PostgreSQL      → Database initialization
✓ Redis           → Cache connectivity
✓ Neo4j           → Graph database

Tests API:
✓ Health check    → /health endpoint
✓ SBOM endpoints  → Upload, list, get
✓ Risk endpoints  → Score, summary
✓ CBOM analysis   → Algorithm detection

Docker Compose:
✓ Image build     → Backend + Frontend
✓ Service startup → All 7 services
✓ Health checks   → Service readiness
```

**Durée:** ~5-10 minutes

**Configuration test:**
- PostgreSQL user: `test_user`
- Database: `pqc_test`
- Port: `5432`
- Redis: `localhost:6379`
- Neo4j: `localhost:7687`

---

### 4. **Security Scan** (`security-scan.yml`)

**Déclenché par:**
- Push sur `main` ou `develop`
- Pull requests
- Schedule: Hebdomadaire le dimanche 2h du matin

**Scans effectués:**

```yaml
Static Analysis:
✓ Gosec           → Go security issues
✓ CodeQL          → Go + JavaScript analysis
✓ TruffleHog      → Secret detection

Dependency Checks:
✓ Nancy           → Go vulnerability scan
✓ npm audit       → Node.js vulnerabilities

Container Security:
✓ Trivy           → Docker image scan
  - Backend image
  - Frontend image

Compliance:
✓ License check   → Go + Node licenses
```

**Résultats visibles:**
- 🔒 Security tab dans GitHub
- 📊 CodeQL alerts
- ⚠️ Dependabot integration

---

### 5. **Quality & Release** (`quality-release.yml`)

**Déclenché par:**
- Push sur `main` (quality checks)
- Tags `v*` (release creation)

**Tests effectués:**

```yaml
Code Quality:
✓ Backend coverage  → Go tests
✓ Frontend coverage → React tests
✓ SonarQube        → Full analysis

Release Automation:
✓ GitHub Release    → Auto-created from tags
✓ Release notes     → From git log
✓ Docker publish    → ghcr.io images
  - ghcr.io/.../pqc-backend:latest
  - ghcr.io/.../pqc-frontend:latest

Documentation:
✓ Swagger docs      → Auto-generated
✓ Git push         → Commit changes
```

---

## 📊 Viewing Results

### Dashboard Actions

```
GitHub Repository → Actions Tab → Voir tous les workflows
```

### Details par workflow

```
Click workflow → See runs → Click run → View logs
```

### Badges de statut

Ajouter à votre README:

```markdown
[![Backend Tests](https://github.com/your-org/pqc-platform/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/your-org/pqc-platform/actions/workflows/backend-tests.yml)
[![Frontend Tests](https://github.com/your-org/pqc-platform/actions/workflows/frontend-tests.yml/badge.svg)](https://github.com/your-org/pqc-platform/actions/workflows/frontend-tests.yml)
[![Integration Tests](https://github.com/your-org/pqc-platform/actions/workflows/integration-tests.yml/badge.svg)](https://github.com/your-org/pqc-platform/actions/workflows/integration-tests.yml)
[![Security Scan](https://github.com/your-org/pqc-platform/actions/workflows/security-scan.yml/badge.svg)](https://github.com/your-org/pqc-platform/actions/workflows/security-scan.yml)
```

---

## 🔑 Secrets Configuration (Optionnel)

### SNYK_TOKEN (Optional)
```
1. Créer compte https://snyk.io
2. Copier API token
3. Ajouter dans Settings > Secrets > SNYK_TOKEN
```

### SONAR_TOKEN (Optional)
```
1. Créer projet https://sonarcloud.io
2. Copier token
3. Ajouter dans Settings > Secrets > SONAR_TOKEN
```

### CODECOV_TOKEN (Optional)
```
1. Lier repository https://codecov.io
2. Copier token
3. Ajouter dans Settings > Secrets > CODECOV_TOKEN
```

### Utiliser dans workflows:
```yaml
env:
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

## 🚨 Troubleshooting

### Workflow échoue

**Step 1: Vérifier les logs**
```
Actions → [Workflow name] → [Latest run] → View logs
```

**Step 2: Erreurs courantes**

#### "go: version not found"
```yaml
# Fix dans backend-tests.yml
- uses: actions/setup-go@v4
  with:
    go-version: '1.21'  # ✓ Correct
```

#### "npm: command not found"
```yaml
# Fix dans frontend-tests.yml
- uses: actions/setup-node@v4
  with:
    node-version: '18.x'
```

#### "Database connection refused"
```yaml
# Vérifier services dans docker-compose.test.yml
services:
  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready ..."]
      retries: 5  # ✓ Augmenter si timeout
```

#### "Tests timeout"
```yaml
# Augmenter timeout
timeout-minutes: 30  # Dans le job
```

---

## ⚙️ Customization

### Modifier les branches déclenchées

```yaml
# Dans chaque workflow
on:
  push:
    branches: [ main, develop, staging ]  # Ajouter branches
  pull_request:
    branches: [ main, develop ]
```

### Ajouter des tests personnalisés

```yaml
# Dans backend-tests.yml, ajouter:
- name: Run custom tests
  run: |
    cd backend
    go test -tags=integration ./... # Tests d'intégration
```

### Modifier les seuils de couverture

```yaml
# Dans backend-tests.yml
- name: Check coverage
  run: |
    coverage=$(go tool cover ... | grep total | awk '{print $3}' | sed 's/%//')
    if (( $(echo "$coverage < 80" | bc -l) )); then  # Change 70 to 80
      exit 1
    fi
```

### Ajouter des notifications

```yaml
# Slack notification example
- name: Slack notification
  uses: 8398a7/action-slack@v3
  if: failure()
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 📈 Monitoring

### Status checks sur PRs

```
Pull Request → Checks tab → See status de tous les workflows
```

Pour forcer les checks avant merge:
```
Settings → Branch protection rules → Require status checks to pass
```

### View metrics

```
Insights → Actions → Workflow runs
- Total runs
- Success/failure rate
- Execution time
```

---

## 🎯 Best Practices

✅ **DO:**
- Exécuter tous les tests avant push
- Voir les logs complets en cas d'erreur
- Configurer branch protection rules
- Utiliser secrets pour les tokens
- Garder les dependencies à jour
- Monitorer les sécurité scans

❌ **DON'T:**
- Commit secrets en dur
- Ignorer les test failures
- Pusher vers main sans tests verts
- Laisser les workflows cassés longtemps
- Commiter les fichiers node_modules
- Utiliser ancient versions Go/Node

---

## 📝 Example: Complet workflow

```yaml
# Le workflow se déclenche quand vous faites un commit
on:
  push:
    branches: [main]

# Tests parallèles
jobs:
  test_backend:
    runs-on: ubuntu-latest
    steps:
      # 1. Clone code
      - uses: actions/checkout@v4
      
      # 2. Setup Go
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      # 3. Run tests
      - run: cd backend && go test ./...
      
      # 4. Upload results
      - uses: codecov/codecov-action@v3
```

Durée totale: ~5 minutes ⚡

---

## 🔗 Useful Links

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Go Testing](https://golang.org/pkg/testing/)
- [Jest Documentation](https://jestjs.io/)
- [Docker in Actions](https://docs.docker.com/ci-cd/github-actions/)
- [Codecov Integration](https://codecov.io/github)
- [SonarQube Cloud](https://sonarcloud.io/)

---

## 📞 Support

Questions sur les workflows?

```
1. Check workflow logs in GitHub
2. Read error messages carefully
3. Google the error code
4. Ask in GitHub Discussions
5. Create an issue with workflow logs attached
```

---

**🎉 Vous avez maintenant un CI/CD complet avec GitHub Actions!**
