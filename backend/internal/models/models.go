package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// ============ SBOM Models ============

type SBOM struct {
	ID              uuid.UUID     `json:"id"`
	Name            string        `json:"name"`
	Version         string        `json:"version"`
	SpecVersion     string        `json:"spec_version"`
	Format          string        `json:"format"` // spdx, cyclonedx
	Content         JSONB         `json:"content"`
	ChecksumSHA256  string        `json:"checksum_sha256"`
	TenantID        uuid.UUID     `json:"tenant_id"`
	UploadedBy      uuid.UUID     `json:"uploaded_by"`
	UploadedAt      time.Time     `json:"uploaded_at"`
	ExpiresAt       *time.Time    `json:"expires_at,omitempty"`
	CreatedAt       time.Time     `json:"created_at"`
	UpdatedAt       time.Time     `json:"updated_at"`
	ComponentCount  int           `json:"component_count"`
	VulnerableCount int           `json:"vulnerable_count"`
	RiskLevel       string        `json:"risk_level"`
}

type SBOMComponent struct {
	ID      uuid.UUID
	SBOMId  uuid.UUID
	Name    string
	Version string
	Purl    string
	Type    string
	CPE     string
}

// ============ CBOM Models ============

type CBOMComponent struct {
	ID                        uuid.UUID  `json:"id"`
	SBOMId                    uuid.UUID  `json:"sbom_id"`
	ComponentName             string     `json:"component_name"`
	ComponentType             string     `json:"component_type"`
	ComponentVersion          string     `json:"component_version"`
	AlgorithmName             string     `json:"algorithm_name"`
	AlgorithmType             string     `json:"algorithm_type"` // encryption, signature, hash, kdf, mac, rng
	BitLength                 int        `json:"bit_length"`
	NISTQuantumSecurityLevel  *int       `json:"nist_quantum_security_level"` // 0-5, null=unknown
	PQCReady                  bool       `json:"pqc_ready"`
	ImplementationPlatform    string     `json:"implementation_platform"`
	ExecutionEnvironment      string     `json:"execution_environment"`
	SecurityStrength          *int       `json:"security_strength"`
	CreatedAt                 time.Time  `json:"created_at"`
	QuantumVulnerabilityScore *float64   `json:"quantum_vulnerability_score,omitempty"`
	MigrationPath             *string    `json:"migration_path,omitempty"`
}

// ============ Risk Analysis Models ============

type RiskScore struct {
	ID                        uuid.UUID `json:"id"`
	SBOMId                    uuid.UUID `json:"sbom_id"`
	ComponentId               *uuid.UUID `json:"component_id,omitempty"`
	RiskLevel                 string    `json:"risk_level"` // critical, high, medium, low, none
	QuantumVulnerabilityScore float64   `json:"quantum_vulnerability_score"` // 0.0-1.0
	Recommendation            string    `json:"recommendation"`
	SuggestedMigrationPath    string    `json:"suggested_migration_path"`
	TimelineYears             int       `json:"timeline_years"`
	CalculatedAt              time.Time `json:"calculated_at"`
}

type RiskSummary struct {
	SBOMId                   uuid.UUID `json:"sbom_id"`
	TotalComponents          int       `json:"total_components"`
	VulnerableComponents     int       `json:"vulnerable_components"`
	PQCReadyComponents       int       `json:"pqc_ready_components"`
	AvgVulnerabilityScore    float64   `json:"avg_vulnerability_score"`
	OverallRiskLevel         string    `json:"overall_risk_level"`
	MostCriticalAlgorithm    string    `json:"most_critical_algorithm"`
	RecommendedMigrationPath string    `json:"recommended_migration_path"`
}

// ============ Migration Plan Models ============

type MigrationPlan struct {
	ID                    uuid.UUID              `json:"id"`
	SBOMId                uuid.UUID              `json:"sbom_id"`
	PlanName              string                 `json:"plan_name"`
	Strategy              string                 `json:"strategy"` // hybrid, parallel, staged, cutover
	StartDate             time.Time              `json:"start_date"`
	TargetCompletionDate  time.Time              `json:"target_completion_date"`
	Priority              string                 `json:"priority"` // critical, high, medium, low
	Status                string                 `json:"status"`   // planning, in_progress, completed, on_hold
	Content               JSONB                  `json:"content"`
	CreatedBy             uuid.UUID              `json:"created_by"`
	CreatedAt             time.Time              `json:"created_at"`
	UpdatedAt             time.Time              `json:"updated_at"`
	MigrationPhases       []MigrationPhase       `json:"migration_phases,omitempty"`
	CompletionPercentage  int                    `json:"completion_percentage"`
}

type MigrationPhase struct {
	Phase              int                    `json:"phase"`
	Name               string                 `json:"name"`
	Description        string                 `json:"description"`
	StartDate          time.Time              `json:"start_date"`
	EndDate            time.Time              `json:"end_date"`
	Status             string                 `json:"status"`
	ComponentsAffected []uuid.UUID            `json:"components_affected"`
	Actions            []MigrationAction      `json:"actions"`
}

type MigrationAction struct {
	ID                uuid.UUID `json:"id"`
	Component         string    `json:"component"`
	CurrentAlgorithm  string    `json:"current_algorithm"`
	TargetAlgorithm   string    `json:"target_algorithm"`
	Action            string    `json:"action"` // replace, retire, parallel_run
	Status            string    `json:"status"` // pending, in_progress, completed
	CompletedAt       *time.Time `json:"completed_at,omitempty"`
	Notes             string    `json:"notes,omitempty"`
}

// ============ PQC Recommendation Models ============

type PQCAlgorithm struct {
	ID               uuid.UUID `json:"id"`
	Name             string    `json:"name"`
	Category         string    `json:"category"` // kem, signature, hash, other
	NISTStandard     string    `json:"nist_standard"`
	KeySizeBits      int       `json:"key_size_bits"`
	SecurityLevel    int       `json:"security_level"` // NIST levels 1-5
	Status           string    `json:"status"`         // recommended, emerging, legacy
	Notes            string    `json:"notes"`
	CreatedAt        time.Time `json:"created_at"`
}

type RecommendationResult struct {
	CurrentAlgorithm      string          `json:"current_algorithm"`
	RecommendedAlgorithm  string          `json:"recommended_algorithm"`
	MigrationComplexity   string          `json:"migration_complexity"` // low, medium, high
	TimelineMonths        int             `json:"timeline_months"`
	EstimatedCost         string          `json:"estimated_cost"`
	SecurityImprovement   string          `json:"security_improvement"`
	Implementation        string          `json:"implementation"`
	BreakingChanges       bool            `json:"breaking_changes"`
	RecommendedPQCAlgos   []PQCAlgorithm  `json:"recommended_pqc_algos"`
}

// ============ Audit Log Models ============

type AuditLog struct {
	ID            uuid.UUID              `json:"id"`
	Action        string                 `json:"action"`
	ResourceType  string                 `json:"resource_type"`
	ResourceId    *uuid.UUID             `json:"resource_id,omitempty"`
	TenantID      *uuid.UUID             `json:"tenant_id,omitempty"`
	UserId        *uuid.UUID             `json:"user_id,omitempty"`
	UserEmail     string                 `json:"user_email"`
	ChangeDetails JSONB                  `json:"change_details"`
	IPAddress     string                 `json:"ip_address"`
	UserAgent     string                 `json:"user_agent"`
	Status        string                 `json:"status"` // success, failure, warning
	ErrorMessage  *string                `json:"error_message,omitempty"`
	Timestamp     time.Time              `json:"timestamp"`
}

// ============ Report Models ============

type ComplianceReport struct {
	ID                    uuid.UUID     `json:"id"`
	SBOMId                uuid.UUID     `json:"sbom_id"`
	GeneratedAt           time.Time     `json:"generated_at"`
	ReportType            string        `json:"report_type"` // nist, anssi, etsi, hds, nis2
	OverallCompliance     float64       `json:"overall_compliance"` // 0-100%
	FindingsSummary       JSONB         `json:"findings_summary"`
	RecommendationsSummary JSONB        `json:"recommendations_summary"`
	RiskAssessment        JSONB         `json:"risk_assessment"`
	MigrationTimeline     JSONB         `json:"migration_timeline"`
	ApprovedBy            *uuid.UUID    `json:"approved_by,omitempty"`
}

// ============ JSON Type for PostgreSQL ============

type JSONB map[string]interface{}

func (j JSONB) Value() (driver.Value, error) {
	return json.Marshal(j)
}

func (j *JSONB) Scan(value interface{}) error {
	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion failed")
	}
	return json.Unmarshal(bytes, &j)
}

// ============ API Request/Response Models ============

type UploadSBOMRequest struct {
	File     []byte `json:"file"`
	FileName string `json:"filename"`
}

type UploadSBOMResponse struct {
	ID             uuid.UUID `json:"id"`
	Name           string    `json:"name"`
	Format         string    `json:"format"`
	ComponentCount int       `json:"component_count"`
	Message        string    `json:"message"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Code    string `json:"code"`
	Details string `json:"details,omitempty"`
}

type HealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version"`
	Database string `json:"database"`
	Cache    string `json:"cache"`
	Time     time.Time `json:"time"`
}

// ============ User & Auth Models ============

type User struct {
	ID         uuid.UUID `json:"id"`
	TenantID   uuid.UUID `json:"tenant_id"`
	Email      string    `json:"email"`
	FullName   string    `json:"full_name"`
	Role       string    `json:"role"` // admin, analyst, viewer
	AuthMethod string    `json:"auth_method"`
	LastLogin  *time.Time `json:"last_login,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type Tenant struct {
	ID                       uuid.UUID `json:"id"`
	Name                     string    `json:"name"`
	ContactEmail             string    `json:"contact_email"`
	MaxSBOMStorageBytes      int64     `json:"max_sbom_storage_bytes"`
	PQCComplianceRequired    bool      `json:"pqc_compliance_required"`
	CreatedAt                time.Time `json:"created_at"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
	User      User      `json:"user"`
}
