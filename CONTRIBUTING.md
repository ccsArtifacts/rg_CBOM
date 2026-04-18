# Contributing to PQC Platform

Merci de l'intérêt porté à PQC Platform! Ce guide vous aidera à contribuer efficacement.

## Code of Conduct

Soyez respectueux, inclusif et constructif. Zéro tolérance pour le harcèlement.

## Comment contribuer?

### 1. Signaler un bug

Avant de signaler:
- Vérifiez que le bug n'existe pas déjà
- Testez avec la dernière version
- Fournissez les détails:
  - Système d'exploitation
  - Version (voir `make version`)
  - Étapes de reproduction
  - Comportement attendu vs observé
  - Logs d'erreur pertinents

Créez une issue GitHub avec le tag `[BUG]`

### 2. Proposer une amélioration

Créez une issue GitHub avec le tag `[FEATURE]` incluant:
- Description claire de la fonctionnalité
- Cas d'usage
- Bénéfices escomptés
- Alternatives considérées

### 3. Soumettre du code

#### Setup du développement

```bash
# Cloner le repo
git clone https://github.com/pqc-transition/pqc-platform.git
cd pqc-platform

# Installer les dépendances
make init
make build

# Démarrer le développement
make up
make logs-backend  # Terminal 2
make logs-frontend # Terminal 3
```

#### Processus de PR

1. **Fork** le repository
2. **Créer une branche** depuis `main`
   ```bash
   git checkout -b feature/ma-nouvelle-fonctionnalite
   ```
3. **Committer** avec des messages clairs
   ```bash
   git commit -m "feat: description courte (#123)"
   ```
4. **Push** vers votre fork
5. **Créer une Pull Request** avec:
   - Description détaillée
   - Référence aux issues (`Fixes #123`)
   - Screenshots si applicable
   - Tests unitaires/intégration

#### Convention de commits

Format: `<type>(<scope>): <subject>`

Types:
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `refactor`: Refactorisation
- `test`: Ajout de tests
- `docs`: Mise à jour documentation
- `perf`: Optimisation performance
- `chore`: Maintenance

Exemples:
```
feat(sbom): ajouter support CycloneDX 1.5
fix(auth): corriger jwt validation
test(cbom): ajouter tests algorithmes détection
docs(api): mettre à jour endpoints
```

### 4. Améliorer la documentation

- Corrections d'orthographe/grammaire
- Clarification des explications
- Ajout d'exemples
- Mises à jour pour nouvelles features

## Standards de développement

### Backend (Go)

```go
// Suivre golangci-lint
// Format: gofmt
// Tests: minimum 80% coverage
// Logs: structured logging avec zap

// Exemple
func (s *SBOMService) AnalyzeSBOM(ctx context.Context, id uuid.UUID) (*SBOM, error) {
    if err := s.validateID(id); err != nil {
        s.logger.Error("invalid SBOM ID", zap.Error(err))
        return nil, err
    }
    
    sbom, err := s.db.GetSBOM(ctx, id)
    if err != nil {
        s.logger.Error("failed to get SBOM", zap.Error(err), zap.String("id", id.String()))
        return nil, errors.Wrap(err, "failed to get SBOM")
    }
    
    return sbom, nil
}
```

### Frontend (React/TypeScript)

```typescript
// ESLint + Prettier
// TypeScript strict mode
// React 18+ avec hooks
// Componentes réutilisables

// Exemple
interface SBOMAnalysisProps {
  sbomId: string;
  onComplete?: (result: AnalysisResult) => void;
}

export const SBOMAnalysis: React.FC<SBOMAnalysisProps> = ({ 
  sbomId, 
  onComplete 
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const handleAnalyze = async () => {
    try {
      setLoading(true);
      const result = await sbomService.analyze(sbomId);
      onComplete?.(result);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Analysis failed'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card>
      {error && <ErrorAlert error={error} />}
      <Button onClick={handleAnalyze} disabled={loading}>
        {loading ? 'Analyzing...' : 'Analyze SBOM'}
      </Button>
    </Card>
  );
};
```

### Tests

```bash
# Backend tests
go test ./... -cover
go test ./... -race  # Détecter race conditions

# Frontend tests
npm test -- --coverage
npm run test:e2e

# Test coverage minimum: 80%
```

### Sécurité

- **Pas de secrets** dans le code
- **Validation des inputs** toujours
- **Sanitization** des outputs
- **TLS/SSL** pour toutes les communications
- **Audit logging** pour actions sensibles
- **Secrets** dans Vault, jamais en clair

Exemple sécurisé:

```go
// ✓ BON
password := os.Getenv("DB_PASSWORD") // De l'environnement
config := vault.GetSecret(ctx, "database/password")

// ✗ MAUVAIS
password := "my-secret-password"  // En dur
config.DBPassword = req.Password   // Non validé
sql := fmt.Sprintf("SELECT * FROM users WHERE id = %d", id) // SQL injection!
```

### Performance

- API latency < 200ms
- Requête DB optimisée (index, joins)
- Frontend bundle < 500KB gzip
- Caching intelligent (Redis)

## Review Process

1. **Vérification automatique**
   - Tests passent
   - Linting OK
   - Coverage minimum atteint

2. **Review humain**
   - Code quality
   - Sécurité
   - Performance
   - Documentation

3. **Approbation**
   - Minimum 2 reviewers
   - Tous les commentaires adressés

4. **Merge**
   - "Squash and merge" pour la clarté

## Release Process

1. Bump version dans `VERSION` file
2. Mettre à jour `CHANGELOG.md`
3. Créer une release tag: `git tag v1.0.0`
4. Créer une GitHub release avec notes
5. CI/CD publie les images Docker automatiquement

Format de version: Semantic Versioning (MAJOR.MINOR.PATCH)

## Questions?

- 📧 Email: dev@pqc-platform.io
- 💬 Discussions: GitHub Discussions
- 🐛 Issues: GitHub Issues
- 📖 Docs: https://docs.pqc-platform.io

Merci de vos contributions! 🙏
