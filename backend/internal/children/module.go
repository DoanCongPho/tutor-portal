package children

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Module struct {
	handler *Handler
}

// New wires the children feature: repository → service → handler.
func New(db *gorm.DB) *Module {
	repo := NewRepository(db)
	svc := NewService(repo)
	return &Module{handler: NewHandler(svc)}
}

// RegisterRoutes mounts the routes under rg. authMW is the shared
// middleware.RequireAuth instance (it carries the JWT signer).
func (m *Module) RegisterRoutes(rg *gin.RouterGroup, authMW gin.HandlerFunc) {
	Routes(rg, m.handler, authMW)
}
