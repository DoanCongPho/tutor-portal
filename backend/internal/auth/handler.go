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

// Register is step one of email signup: it validates the payload, stashes a
// pending registration, and emails an OTP. No tokens yet — the client follows
// up with VerifyRegistration. Returns 202 Accepted.
func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	if err := h.svc.StartRegistration(c.Request.Context(), req.Email, req.Phone, req.Role, req.Name, req.Password); err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusAccepted, PendingRegistrationResponse{
		Email:   req.Email,
		Message: "Verification code sent",
	})
}

// VerifyRegistration is step two: it confirms the OTP, creates the account, and
// issues a token pair. Returns 201 Created.
func (h *Handler) VerifyRegistration(c *gin.Context) {
	var req VerifyRegistrationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	result, err := h.svc.VerifyRegistration(c.Request.Context(), req.Email, req.Code)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, toTokenResponse(result))
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	result, err := h.svc.Login(c.Request.Context(), req.Email, req.Password)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, toTokenResponse(result))
}

// GoogleLogin verifies a Google ID token. A known/linked email logs in (200 with
// tokens); an unseen email returns 200 with needs_role + a registration token the
// client follows up with via CompleteGoogleRegistration.
func (h *Handler) GoogleLogin(c *gin.Context) {
	var req GoogleLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	outcome, err := h.svc.LoginWithGoogle(c.Request.Context(), req.IDToken)
	if err != nil {
		h.respondError(c, err)
		return
	}
	if outcome.NeedsRole {
		c.JSON(http.StatusOK, GoogleLoginResponse{
			NeedsRole:         true,
			RegistrationToken: outcome.RegistrationToken,
		})
		return
	}
	tokens := toTokenResponse(outcome.Result)
	c.JSON(http.StatusOK, GoogleLoginResponse{NeedsRole: false, Auth: &tokens})
}

// CompleteGoogleRegistration creates a first-time Google user with the chosen
// role and issues tokens. Returns 201 Created.
func (h *Handler) CompleteGoogleRegistration(c *gin.Context) {
	var req CompleteGoogleRegistrationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	result, err := h.svc.CompleteGoogleRegistration(c.Request.Context(), req.RegistrationToken, req.Role)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, toTokenResponse(result))
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
	case errors.Is(err, ErrEmailAlreadyExists), errors.Is(err, ErrPhoneAlreadyExists):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInvalidCredentials):
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInvalidOTP):
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
	case errors.Is(err, ErrUserNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.Is(err, ErrAccountSuspended):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInvalidToken), errors.Is(err, ErrSessionExpired):
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
	case errors.Is(err, ErrGoogleTokenInvalid), errors.Is(err, ErrGoogleEmailUnverified),
		errors.Is(err, ErrInvalidRegistrationToken):
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
