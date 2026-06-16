package material

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/DoanCongPho/tutor-portal/backend/internal/middleware"
)

type Handler struct {
	svc *Service
}

func NewHandler(s *Service) *Handler { return &Handler{svc: s} }

// Create attaches a document/material to one of the authenticated tutor's
// bookings. The route is guarded by RequireRole("tutor").
func (h *Handler) Create(c *gin.Context) {
	uid, ok := middleware.UserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	var req CreateMaterialRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := h.svc.CreateMaterial(c.Request.Context(), uid, req)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, res)
}

// ListByBooking returns the documents attached to a booking, selected by the
// ?booking_id= query param. Open to any party of the booking (tutor, child,
// parent); the service enforces which.
func (h *Handler) ListByBooking(c *gin.Context) {
	uid, ok := middleware.UserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	role, _ := middleware.Role(c)
	bookingID, err := strconv.ParseUint(c.Query("booking_id"), 10, 64)
	if err != nil || bookingID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing or invalid booking_id"})
		return
	}
	res, err := h.svc.ListBookingMaterials(c.Request.Context(), uid, role, bookingID)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"materials": res})
}

// Delete removes a material owned by the authenticated tutor.
func (h *Handler) Delete(c *gin.Context) {
	uid, ok := middleware.UserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil || id == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid material id"})
		return
	}
	if err := h.svc.DeleteMaterial(c.Request.Context(), uid, id); err != nil {
		h.respondError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *Handler) respondError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrInvalidType), errors.Is(err, ErrDeadlineNotAllowed):
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	case errors.Is(err, ErrForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, ErrMaterialNotFound),
		errors.Is(err, ErrBookingNotFound),
		errors.Is(err, ErrProfileNotFound),
		errors.Is(err, ErrStudentNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}
