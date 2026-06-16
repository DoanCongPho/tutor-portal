package children

import (
	"github.com/gin-gonic/gin"

	"github.com/DoanCongPho/tutor-portal/backend/internal/auth"
	"github.com/DoanCongPho/tutor-portal/backend/internal/middleware"
)

// Routes mounts the children endpoints. Parent routes manage child profiles
// (parent-only per PRD §2); the student routes let a student link to a parent by
// entering the invite code. All require a valid access token (authMW).
func Routes(rg *gin.RouterGroup, h *Handler, authMW gin.HandlerFunc) {
	g := rg.Group("/children", authMW, middleware.RequireRole(auth.RoleParent))
	g.GET("", h.List)
	g.POST("", h.Create)
	g.POST("/connect", h.Connect)
	g.POST("/:id/invite", h.Regenerate)
	g.DELETE("/:id", h.Delete)

	// Student-facing: a student enters the invite code their parent generated to
	// link the two accounts (flips the pending child to connected).
	s := rg.Group("/children", authMW, middleware.RequireRole(auth.RoleStudent))
	s.POST("/link", h.Link)
	s.GET("/connection", h.MyConnection)
}
