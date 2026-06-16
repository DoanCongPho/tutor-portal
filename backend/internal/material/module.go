package material

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Module struct {
	handler *Handler
}

// New wires the material (learning-portal) feature. It needs only the DB: all
// authorization is resolved against existing rows (tutor_profiles, students,
// bookings) through the repository, and route auth uses the shared authMW
// passed to RegisterRoutes.
func New(db *gorm.DB) *Module {
	repo := NewRepository(db)
	svc := NewService(repo)
	return &Module{handler: NewHandler(svc)}
}

func (m *Module) RegisterRoutes(rg *gin.RouterGroup, authMW gin.HandlerFunc) {
	Routes(rg, m.handler, authMW)
}
