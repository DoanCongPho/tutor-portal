package tutor

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

type Module struct {
	handler *Handler
	signer  *pkgjwt.Signer
}

// New wires the tutor feature. It needs the DB (data access) and the JWT signer
// (used by the route-group auth middleware). It issues no tokens itself.
func New(db *gorm.DB, signer *pkgjwt.Signer) *Module {
	repo := NewRepository(db)
	svc := NewService(repo)
	return &Module{handler: NewHandler(svc), signer: signer}
}

func (m *Module) RegisterRoutes(rg *gin.RouterGroup) {
	Routes(rg, m.handler, m.signer)
}
