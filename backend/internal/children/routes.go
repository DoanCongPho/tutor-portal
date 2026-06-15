package children

import (
	"github.com/gin-gonic/gin"

	"github.com/DoanCongPho/tutor-portal/backend/internal/auth"
	"github.com/DoanCongPho/tutor-portal/backend/internal/middleware"
)

// Routes mounts the children endpoints. All require a valid access token
// (authMW) and the parent role — child management is parent-only per PRD §2.
func Routes(rg *gin.RouterGroup, h *Handler, authMW gin.HandlerFunc) {
	g := rg.Group("/children", authMW, middleware.RequireRole(auth.RoleParent))
	g.GET("", h.List)
	g.POST("", h.Create)
	g.POST("/connect", h.Connect)
	g.POST("/:id/invite", h.Regenerate)
	g.DELETE("/:id", h.Delete)
}
