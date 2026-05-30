package auth

import (
	"github.com/gin-gonic/gin"
	redis "github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

type Module struct {
	handler *Handler
}

// New wires the auth feature. Pass nil for rdb to use the in-process KV store
// (handy for dev when Redis isn't running). In that mode OTPs and sessions
// are lost on restart; for production always pass a real client.
func New(db *gorm.DB, rdb *redis.Client, signer *pkgjwt.Signer) *Module {
	var kv kvStore
	if rdb != nil {
		kv = &redisStore{client: rdb}
	} else {
		kv = newMemoryStore()
	}
	repo := NewRepository(db)
	svc := NewService(repo, kv, signer)
	return &Module{handler: NewHandler(svc)}
}

func (m *Module) RegisterRoutes(rg *gin.RouterGroup) {
	Routes(rg, m.handler)
}
