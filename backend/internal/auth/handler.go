package auth

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	svc *Service
}

func NewHandler(s *Service) *Handler { return &Handler{svc: s} }

func (h *Handler) RegisterStart(c *gin.Context) {
	var req RegisterStartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	if err := h.svc.StartRegistration(c.Request.Context(), req.Phone, req.Role, req.Name); err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusAccepted, OTPSentResponse{ExpiresInSeconds: int(otpTTL.Seconds())})
}

func (h *Handler) RegisterVerify(c *gin.Context) {
	var req RegisterVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	result, err := h.svc.VerifyRegistration(c.Request.Context(), req.Phone, req.Code)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, toTokenResponse(result))
}

func (h *Handler) LoginStart(c *gin.Context) {
	var req LoginStartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	if err := h.svc.StartLogin(c.Request.Context(), req.Phone); err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusAccepted, OTPSentResponse{ExpiresInSeconds: int(otpTTL.Seconds())})
}

func (h *Handler) LoginVerify(c *gin.Context) {
	var req LoginVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	result, err := h.svc.VerifyLogin(c.Request.Context(), req.Phone, req.Code)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, toTokenResponse(result))
}

func (h *Handler) Refresh(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	result, err := h.svc.Refresh(c.Request.Context(), req.RefreshToken)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, toTokenResponse(result))
}

func (h *Handler) badRequest(c *gin.Context, err error) {
	c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
}

func (h *Handler) respondError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrPhoneAlreadyExists):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInvalidOTP):
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
	case errors.Is(err, ErrUserNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.Is(err, ErrAccountSuspended):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInvalidToken), errors.Is(err, ErrSessionExpired):
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}

func toTokenResponse(r *AuthResult) TokenResponse {
	return TokenResponse{
		AccessToken:             r.Access,
		RefreshToken:            r.Refresh,
		AccessExpiresInSeconds:  int(r.AccessExpiresIn.Seconds()),
		RefreshExpiresInSeconds: int(r.RefreshExpiresIn.Seconds()),
		User:                    toUserDTO(r.User),
	}
}
