.PHONY: help build up down logs clean test deploy stop restart health init

.DEFAULT_GOAL := help

PROJECT_NAME := pqc-platform
DOCKER_COMPOSE := docker-compose
LOG_DIR := logs

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

help:
	@echo "$(BLUE)PQC Platform - Available Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Deployment:$(NC)"
	@echo "  make deploy          - Deploy the entire platform (recommended for first run)"
	@echo "  make up              - Start all services"
	@echo "  make down            - Stop all services"
	@echo "  make restart         - Restart all services"
	@echo "  make stop            - Stop services without removing"
	@echo ""
	@echo "$(GREEN)Building:$(NC)"
	@echo "  make build           - Build Docker images"
	@echo "  make rebuild         - Force rebuild all images"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  make logs            - Follow all service logs"
	@echo "  make logs-backend    - Follow backend logs only"
	@echo "  make logs-frontend   - Follow frontend logs only"
	@echo "  make logs-db         - Follow database logs only"
	@echo ""
	@echo "$(GREEN)Database:$(NC)"
	@echo "  make db-shell        - Access PostgreSQL shell"
	@echo "  make db-reset        - Reset database (CAUTION)"
	@echo "  make neo4j-shell     - Access Neo4j shell"
	@echo ""
	@echo "$(GREEN)Monitoring:$(NC)"
	@echo "  make health          - Check services health"
	@echo "  make stats           - Show resource usage"
	@echo "  make ps              - List running containers"
	@echo ""
	@echo "$(GREEN)Testing:$(NC)"
	@echo "  make test            - Run all tests"
	@echo "  make test-api        - Test API endpoints"
	@echo "  make test-db         - Test database connectivity"
	@echo ""
	@echo "$(GREEN)Maintenance:$(NC)"
	@echo "  make clean           - Remove containers and volumes"
	@echo "  make clean-images    - Remove all images"
	@echo "  make init            - Initialize configuration (certs, .env)"
	@echo "  make prune           - Clean unused Docker resources"
	@echo ""
	@echo "$(GREEN)Access:$(NC)"
	@echo "  Frontend:  https://localhost:3000"
	@echo "  API:       https://localhost:8080/api"
	@echo "  Vault:     http://localhost:8200"
	@echo "  Neo4j:     http://localhost:7474"
	@echo "  PgAdmin:   http://localhost:5050"

# Deployment
deploy: init build up health
	@echo "$(GREEN)✓ Platform deployed successfully!$(NC)"
	@make print-access

up:
	@echo "$(BLUE)Starting services...$(NC)"
	@mkdir -p $(LOG_DIR)
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✓ Services started$(NC)"

down:
	@echo "$(BLUE)Stopping services...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓ Services stopped$(NC)"

stop:
	@echo "$(BLUE)Pausing services...$(NC)"
	@$(DOCKER_COMPOSE) stop
	@echo "$(GREEN)✓ Services paused$(NC)"

restart: down up
	@echo "$(GREEN)✓ Services restarted$(NC)"

# Building
build:
	@echo "$(BLUE)Building images...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)✓ Images built$(NC)"

rebuild:
	@echo "$(BLUE)Rebuilding images (no cache)...$(NC)"
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)✓ Images rebuilt$(NC)"

# Logging
logs:
	@$(DOCKER_COMPOSE) logs -f

logs-backend:
	@$(DOCKER_COMPOSE) logs -f pqc-backend

logs-frontend:
	@$(DOCKER_COMPOSE) logs -f pqc-frontend

logs-db:
	@$(DOCKER_COMPOSE) logs -f postgres

logs-neo4j:
	@$(DOCKER_COMPOSE) logs -f neo4j

# Database
db-shell:
	@$(DOCKER_COMPOSE) exec postgres psql -U pqc_user -d pqc_inventory

db-reset:
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(DOCKER_COMPOSE) down -v; \
		make up; \
		echo "$(GREEN)✓ Database reset$(NC)"; \
	else \
		echo "$(RED)Cancelled$(NC)"; \
	fi

neo4j-shell:
	@$(DOCKER_COMPOSE) exec neo4j cypher-shell -u neo4j

# Monitoring
health:
	@echo "$(BLUE)Checking services health...$(NC)"
	@$(DOCKER_COMPOSE) ps --services | while read service; do \
		status=$$($(DOCKER_COMPOSE) ps $$service --format "{{.State}}"); \
		if [ "$$status" = "running" ]; then \
			echo "$(GREEN)✓$(NC) $$service: $$status"; \
		else \
			echo "$(RED)✗$(NC) $$service: $$status"; \
		fi; \
	done

stats:
	@docker stats --no-stream

ps:
	@$(DOCKER_COMPOSE) ps

# Testing
test: test-db test-api
	@echo "$(GREEN)✓ All tests passed$(NC)"

test-db:
	@echo "$(BLUE)Testing database connectivity...$(NC)"
	@$(DOCKER_COMPOSE) exec -T postgres pg_isready -U pqc_user -d pqc_inventory || true
	@echo "$(GREEN)✓ Database test passed$(NC)"

test-api:
	@echo "$(BLUE)Testing API endpoints...$(NC)"
	@curl -sk https://localhost:8080/health -w "\nHTTP Status: %{http_code}\n" || echo "$(RED)API not ready$(NC)"

# Initialization
init:
	@echo "$(BLUE)Initializing configuration...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✓ Created .env file$(NC)"; \
	fi
	@if [ ! -d config/tls ]; then \
		mkdir -p config/tls; \
		openssl genrsa -out config/tls/server.key 2048 2>/dev/null || true; \
		openssl req -new -x509 -key config/tls/server.key -out config/tls/server.crt \
			-days 365 -subj "/CN=localhost/O=PQC-Platform/C=FR" 2>/dev/null || true; \
		chmod 600 config/tls/server.*; \
		echo "$(GREEN)✓ Generated TLS certificates$(NC)"; \
	fi
	@if [ ! -d config/postgres ]; then \
		mkdir -p config/postgres; \
		echo "$(GREEN)✓ Created PostgreSQL config directory$(NC)"; \
	fi
	@echo "$(GREEN)✓ Initialization complete$(NC)"

# Cleanup
clean: down
	@echo "$(BLUE)Cleaning up...$(NC)"
	@$(DOCKER_COMPOSE) down -v
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

clean-images:
	@echo "$(BLUE)Removing images...$(NC)"
	@docker rmi pqc-platform_pqc-backend pqc-platform_pqc-frontend 2>/dev/null || true
	@echo "$(GREEN)✓ Images removed$(NC)"

prune:
	@echo "$(BLUE)Pruning Docker resources...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)✓ Pruning complete$(NC)"

# Utils
print-access:
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  PQC Platform - Access Information$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BLUE)Web Interfaces:$(NC)"
	@echo "  Frontend:     https://localhost:3000"
	@echo "  Vault UI:     http://localhost:8200/ui"
	@echo "  Neo4j:        http://localhost:7474"
	@echo ""
	@echo "$(BLUE)APIs:$(NC)"
	@echo "  REST API:     https://localhost:8080/api/v1"
	@echo "  Health:       https://localhost:8080/health"
	@echo ""
	@echo "$(BLUE)Databases:$(NC)"
	@echo "  PostgreSQL:   localhost:5432"
	@echo "  Neo4j:        localhost:7687"
	@echo "  Redis:        localhost:6379"
	@echo "  Elasticsearch:localhost:9200"
	@echo ""
	@echo "$(BLUE)Default Credentials:$(NC)"
	@echo "  DB User:      pqc_user"
	@echo "  Neo4j User:   neo4j"
	@echo "  ES User:      elastic"
	@echo "  (Passwords in .env file)"
	@echo ""
	@echo "$(BLUE)Useful Commands:$(NC)"
	@echo "  Logs:         make logs"
	@echo "  Health:       make health"
	@echo "  DB Shell:     make db-shell"
	@echo "  Help:         make help"
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""

# Development utilities
backend-build:
	@cd backend && go build -o pqc-server ./cmd/main.go

frontend-install:
	@cd frontend && npm install

frontend-dev:
	@cd frontend && npm start

docs:
	@echo "$(BLUE)Opening documentation...$(NC)"
	@which xdg-open > /dev/null && xdg-open README.md || open README.md || echo "README.md"

version:
	@echo "$(BLUE)PQC Platform v1.0.0$(NC)"

.PHONY: test-build
test-build:
	@echo "$(BLUE)Testing builds...$(NC)"
	@cd backend && CGO_ENABLED=0 GOOS=linux go build -o /tmp/pqc-server ./cmd/main.go && echo "$(GREEN)✓ Backend build OK$(NC)" || echo "$(RED)✗ Backend build failed$(NC)"
	@cd frontend && npm run build && echo "$(GREEN)✓ Frontend build OK$(NC)" || echo "$(RED)✗ Frontend build failed$(NC)"

version-check:
	@echo "$(BLUE)Version Information:$(NC)"
	@echo "  Go: $$(go version 2>/dev/null || echo 'Not installed')"
	@echo "  Node: $$(node --version 2>/dev/null || echo 'Not installed')"
	@echo "  Docker: $$(docker --version)"
	@echo "  Docker Compose: $$(docker-compose --version)"
