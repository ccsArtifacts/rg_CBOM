pqc-platform/
├── README.md                          # Documentation principale
├── .gitignore                         # Git ignore patterns
├── .env.example                       # Template variables d'environnement
├── docker-compose.yml                 # Orchestration Docker
├── Makefile                           # Commandes courantes
├── LICENSE                            # MIT License
│
├── backend/                           # Application backend (Go)
│   ├── Dockerfile                     # Container image
│   ├── go.mod                         # Go module definition
│   ├── go.sum                         # Go module checksums
│   │
│   ├── cmd/
│   │   └── main.go                   # Application entry point
│   │
│   ├── internal/
│   │   ├── api/                      # HTTP handlers & routers
│   │   │   ├── handler.go            # Main handler struct
│   │   │   ├── sbom.go               # SBOM endpoints
│   │   │   ├── cbom.go               # CBOM endpoints
│   │   │   ├── risk.go               # Risk analysis endpoints
│   │   │   ├── migration.go          # Migration planning endpoints
│   │   │   ├── reporting.go          # Reporting endpoints
│   │   │   └── admin.go              # Admin endpoints
│   │   │
│   │   ├── services/                 # Business logic
│   │   │   ├── sbom_service.go       # SBOM parsing & analysis
│   │   │   ├── cbom_service.go       # CBOM extraction & detection
│   │   │   ├── risk_analyzer.go      # PQC risk scoring
│   │   │   ├── migration_planner.go  # Migration strategy planning
│   │   │   ├── reporting_service.go  # Report generation
│   │   │   └── integration_service.go # External integrations
│   │   │
│   │   ├── db/                       # Database layer
│   │   │   ├── postgres.go           # PostgreSQL connection
│   │   │   ├── neo4j.go              # Neo4j connection
│   │   │   └── queries.go            # SQL queries
│   │   │
│   │   ├── auth/                     # Authentication & authorization
│   │   │   ├── jwt.go                # JWT handling
│   │   │   ├── oauth.go              # OAuth2 integration
│   │   │   ├── ldap.go               # LDAP integration
│   │   │   └── rbac.go               # Role-based access control
│   │   │
│   │   ├── crypto/                   # Cryptographic utilities
│   │   │   ├── detector.go           # Algorithm detection
│   │   │   ├── analyzer.go           # Algorithm analysis
│   │   │   ├── pqc_mapper.go         # PQC recommendations
│   │   │   └── vulnerability.go      # Vulnerability scoring
│   │   │
│   │   ├── models/                   # Data models
│   │   │   └── models.go             # All data structures
│   │   │
│   │   ├── vault/                    # Secret management
│   │   │   └── vault_client.go       # Vault integration
│   │   │
│   │   ├── logging/                  # Logging utilities
│   │   │   └── logger.go             # Structured logging
│   │   │
│   │   └── config/                   # Configuration
│   │       └── config.go             # App configuration
│   │
│   └── pkg/                          # Reusable packages
│       ├── sbom/                     # SBOM parsing
│       │   ├── spdx.go               # SPDX format
│       │   └── cyclonedx.go          # CycloneDX format
│       │
│       ├── cbom/                     # CBOM utilities
│       │   ├── detector.go           # Crypto detection
│       │   └── analyzer.go           # Analysis tools
│       │
│       └── utils/                    # Helper functions
│           ├── errors.go             # Error handling
│           └── validators.go         # Input validation
│
├── frontend/                          # React application
│   ├── Dockerfile                     # Container image
│   ├── package.json                   # NPM dependencies
│   ├── package-lock.json              # Dependency lock file
│   ├── tsconfig.json                  # TypeScript config
│   ├── tailwind.config.js             # Tailwind CSS config
│   ├── vite.config.ts                 # Vite config
│   ├── .env.example                   # Environment template
│   │
│   ├── public/                        # Static assets
│   │   ├── index.html                # HTML template
│   │   ├── favicon.ico                # Favicon
│   │   └── manifest.json              # PWA manifest
│   │
│   └── src/                           # Source code
│       ├── main.tsx                   # App entry point
│       ├── App.tsx                    # Root component
│       ├── index.css                  # Global styles
│       │
│       ├── components/                # React components
│       │   ├── Dashboard.tsx          # Main dashboard
│       │   ├── SBOMImporter.tsx       # SBOM upload
│       │   ├── CBOMAnalyzer.tsx       # CBOM analysis
│       │   ├── RiskScorer.tsx         # Risk visualization
│       │   ├── MigrationPlanner.tsx   # Migration planning UI
│       │   ├── Reports.tsx            # Reporting interface
│       │   ├── Navigation.tsx         # Navigation menu
│       │   ├── Layout.tsx             # Layout wrapper
│       │   └── common/                # Reusable components
│       │       ├── Button.tsx
│       │       ├── Card.tsx
│       │       ├── Modal.tsx
│       │       ├── Table.tsx
│       │       └── LoadingSpinner.tsx
│       │
│       ├── pages/                     # Page components
│       │   ├── HomePage.tsx
│       │   ├── SBOMPage.tsx
│       │   ├── RiskPage.tsx
│       │   ├── MigrationPage.tsx
│       │   ├── ReportsPage.tsx
│       │   ├── AdminPage.tsx
│       │   └── NotFoundPage.tsx
│       │
│       ├── hooks/                     # Custom React hooks
│       │   ├── useAuth.ts             # Auth hook
│       │   ├── useAPI.ts              # API calls
│       │   ├── useSBOM.ts             # SBOM data
│       │   └── useMigration.ts        # Migration data
│       │
│       ├── services/                  # API client services
│       │   ├── api.ts                 # Axios client
│       │   ├── auth.service.ts        # Auth endpoints
│       │   ├── sbom.service.ts        # SBOM endpoints
│       │   ├── cbom.service.ts        # CBOM endpoints
│       │   ├── risk.service.ts        # Risk endpoints
│       │   ├── migration.service.ts   # Migration endpoints
│       │   └── reporting.service.ts   # Report endpoints
│       │
│       ├── store/                     # State management
│       │   ├── auth.store.ts          # Auth state
│       │   ├── sbom.store.ts          # SBOM state
│       │   ├── ui.store.ts            # UI state
│       │   └── appStore.ts            # Global store
│       │
│       ├── types/                     # TypeScript types
│       │   ├── models.ts              # Domain models
│       │   ├── api.ts                 # API response types
│       │   └── auth.ts                # Auth types
│       │
│       ├── utils/                     # Utility functions
│       │   ├── formatting.ts          # Format utilities
│       │   ├── validation.ts          # Validators
│       │   ├── date.ts                # Date utilities
│       │   └── storage.ts             # Local storage
│       │
│       ├── constants/                 # Constants
│       │   ├── api.ts                 # API endpoints
│       │   ├── algorithms.ts          # Algorithm definitions
│       │   └── themes.ts              # Theme constants
│       │
│       └── styles/                    # Global styles
│           ├── globals.css
│           ├── variables.css
│           └── animations.css
│
├── config/                            # Configuration files
│   ├── nginx/
│   │   ├── nginx.conf                # Main Nginx config
│   │   ├── ssl.conf                  # SSL/TLS config
│   │   └── security.conf             # Security headers
│   │
│   ├── postgres/
│   │   ├── init.sql                  # Database schema
│   │   ├── server.crt                # TLS certificate
│   │   └── server.key                # TLS private key
│   │
│   ├── elasticsearch/
│   │   └── elasticsearch.yml         # ES config
│   │
│   ├── vault/
│   │   ├── init.sh                   # Vault initialization
│   │   └── config.hcl                # Vault config
│   │
│   └── tls/
│       ├── server.crt                # Server certificate
│       └── server.key                # Server private key
│
├── scripts/                           # Helper scripts
│   ├── deploy.sh                     # Full deployment
│   ├── generate-certs.sh             # TLS certificate generation
│   ├── init-vault.sh                 # Vault initialization
│   ├── backup-database.sh            # Database backup
│   ├── restore-database.sh           # Database restore
│   ├── migrate-schema.sh              # Database migrations
│   └── health-check.sh               # Health monitoring
│
├── docs/                              # Documentation
│   ├── ARCHITECTURE.md               # System architecture
│   ├── API.md                        # API documentation
│   ├── DEPLOYMENT.md                 # Deployment guide
│   ├── SECURITY.md                   # Security guidelines
│   ├── PQC_MIGRATION.md              # PQC migration strategy
│   ├── CONTRIBUTING.md               # Contribution guide
│   └── TROUBLESHOOTING.md            # Troubleshooting guide
│
├── tests/                             # Test files
│   ├── integration/
│   │   ├── sbom_test.go
│   │   ├── cbom_test.go
│   │   └── risk_test.go
│   │
│   ├── unit/
│   │   ├── services_test.go
│   │   └── utils_test.go
│   │
│   └── e2e/
│       └── main_test.ts
│
├── data/                              # Data directory
│   ├── uploads/                      # Uploaded SBOM files
│   ├── exports/                      # Generated reports
│   └── backups/                      # Database backups
│
└── logs/                              # Application logs
    ├── backend.log
    ├── frontend.log
    └── audit.log

═══════════════════════════════════════════════════════════════
Total: ~150+ source files
Languages: Go, TypeScript, React, SQL, YAML, Shell
Architecture: Microservices (containerized)
Database: PostgreSQL + Neo4j + Elasticsearch
Cache: Redis
Security: TLS 1.3, JWT, RBAC, Audit Logs
═══════════════════════════════════════════════════════════════
