package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"go.uber.org/zap"

	"github.com/pqc-transition/pqc-platform/internal/api"
	"github.com/pqc-transition/pqc-platform/internal/auth"
	"github.com/pqc-transition/pqc-platform/internal/db"
	"github.com/pqc-transition/pqc-platform/internal/services"
	"github.com/pqc-transition/pqc-platform/internal/vault"
)

var Version = "1.0.0"

func main() {
	// Load .env file
	_ = godotenv.Load()

	// Initialize logger
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	// Initialize Echo
	e := echo.New()
	e.HideBanner = true

	// Middleware
	e.Use(middleware.RequestLoggerWithConfig(middleware.RequestLoggerConfig{
		LogURI:    true,
		LogStatus: true,
		LogMethod: true,
	}))
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins:     []string{"https://localhost:3000", "https://localhost"},
		AllowMethods:     []string{echo.GET, echo.POST, echo.PUT, echo.DELETE, echo.PATCH},
		AllowHeaders:     []string{echo.HeaderAuthorization, echo.HeaderContentType},
		AllowCredentials: true,
		MaxAge:           3600,
	}))
	e.Use(middleware.RecoverWithConfig(middleware.RecoverConfig{
		StackSize: 4 << 10,
	}))

	// Initialize services
	ctx := context.Background()

	// Database initialization
	postgresDB, err := db.NewPostgresDB(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		logger.Fatal("Failed to initialize PostgreSQL", zap.Error(err))
	}
	defer postgresDB.Close()

	neo4jDB, err := db.NewNeo4jDB(ctx, os.Getenv("NEO4J_URI"))
	if err != nil {
		logger.Fatal("Failed to initialize Neo4j", zap.Error(err))
	}
	defer neo4jDB.Close(ctx)

	// Vault initialization
	vaultClient, err := vault.NewVaultClient(os.Getenv("VAULT_ADDR"), os.Getenv("VAULT_TOKEN"))
	if err != nil {
		logger.Fatal("Failed to initialize Vault", zap.Error(err))
	}

	// Auth service
	authService := auth.NewAuthService(vaultClient)

	// Initialize services
	sbomService := services.NewSBOMService(postgresDB, neo4jDB)
	cbomService := services.NewCBOMService(postgresDB, neo4jDB)
	riskAnalyzer := services.NewRiskAnalyzer(postgresDB)
	migrationPlanner := services.NewMigrationPlanner(postgresDB)
	reportingService := services.NewReportingService(postgresDB)

	// API handlers
	handler := api.NewHandler(
		sbomService,
		cbomService,
		riskAnalyzer,
		migrationPlanner,
		reportingService,
		authService,
		logger,
	)

	// Routes
	v1 := e.Group("/api/v1")

	// Health check
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok", "version": Version})
	})

	// SBOM endpoints
	v1.POST("/sbom/upload", handler.UploadSBOM)
	v1.GET("/sbom/:id", handler.GetSBOM)
	v1.GET("/sbom", handler.ListSBOMs)
	v1.DELETE("/sbom/:id", handler.DeleteSBOM)

	// CBOM endpoints
	v1.GET("/cbom/:sbomId", handler.GetCBOM)
	v1.POST("/cbom/:sbomId/analyze", handler.AnalyzeCBOM)
	v1.GET("/cbom/:sbomId/algorithms", handler.GetAlgorithms)

	// Risk analysis endpoints
	v1.GET("/risk/score/:sbomId", handler.GetRiskScore)
	v1.GET("/risk/summary", handler.GetRiskSummary)
	v1.POST("/risk/rescan", handler.RescanRisk)

	// Migration planning endpoints
	v1.POST("/migration/plan", handler.CreateMigrationPlan)
	v1.GET("/migration/plan/:id", handler.GetMigrationPlan)
	v1.PUT("/migration/plan/:id", handler.UpdateMigrationPlan)
	v1.GET("/migration/recommendations", handler.GetPQCRecommendations)

	// Reporting endpoints
	v1.GET("/reports/compliance/:sbomId", handler.GenerateComplianceReport)
	v1.GET("/reports/executive", handler.GenerateExecutiveReport)
	v1.POST("/reports/export", handler.ExportReport)

	// Admin endpoints
	admin := v1.Group("/admin")
	admin.Use(authService.AuthMiddleware())
	admin.GET("/stats", handler.GetSystemStats)
	admin.GET("/audit", handler.GetAuditLogs)

	// TLS configuration
	tlsCert := os.Getenv("TLS_CERT")
	tlsKey := os.Getenv("TLS_KEY")

	tlsConfig := &tls.Config{
		MinVersion:               tls.VersionTLS13,
		PreferServerCipherSuites: true,
	}

	server := &http.Server{
		Addr:      ":8080",
		TLSConfig: tlsConfig,
	}

	// Start server
	go func() {
		logger.Info("Starting PQC Platform Server", zap.String("version", Version))
		if err := e.StartServer(server); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := e.Shutdown(ctx); err != nil {
		logger.Fatal("Server shutdown error", zap.Error(err))
	}

	logger.Info("Server shutdown gracefully")
}
