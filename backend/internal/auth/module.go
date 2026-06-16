package auth

import (
	"github.com/gin-gonic/gin"
	redis "github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	"github.com/DoanCongPho/tutor-portal/backend/pkg/email"
	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

type Module struct {
	handler *Handler
}

// New wires the auth feature. Pass nil for rdb to use the in-process KV store
// (handy for dev when Redis isn't running). In that mode the refresh-session
// JTIs are lost on restart (everyone is logged out); for production always
// pass a real client.
//
// mailer delivers the signup OTP. Pass nil to fall back to email.LogSender,
// which writes the code to the app log instead of dialing out — fine for dev,
// never for production.
//
// googleClientID is the audience Google ID tokens are verified against (the
// Firebase Web/server OAuth client id); see config.GoogleOAuthClientID.
func New(db *gorm.DB, rdb *redis.Client, signer *pkgjwt.Signer, mailer email.Sender, googleClientID string) *Module {
	var kv kvStore
	if rdb != nil {
		kv = &redisStore{client: rdb}
	} else {
		kv = newMemoryStore()
	}
	if mailer == nil {
		mailer = email.LogSender{}
	}
	repo := NewRepository(db)
	svc := NewService(repo, kv, signer, mailer, newGoogleVerifier(googleClientID))
	return &Module{handler: NewHandler(svc)}
}

func (m *Module) RegisterRoutes(rg *gin.RouterGroup) {
	Routes(rg, m.handler)
}
