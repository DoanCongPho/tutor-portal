package material

import (
	"context"

	"github.com/DoanCongPho/tutor-portal/backend/internal/auth"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

// CreateMaterial attaches a learning-portal document to one of the tutor's
// bookings (PRD §5.8). The booking is the course: the material's student is
// taken from the booking, so only that booking's child (and its parent) can
// later read it. Ownership is enforced — a tutor may only post to their own
// booking.
func (s *Service) CreateMaterial(ctx context.Context, userID uint64, req CreateMaterialRequest) (*MaterialResponse, error) {
	if !IsValidType(req.Type) {
		return nil, ErrInvalidType
	}
	// Only assignments carry a deadline (and may later receive submissions).
	if req.Deadline != nil && req.Type != TypeAssignment {
		return nil, ErrDeadlineNotAllowed
	}

	profileID, err := s.repo.TutorProfileIDByUser(ctx, userID)
	if err != nil {
		return nil, err
	}
	booking, err := s.repo.FindBooking(ctx, req.BookingID)
	if err != nil {
		return nil, err
	}
	if booking.TutorID != profileID {
		return nil, ErrForbidden
	}

	bookingID := booking.ID
	m := &Material{
		TutorID:   profileID,
		StudentID: booking.StudentID,
		BookingID: &bookingID,
		Type:      req.Type,
		Title:     req.Title,
		Deadline:  req.Deadline,
	}
	if req.FileURL != "" {
		m.FileURL = &req.FileURL
	}
	if err := s.repo.InsertMaterial(ctx, m); err != nil {
		return nil, err
	}
	resp := toMaterialResponse(m)
	return &resp, nil
}

// ListBookingMaterials returns every document attached to a booking, for any
// party to it: the owning tutor, the booking's child, or the child's parent.
func (s *Service) ListBookingMaterials(ctx context.Context, userID uint64, role string, bookingID uint64) ([]MaterialResponse, error) {
	booking, err := s.repo.FindBooking(ctx, bookingID)
	if err != nil {
		return nil, err
	}
	if err := s.authorizeBookingAccess(ctx, userID, role, booking); err != nil {
		return nil, err
	}
	rows, err := s.repo.ListByBooking(ctx, bookingID)
	if err != nil {
		return nil, err
	}
	out := make([]MaterialResponse, 0, len(rows))
	for i := range rows {
		out = append(out, toMaterialResponse(&rows[i]))
	}
	return out, nil
}

// DeleteMaterial removes a document. Only the tutor who owns it may delete it.
func (s *Service) DeleteMaterial(ctx context.Context, userID, materialID uint64) error {
	profileID, err := s.repo.TutorProfileIDByUser(ctx, userID)
	if err != nil {
		return err
	}
	m, err := s.repo.FindMaterial(ctx, materialID)
	if err != nil {
		return err
	}
	if m.TutorID != profileID {
		return ErrForbidden
	}
	return s.repo.DeleteMaterial(ctx, materialID)
}

// authorizeBookingAccess permits the booking's tutor, child, or parent and
// rejects everyone else with ErrForbidden. The caller's role selects which
// identity column the user id is matched against.
func (s *Service) authorizeBookingAccess(ctx context.Context, userID uint64, role string, b *bookingRef) error {
	switch role {
	case auth.RoleTutor:
		profileID, err := s.repo.TutorProfileIDByUser(ctx, userID)
		if err != nil {
			return err
		}
		if profileID != b.TutorID {
			return ErrForbidden
		}
	case auth.RoleStudent:
		studentID, err := s.repo.StudentIDByUser(ctx, userID)
		if err != nil {
			return err
		}
		if studentID != b.StudentID {
			return ErrForbidden
		}
	case auth.RoleParent:
		if userID != b.ParentID {
			return ErrForbidden
		}
	default:
		return ErrForbidden
	}
	return nil
}
