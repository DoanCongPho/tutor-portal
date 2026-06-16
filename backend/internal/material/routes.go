package material

import (
	"github.com/gin-gonic/gin"

	"github.com/DoanCongPho/tutor-portal/backend/internal/auth"
	"github.com/DoanCongPho/tutor-portal/backend/internal/middleware"
)

// Routes mounts the learning-portal material endpoints under /materials, all
// requiring a valid access token (authMW). Reads are open to any party of a
// booking (tutor/child/parent) and authorized in the service; writes are
// tutor-only and gated here with RequireRole.
func Routes(rg *gin.RouterGroup, h *Handler, authMW gin.HandlerFunc) {
	g := rg.Group("/materials", authMW)
	g.GET("", h.ListByBooking) // ?booking_id=<id>
	g.POST("", middleware.RequireRole(auth.RoleTutor), h.Create)
	g.DELETE("/:id", middleware.RequireRole(auth.RoleTutor), h.Delete)
}
