package tutor

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/DoanCongPho/tutor-portal/backend/internal/middleware"
)

type Handler struct {
	svc *Service
}

func NewHandler(s *Service) *Handler { return &Handler{svc: s} }

// SubmitOnboarding persists the authenticated tutor's full onboarding payload
// and returns the resulting profile (status pending_review). The route is
// guarded by RequireAuth+RequireRole("tutor"), so the user id is always present.
func (h *Handler) SubmitOnboarding(c *gin.Context) {
	uid, ok := middleware.UserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	var req SubmitOnboardingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	res, err := h.svc.SubmitOnboarding(c.Request.Context(), uid, req)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, res)
}

// GetMyProfile returns the authenticated tutor's onboarding profile, or 404 if
// they have not onboarded.
func (h *Handler) GetMyProfile(c *gin.Context) {
	uid, ok := middleware.UserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	res, err := h.svc.GetMyProfile(c.Request.Context(), uid)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, res)
}

func (h *Handler) badRequest(c *gin.Context, err error) {
	c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
}

func (h *Handler) respondError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrInvalidSubject),
		errors.Is(err, ErrInvalidLevel),
		errors.Is(err, ErrInvalidDocType),
		errors.Is(err, ErrInvalidRate),
		errors.Is(err, ErrInvalidSchedule):
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	case errors.Is(err, ErrProfileNotFound), errors.Is(err, ErrUserNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.Is(err, ErrProfileExists):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}
