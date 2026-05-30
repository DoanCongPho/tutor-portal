package auth

import "github.com/gin-gonic/gin"

func Routes(rg *gin.RouterGroup, h *Handler) {
	g := rg.Group("/auth")
	g.POST("/register/start", h.RegisterStart)
	g.POST("/register/verify", h.RegisterVerify)
	g.POST("/login/start", h.LoginStart)
	g.POST("/login/verify", h.LoginVerify)
	g.POST("/refresh", h.Refresh)
}
