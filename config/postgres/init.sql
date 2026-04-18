-- PQC Platform Database Schema

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- SBOM Table
CREATE TABLE IF NOT EXISTS sboms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    version VARCHAR(50),
    spec_version VARCHAR(20) NOT NULL,
    format VARCHAR(20) NOT NULL CHECK (format IN ('spdx', 'cyclonedx')),
    content JSONB NOT NULL,
    checksum_sha256 VARCHAR(64) NOT NULL UNIQUE,
    tenant_id UUID NOT NULL,
    uploaded_by UUID NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT sbom_name_unique UNIQUE(tenant_id, name)
);

CREATE INDEX idx_sbom_tenant ON sboms(tenant_id);
CREATE INDEX idx_sbom_format ON sboms(format);
CREATE INDEX idx_sbom_created ON sboms(created_at DESC);

-- CBOM Components Table
CREATE TABLE IF NOT EXISTS cbom_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sbom_id UUID NOT NULL REFERENCES sboms(id) ON DELETE CASCADE,
    component_name VARCHAR(255) NOT NULL,
    component_type VARCHAR(50),
    component_version VARCHAR(100),
    algorithm_name VARCHAR(100),
    algorithm_type VARCHAR(50) NOT NULL CHECK (algorithm_type IN ('encryption', 'signature', 'hash', 'kdf', 'mac', 'rng')),
    bit_length INTEGER,
    nist_quantum_security_level INTEGER CHECK (nist_quantum_security_level BETWEEN 0 AND 5),
    pqc_ready BOOLEAN DEFAULT FALSE,
    implementation_platform VARCHAR(50),
    execution_environment VARCHAR(50),
    security_strength INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (sbom_id) REFERENCES sboms(id) ON DELETE CASCADE
);

CREATE INDEX idx_cbom_sbom ON cbom_components(sbom_id);
CREATE INDEX idx_cbom_algo_type ON cbom_components(algorithm_type);
CREATE INDEX idx_cbom_quantum_level ON cbom_components(nist_quantum_security_level);

-- Risk Scores Table
CREATE TABLE IF NOT EXISTS risk_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sbom_id UUID NOT NULL REFERENCES sboms(id) ON DELETE CASCADE,
    component_id UUID REFERENCES cbom_components(id) ON DELETE CASCADE,
    risk_level VARCHAR(20) NOT NULL CHECK (risk_level IN ('critical', 'high', 'medium', 'low', 'none')),
    quantum_vulnerability_score NUMERIC(3, 2) NOT NULL CHECK (quantum_vulnerability_score BETWEEN 0 AND 1),
    recommendation TEXT,
    suggested_migration_path VARCHAR(100),
    timeline_years INTEGER,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_risk_sbom ON risk_scores(sbom_id);
CREATE INDEX idx_risk_level ON risk_scores(risk_level);

-- Migration Plans Table
CREATE TABLE IF NOT EXISTS migration_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sbom_id UUID NOT NULL REFERENCES sboms(id) ON DELETE CASCADE,
    plan_name VARCHAR(255),
    strategy VARCHAR(50) CHECK (strategy IN ('hybrid', 'parallel', 'staged', 'cutover')),
    start_date DATE NOT NULL,
    target_completion_date DATE NOT NULL,
    priority VARCHAR(20) CHECK (priority IN ('critical', 'high', 'medium', 'low')),
    status VARCHAR(50) DEFAULT 'planning',
    content JSONB NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_migration_sbom ON migration_plans(sbom_id);
CREATE INDEX idx_migration_status ON migration_plans(status);

-- Audit Logs Table (immutable, append-only)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    tenant_id UUID,
    user_id UUID,
    user_email VARCHAR(255),
    change_details JSONB,
    ip_address INET,
    user_agent VARCHAR(500),
    status VARCHAR(20) CHECK (status IN ('success', 'failure', 'warning')),
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Immutable: No UPDATE or DELETE allowed on audit_logs
CREATE INDEX idx_audit_tenant ON audit_logs(tenant_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);

-- Tenants Table
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    contact_email VARCHAR(255),
    max_sbom_storage BIGINT DEFAULT 10737418240, -- 10 GB
    pqc_compliance_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'analyst', 'viewer')),
    auth_method VARCHAR(50) DEFAULT 'oauth2',
    public_key_pem TEXT,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_tenant ON users(tenant_id);
CREATE INDEX idx_user_email ON users(email);

-- PQC Algorithms Reference Table
CREATE TABLE IF NOT EXISTS pqc_algorithms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL CHECK (category IN ('kem', 'signature', 'hash', 'other')),
    nist_std VARCHAR(20),
    key_size_bits INTEGER,
    security_level INTEGER,
    status VARCHAR(50) DEFAULT 'recommended',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert standard PQC algorithms
INSERT INTO pqc_algorithms (name, category, nist_std, key_size_bits, security_level, status, notes) VALUES
('ML-KEM-512', 'kem', 'FIPS 203', 512, 1, 'recommended', 'Kyber variant, security level 1'),
('ML-KEM-768', 'kem', 'FIPS 203', 768, 3, 'recommended', 'Kyber variant, security level 3'),
('ML-KEM-1024', 'kem', 'FIPS 203', 1024, 5, 'recommended', 'Kyber variant, security level 5'),
('ML-DSA-44', 'signature', 'FIPS 204', 2560, 2, 'recommended', 'Dilithium variant, security level 2'),
('ML-DSA-65', 'signature', 'FIPS 204', 4032, 3, 'recommended', 'Dilithium variant, security level 3'),
('ML-DSA-87', 'signature', 'FIPS 204', 5184, 5, 'recommended', 'Dilithium variant, security level 5'),
('SLH-DSA-SHA2-128s', 'signature', 'FIPS 205', 2144, 1, 'legacy', 'SPHINCS+ variant'),
('SHA3-256', 'hash', 'FIPS 202', 256, 3, 'recommended', 'Sponge-based hash function'),
('SHA3-512', 'hash', 'FIPS 202', 512, 5, 'recommended', 'Sponge-based hash function'),
('KMAC128', 'hash', 'FIPS 198', 128, 1, 'recommended', 'XOF-based MAC'),
('KMAC256', 'hash', 'FIPS 198', 256, 3, 'recommended', 'XOF-based MAC');

-- Create view for risk summary
CREATE OR REPLACE VIEW risk_summary_view AS
SELECT 
    sbom_id,
    COUNT(*) as total_components,
    SUM(CASE WHEN nist_quantum_security_level = 0 THEN 1 ELSE 0 END) as vulnerable_components,
    SUM(CASE WHEN nist_quantum_security_level >= 1 THEN 1 ELSE 0 END) as pqc_ready_components,
    ROUND(AVG(quantum_vulnerability_score)::NUMERIC, 3) as avg_vulnerability_score,
    MAX(CASE 
        WHEN quantum_vulnerability_score >= 0.8 THEN 'critical'
        WHEN quantum_vulnerability_score >= 0.6 THEN 'high'
        WHEN quantum_vulnerability_score >= 0.4 THEN 'medium'
        WHEN quantum_vulnerability_score >= 0.2 THEN 'low'
        ELSE 'none'
    END) as overall_risk_level
FROM cbom_components
GROUP BY sbom_id;

-- Grant permissions
GRANT CONNECT ON DATABASE pqc_inventory TO pqc_user;
GRANT USAGE ON SCHEMA public TO pqc_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pqc_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pqc_user;

-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (action, resource_type, resource_id, change_details, timestamp)
        VALUES ('DELETE', TG_TABLE_NAME, OLD.id, row_to_json(OLD), CURRENT_TIMESTAMP);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (action, resource_type, resource_id, change_details, timestamp)
        VALUES ('UPDATE', TG_TABLE_NAME, NEW.id, 
            jsonb_build_object('before', row_to_json(OLD), 'after', row_to_json(NEW)), 
            CURRENT_TIMESTAMP);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (action, resource_type, resource_id, change_details, timestamp)
        VALUES ('INSERT', TG_TABLE_NAME, NEW.id, row_to_json(NEW), CURRENT_TIMESTAMP);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for audit
CREATE TRIGGER sbom_audit_trigger AFTER INSERT OR UPDATE OR DELETE ON sboms
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER cbom_audit_trigger AFTER INSERT OR UPDATE OR DELETE ON cbom_components
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER risk_audit_trigger AFTER INSERT OR UPDATE OR DELETE ON risk_scores
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
