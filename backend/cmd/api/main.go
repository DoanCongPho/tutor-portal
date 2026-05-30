package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	redis "github.com/redis/go-redis/v9"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"github.com/DoanCongPho/tutor-portal/backend/internal/auth"
	"github.com/DoanCongPho/tutor-portal/backend/internal/config"
	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

func main() {
	cfg := config.Load()

	db, err := openDB(cfg)
	if err != nil {
		log.Fatalf("db: %v", err)
	}
	rdb := tryOpenRedis(cfg)
	if rdb != nil {
		defer rdb.Close()
	}

	signer := pkgjwt.NewSigner(cfg.JWTSecret, cfg.JWTAccessTTL, cfg.JWTRefreshTTL)

	if cfg.AppEnv == "production" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.GET("/api/v1/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	v1 := r.Group("/api/v1")
	auth.New(db, rdb, signer).RegisterRoutes(v1)

	srv := &http.Server{
		Addr:              ":" + cfg.AppPort,
		Handler:           r,
		ReadHeaderTimeout: 5 * time.Second,
	}
	go func() {
		log.Printf("api listening on :%s (env=%s)", cfg.AppPort, cfg.AppEnv)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("server: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("shutdown: %v", err)
	}
}

func openDB(cfg config.Config) (*gorm.DB, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=true&loc=UTC",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, cfg.DBName)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}
	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(5)
	sqlDB.SetConnMaxLifetime(time.Hour)
	return db, nil
}

// tryOpenRedis returns a Redis client when the address is reachable,
// otherwise nil. auth.New transparently falls back to an in-process KV store
// when nil. Fine for local dev; NOT for production — OTPs and sessions vanish
// on restart.
//
// We probe with raw net.DialTimeout first so a missing Redis fails in ~1s
// instead of go-redis's default several-second pool-retry storm.
func tryOpenRedis(cfg config.Config) *redis.Client {
	addr := cfg.RedisHost + ":" + cfg.RedisPort
	conn, err := net.DialTimeout("tcp", addr, time.Second)
	if err != nil {
		log.Printf("WARN redis: not reachable at %s — using in-memory KV store (OTPs and sessions lost on restart). %v",
			addr, err)
		return nil
	}
	_ = conn.Close()
	log.Printf("redis: connected at %s", addr)
	return redis.NewClient(&redis.Options{Addr: addr})
}
