#!/bin/bash

set -euo pipefail

# ============================================
# PQC Platform Deployment Script
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="pqc-platform"
LOG_FILE="${SCRIPT_DIR}/deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $@" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $@" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $@" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $@" | tee -a "${LOG_FILE}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    command -v docker &> /dev/null || {
        log_error "Docker is not installed"
        exit 1
    }
    
    command -v docker-compose &> /dev/null || {
        log_error "Docker Compose is not installed"
        exit 1
    }
    
    command -v openssl &> /dev/null || {
        log_error "OpenSSL is not installed"
        exit 1
    }
    
    log_success "All prerequisites found"
}

# Generate TLS certificates
generate_tls_certificates() {
    log_info "Generating TLS certificates..."
    
    local cert_dir="${SCRIPT_DIR}/config/tls"
    mkdir -p "${cert_dir}"
    
    # Generate private key if not exists
    if [ ! -f "${cert_dir}/server.key" ]; then
        openssl genrsa -out "${cert_dir}/server.key" 2048 2>/dev/null
        log_success "Generated server private key"
    fi
    
    # Generate certificate if not exists
    if [ ! -f "${cert_dir}/server.crt" ]; then
        openssl req -new -x509 -key "${cert_dir}/server.key" -out "${cert_dir}/server.crt" \
            -days 365 -subj "/CN=localhost/O=PQC-Platform/C=FR" 2>/dev/null
        log_success "Generated server certificate"
    fi
    
    # Set proper permissions
    chmod 600 "${cert_dir}/server.key" "${cert_dir}/server.crt"
}

# Generate .env file
setup_env() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f "${SCRIPT_DIR}/.env" ]; then
        cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
        
        # Generate secure passwords
        local db_pass=$(openssl rand -base64 32)
        local neo4j_pass=$(openssl rand -base64 32)
        local elastic_pass=$(openssl rand -base64 32)
        local redis_pass=$(openssl rand -base64 32)
        
        # Update .env with generated passwords
        sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${db_pass}/" "${SCRIPT_DIR}/.env"
        sed -i "s/NEO4J_PASSWORD=.*/NEO4J_PASSWORD=${neo4j_pass}/" "${SCRIPT_DIR}/.env"
        sed -i "s/ELASTIC_PASSWORD=.*/ELASTIC_PASSWORD=${elastic_pass}/" "${SCRIPT_DIR}/.env"
        sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=${redis_pass}/" "${SCRIPT_DIR}/.env"
        
        log_success "Generated secure environment configuration"
    else
        log_warning ".env file already exists, skipping generation"
    fi
}

# Start services
start_services() {
    log_info "Starting Docker services..."
    
    cd "${SCRIPT_DIR}"
    
    # Pull latest images
    docker-compose pull 2>/dev/null || true
    
    # Start services
    docker-compose up -d
    
    log_success "Docker services started"
}

# Wait for services to be healthy
wait_for_services() {
    log_info "Waiting for services to be healthy..."
    
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local healthy_services=0
        local total_services=7
        
        # Check each service
        docker-compose ps --services --filter "status=running" | grep -q "postgres" && ((healthy_services++)) || true
        docker-compose ps --services --filter "status=running" | grep -q "neo4j" && ((healthy_services++)) || true
        docker-compose ps --services --filter "status=running" | grep -q "elasticsearch" && ((healthy_services++)) || true
        docker-compose ps --services --filter "status=running" | grep -q "redis" && ((healthy_services++)) || true
        docker-compose ps --services --filter "status=running" | grep -q "vault" && ((healthy_services++)) || true
        docker-compose ps --services --filter "status=running" | grep -q "pqc-backend" && ((healthy_services++)) || true
        docker-compose ps --services --filter "status=running" | grep -q "pqc-frontend" && ((healthy_services++)) || true
        
        if [ $healthy_services -eq $total_services ]; then
            log_success "All services are healthy"
            return 0
        fi
        
        log_info "Waiting... ($((attempt+1))/$max_attempts) - $healthy_services/$total_services services running"
        sleep 2
        ((attempt++))
    done
    
    log_error "Services did not become healthy in time"
    return 1
}

# Initialize database
init_database() {
    log_info "Initializing database..."
    
    sleep 5  # Wait for PostgreSQL to be ready
    
    docker-compose exec -T postgres psql -U pqc_user -d pqc_inventory \
        -c "SELECT 1" &>/dev/null || {
        log_error "Failed to connect to PostgreSQL"
        return 1
    }
    
    log_success "Database initialized"
}

# Run tests
run_tests() {
    log_info "Running health checks..."
    
    # Check PostgreSQL
    docker-compose exec -T postgres pg_isready -U pqc_user || {
        log_error "PostgreSQL health check failed"
        return 1
    }
    
    # Check Neo4j
    docker-compose exec -T neo4j curl -s -u neo4j:${NEO4J_PASSWORD:-pqc_graph_2024} \
        http://localhost:7474 &>/dev/null || {
        log_warning "Neo4j might not be ready yet"
    }
    
    # Check Elasticsearch
    docker-compose exec -T elasticsearch curl -s -u elastic:${ELASTIC_PASSWORD:-pqc_elastic_2024} \
        https://localhost:9200 --insecure &>/dev/null || {
        log_warning "Elasticsearch might not be ready yet"
    }
    
    # Check Backend
    docker-compose exec -T pqc-backend curl -s -k https://localhost:8080/health &>/dev/null || {
        log_warning "Backend might not be ready yet"
    }
    
    log_success "Health checks completed"
}

# Print access information
print_access_info() {
    log_info "PQC Platform is ready!"
    echo ""
    echo -e "${GREEN}Access Information:${NC}"
    echo "========================================="
    echo -e "Frontend:     ${BLUE}https://localhost:3000${NC}"
    echo -e "API:          ${BLUE}https://localhost:8080/api${NC}"
    echo -e "Vault:        ${BLUE}http://localhost:8200${NC}"
    echo -e "Neo4j:        ${BLUE}http://localhost:7474${NC} (neo4j/pqc_graph_2024)"
    echo -e "Elasticsearch:${BLUE}https://localhost:9200${NC} (elastic/pqc_elastic_2024)"
    echo "========================================="
    echo ""
    echo -e "${YELLOW}Default Credentials:${NC}"
    echo "- PostgreSQL: pqc_user / (see .env)"
    echo "- Neo4j: neo4j / (see .env)"
    echo "- Elasticsearch: elastic / (see .env)"
    echo "- Vault Token: pqc-dev-token-2024"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Open https://localhost:3000 in your browser"
    echo "2. Accept the self-signed certificate warning"
    echo "3. Start by uploading your first SBOM"
    echo ""
}

# Cleanup function
cleanup() {
    log_warning "Cleaning up..."
    docker-compose down
    log_info "Cleanup completed"
}

# Main execution
main() {
    log_info "========================================="
    log_info "PQC Platform Deployment Script"
    log_info "========================================="
    
    check_prerequisites
    generate_tls_certificates
    setup_env
    start_services
    wait_for_services || {
        log_error "Failed to start services"
        cleanup
        exit 1
    }
    init_database
    run_tests
    print_access_info
    
    log_success "Deployment completed successfully!"
}

# Trap errors
trap 'log_error "An error occurred"; cleanup; exit 1' ERR

# Execute main
main "$@"
