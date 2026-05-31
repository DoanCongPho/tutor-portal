package auth

import "github.com/gin-gonic/gin"

func Routes(rg *gin.RouterGroup, h *Handler) {
	g := rg.Group("/auth")
	g.POST("/register", h.Register)
	g.POST("/register/verify", h.VerifyRegistration)
	g.POST("/login", h.Login)
	g.POST("/refresh", h.Refresh)
}
