package children

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

func (h *Handler) List(c *gin.Context) {
	parentID, ok := h.parentID(c)
	if !ok {
		return
	}
	list, err := h.svc.List(c.Request.Context(), parentID)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, ChildListResponse{Children: toChildDTOs(list)})
}

func (h *Handler) Create(c *gin.Context) {
	parentID, ok := h.parentID(c)
	if !ok {
		return
	}
	var req CreateChildRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	st, err := h.svc.CreateInvite(c.Request.Context(), parentID, req.Name, req.Grade, req.School)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, toChildDTO(st))
}

func (h *Handler) Connect(c *gin.Context) {
	parentID, ok := h.parentID(c)
	if !ok {
		return
	}
	var req ConnectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	st, err := h.svc.Connect(c.Request.Context(), parentID, req.Code)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, toChildDTO(st))
}

// Link is the student-facing connect endpoint: the authenticated student enters
// the invite code their parent shared, flipping the pending child to connected
// and linking it to the student's account.
func (h *Handler) Link(c *gin.Context) {
	studentID, ok := h.studentID(c)
	if !ok {
		return
	}
	var req ConnectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.badRequest(c, err)
		return
	}
	st, err := h.svc.LinkByCode(c.Request.Context(), studentID, req.Code)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, toChildDTO(st))
}

// MyConnection returns the student's current parent link, or 404 if they haven't
// connected yet (the frontend treats 404 as "not connected").
func (h *Handler) MyConnection(c *gin.Context) {
	studentID, ok := h.studentID(c)
	if !ok {
		return
	}
	st, err := h.svc.MyConnection(c.Request.Context(), studentID)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, toChildDTO(st))
}

func (h *Handler) Regenerate(c *gin.Context) {
	parentID, ok := h.parentID(c)
	if !ok {
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		h.badRequest(c, err)
		return
	}
	st, err := h.svc.RegenerateInvite(c.Request.Context(), parentID, id)
	if err != nil {
		h.respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, toChildDTO(st))
}

func (h *Handler) Delete(c *gin.Context) {
	parentID, ok := h.parentID(c)
	if !ok {
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		h.badRequest(c, err)
		return
	}
	if err := h.svc.Remove(c.Request.Context(), parentID, id); err != nil {
		h.respondError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// parentID reads the authenticated user id. The parent role is already enforced
// by middleware.RequireRole on the route group, so this only guards against a
// missing id (route mounted without RequireAuth).
func (h *Handler) parentID(c *gin.Context) (uint64, bool) {
	id, ok := middleware.UserID(c)
	if !ok || id == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return 0, false
	}
	return id, true
}

// studentID reads the authenticated user id for the student-facing routes. The
// student role is enforced by middleware.RequireRole on the route group; this
// only guards against a missing id.
func (h *Handler) studentID(c *gin.Context) (uint64, bool) {
	id, ok := middleware.UserID(c)
	if !ok || id == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return 0, false
	}
	return id, true
}

func (h *Handler) badRequest(c *gin.Context, err error) {
	c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
}

func (h *Handler) respondError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrChildNotFound), errors.Is(err, ErrInviteNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInviteExpired):
		c.JSON(http.StatusGone, gin.H{"error": err.Error()})
	case errors.Is(err, ErrAlreadyConnected):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, ErrForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}
