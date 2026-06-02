package tutor

import (
	"github.com/gin-gonic/gin"

	"github.com/DoanCongPho/tutor-portal/backend/internal/middleware"
	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

// Routes mounts the tutor endpoints under /tutors, all guarded by a valid access
// token belonging to a tutor account.
func Routes(rg *gin.RouterGroup, h *Handler, signer *pkgjwt.Signer) {
	g := rg.Group("/tutors")
	g.Use(middleware.RequireAuth(signer), middleware.RequireRole("tutor"))
	g.POST("/onboarding", h.SubmitOnboarding)
	g.GET("/me", h.GetMyProfile)
}
