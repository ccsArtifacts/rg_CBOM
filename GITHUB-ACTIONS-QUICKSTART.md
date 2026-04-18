# ✨ GitHub Actions Testing - Quick Start

## 🎯 3 minutes pour avoir un CI/CD complet

### Step 1: Fork ou clone le repository

```bash
# Option A: Si vous avez votre compte GitHub
# Aller à https://github.com/new et importer le ZIP
# Ou cloner localement:
git clone https://github.com/YOUR-USERNAME/pqc-platform.git
cd pqc-platform

# Option B: Clone directement
git clone https://github.com/pqc-transition/pqc-platform.git
```

### Step 2: Activer GitHub Actions

```
Votre repository GitHub
  ↓
Settings → Actions → Allow all actions and reusable workflows ✓
```

### Step 3: Faire un commit

```bash
git add .
git commit -m "feat: initial commit"
git push origin main
```

### Step 4: Voir les workflows en action!

```
Votre repository GitHub
  ↓
Actions tab → Voir tous les workflows s'exécuter ✅
```

---

## 🚀 Ce qui se passe automatiquement

Quand vous faites un **push** ou une **pull request**:

### Les 5 workflows se déclenchent en parallèle:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  🔄 Backend Tests        → Tests Go + Security Scan       │
│  🔄 Frontend Tests       → Tests React + TypeScript        │
│  🔄 Integration Tests    → Full stack avec Docker          │
│  🔄 Security Scan        → SAST, secrets, deps             │
│  🔄 Quality & Release    → SonarQube + Docker Publish      │
│                                                             │
│  ⏱️ Total time: 5-10 minutes                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Résultats visibles:

✅ **PR Status Checks** - Voir si les tests passent  
✅ **Security Tab** - CodeQL, Snyk findings  
✅ **Codecov Badge** - Coverage %  
✅ **GitHub Releases** - Auto-created from tags  
✅ **Docker Registr** - ghcr.io images published  

---

## 📊 5 Workflows détaillés

### 1️⃣ Backend Tests (backend-tests.yml)

**Déclenché par:** Push/PR aux fichiers backend

**Tests:**
```
✓ Code formatting    (go fmt)
✓ Code linting       (golangci-lint)
✓ Unit tests         (go test, 70% coverage minimum)
✓ Security scan      (gosec)
✓ Race conditions    (go test -race)
✓ Binary build       (CGO_ENABLED=0)
```

**Affichage résultats:**
- GitHub PR checks
- Codecov coverage badge
- ✅ Checkmark si succès / ❌ X si erreur

---

### 2️⃣ Frontend Tests (frontend-tests.yml)

**Déclenché par:** Push/PR aux fichiers frontend

**Tests (multiple Node versions):**
```
✓ Linting            (ESLint)
✓ TypeScript         (Type checking)
✓ Unit tests         (Jest, 70% coverage)
✓ Build              (Vite production build)
✓ Bundle size check  (Alert si > 500KB gzip)
✓ Dependency audit   (npm audit)
```

**Affichage résultats:**
- Matrix results (Node 18 + 20)
- Codecov badge
- Bundle size metrics

---

### 3️⃣ Integration Tests (integration-tests.yml)

**Déclenché par:** Tous les push/PR

**Services testés:**
```
✓ PostgreSQL    → Database init + connectivity
✓ Redis         → Cache health check
✓ Neo4j         → Graph DB startup
✓ Backend API   → /health, /api endpoints
✓ Frontend      → Build + load test
✓ Docker images → Build + push cache
```

**Réel test:** 
```bash
# Voici ce qui s'exécute:
curl https://localhost:8080/health
curl -X POST /api/v1/sbom/upload ...
curl /api/v1/risk/score/...
```

---

### 4️⃣ Security Scan (security-scan.yml)

**Déclenché par:** Push, PR, Schedule (weekly)

**Scans effectués:**
```
SAST Analysis:
✓ CodeQL       → Go + JavaScript vulnerabilities
✓ Gosec        → Go security issues
✓ TruffleHog   → Secret detection
✓ Trivy        → Docker image scanning

Dependency Checks:
✓ Nancy        → Go CVE vulnerabilities
✓ npm audit    → Node.js vulnerabilities
✓ Snyk         → Comprehensive scan

Compliance:
✓ License check → Legal compliance
```

**Résultats visibles:**
- GitHub Security tab
- CodeQL alerts
- Trivy report

---

### 5️⃣ Quality & Release (quality-release.yml)

**Déclenché par:** Push to main, tags v*

**Actions:**
```
Code Quality:
✓ SonarQube    → Full code analysis
✓ Coverage     → Combined metrics

Automated Release:
✓ GitHub Release → Auto-created from tags
✓ Release notes  → From git log
✓ Docker publish → ghcr.io/your-org/...

Documentation:
✓ Swagger docs → Auto-generated
✓ Commit changes → Git push
```

**Comment créer une release:**
```bash
git tag v1.0.0
git push origin v1.0.0
# → GitHub Actions crée la release automatiquement
```

---

## 🔍 Voir les résultats

### Option 1: Depuis GitHub web
```
Repository → Actions tab → Click workflow → Click run → Expand logs
```

### Option 2: Depuis une PR
```
Pull Request → Checks tab → Details → View logs
```

### Option 3: Status badge dans README
```markdown
[![Tests](https://github.com/your/repo/actions/workflows/backend-tests.yml/badge.svg)](...)
```

---

## 🛠️ Fichiers inclus

### Workflows (`.github/workflows/`)
```
✓ backend-tests.yml          (350 lines) → Go testing
✓ frontend-tests.yml         (180 lines) → React testing
✓ integration-tests.yml      (270 lines) → Full stack
✓ security-scan.yml          (310 lines) → Security
✓ quality-release.yml        (220 lines) → Quality & release
```

### Support files
```
✓ docker-compose.test.yml    → Test services
✓ docs/GITHUB-ACTIONS.md     → Complete guide
```

**Total:** ~1,330 lines de configuration CI/CD

---

## ⚙️ Configuration optionnelle

### Ajouter secrets (pour fonctionnalités premium)

```
Settings → Secrets and variables → Actions → New secret
```

Secrets optionnels:
```
SNYK_TOKEN      (Snyk vulnerability scanning)
SONAR_TOKEN     (SonarQube code quality)
CODECOV_TOKEN   (Code coverage platform)
```

Sans ces secrets, les workflows fonctionnent quand même!

---

## 🐛 Troubleshooting

### "Tests failed"
1. Aller à Actions tab
2. Click le workflow qui a échoué
3. Voir le log detaillé
4. Fixer le code localement
5. Push à nouveau → workflow se réexécute automatiquement

### "Coverage too low"
```
Solution: Ajouter plus de tests
File: backend/internal/services/*_test.go
       frontend/src/__tests__/*
```

### "Docker build timeout"
```yaml
# Dans les workflows
timeout-minutes: 30  # Augmenter si needed
```

### "Secrets not found"
```yaml
# Si vous utilisez secrets:
env:
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

## 📈 Metrics & Monitoring

### Dashboard GitHub Actions
```
Repository → Insights → Actions
- Total runs
- Success rate
- Execution time trends
```

### Codecov dashboard
```
codecov.io → Find your repo → View coverage
- Trend graphs
- Per-file breakdown
- Missing coverage
```

### SonarQube dashboard
```
sonarcloud.io → Your project
- Code smells
- Vulnerabilities
- Technical debt
```

---

## ✅ Checklist: Vous êtes prêt!

- [ ] Repository cloned ou forked
- [ ] GitHub Actions activé
- [ ] Commit poussé
- [ ] Workflows visibles dans Actions tab
- [ ] Au moins 1 workflow complété (succès ou échec)
- [ ] Logs consultés
- [ ] Prochaine étape: Modifier le code

---

## 🎯 Cas d'usage

### Scenario 1: Développement local + GitHub

```bash
# 1. Développer en local
vim backend/internal/services/sbom_service.go

# 2. Tester localement
make test

# 3. Commit et push
git commit -m "fix: sbom parsing issue"
git push origin feature/fix-sbom

# 4. GitHub Actions teste automatiquement
# 5. Ouvrir PR → Voir les checks
# 6. Merge une fois tout vert
```

### Scenario 2: Release automation

```bash
# 1. Bump version dans code
VERSION=1.0.1

# 2. Tag release
git tag v1.0.1
git push origin v1.0.1

# 3. GitHub Actions:
#    ✓ Crée la release
#    ✓ Publie les images Docker
#    ✓ Génère les docs
#    ✓ Envoie notification

# Terminé! Release complètement automatisée
```

### Scenario 3: Security monitoring

```
GitHub Security tab
├─ CodeQL alerts    → Classer + resolver
├─ Snyk findings    → See vulnerability details
├─ Secret scanning  → Alert si secret commité
└─ Dependabot       → Automated PRs pour updates
```

---

## 🚀 Prochaines étapes

1. **Voir les workflows en action:**
   ```
   Actions tab → Refresh → Watch workflow run in real-time
   ```

2. **Modifier le code et voir les tests:**
   ```bash
   git checkout -b test-feature
   echo "// test" >> backend/cmd/main.go
   git commit -am "test: trigger workflow"
   git push origin test-feature
   ```

3. **Créer une PR et voir les checks:**
   ```
   GitHub → Compare & pull request → See checks on PR
   ```

4. **Configurer branch protection:**
   ```
   Settings → Branches → Add branch protection rule
   ✓ Require status checks to pass
   ```

---

## 💡 Pro Tips

**Tip 1:** Workflows en parallèle → 10x plus rapide qu'en série

**Tip 2:** Cache les dépendances → 2-3x faster builds
```yaml
cache: 'go'  # Utilise GitHub's action caching
```

**Tip 3:** Utiliser `if: failure()` pour notifs:
```yaml
- name: Slack notification
  if: failure()
  run: curl webhook...
```

**Tip 4:** Matcher plusieurs branches:
```yaml
on:
  push:
    branches: [ main, develop, release/* ]
```

**Tip 5:** Checkout avec fetch-depth: 0 pour git log:
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Full history for SonarQube
```

---

## 📞 Help

- **Besoin d'aide?** Consultez `docs/GITHUB-ACTIONS.md`
- **Erreur dans les logs?** Copy-paste dans Google
- **Pas compris?** Lire `.github/workflows/*.yml`
- **Besoin de changer quelque chose?** Edit `.yml` et push

---

**🎉 Vous avez maintenant un CI/CD complet avec GitHub Actions!**

Tests automatiques, security scans, releases, Docker publishing — tout en 5-10 minutes! ⚡

