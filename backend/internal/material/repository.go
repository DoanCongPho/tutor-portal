package material

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

// TutorProfileIDByUser resolves the tutor_profiles.id owned by a user, or
// ErrProfileNotFound. materials.tutor_id and bookings.tutor_id reference the
// profile id, so an authenticated tutor's user id must be translated before any
// ownership check.
func (r *Repository) TutorProfileIDByUser(ctx context.Context, userID uint64) (uint64, error) {
	var ref tutorProfileRef
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&ref).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return 0, ErrProfileNotFound
	}
	if err != nil {
		return 0, err
	}
	return ref.ID, nil
}

// StudentIDByUser resolves the students.id linked to a connected child's own
// user account, or ErrStudentNotFound.
func (r *Repository) StudentIDByUser(ctx context.Context, userID uint64) (uint64, error) {
	var ref studentRef
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&ref).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return 0, ErrStudentNotFound
	}
	if err != nil {
		return 0, err
	}
	return ref.ID, nil
}

// FindBooking loads the authorization-relevant slice of a booking.
func (r *Repository) FindBooking(ctx context.Context, bookingID uint64) (*bookingRef, error) {
	var b bookingRef
	err := r.db.WithContext(ctx).Where("id = ?", bookingID).First(&b).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrBookingNotFound
	}
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *Repository) InsertMaterial(ctx context.Context, m *Material) error {
	return r.db.WithContext(ctx).Create(m).Error
}

// ListByBooking returns a booking's materials, newest first.
func (r *Repository) ListByBooking(ctx context.Context, bookingID uint64) ([]Material, error) {
	var out []Material
	err := r.db.WithContext(ctx).
		Where("booking_id = ?", bookingID).
		Order("created_at DESC").
		Find(&out).Error
	return out, err
}

func (r *Repository) FindMaterial(ctx context.Context, id uint64) (*Material, error) {
	var m Material
	err := r.db.WithContext(ctx).First(&m, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrMaterialNotFound
	}
	if err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *Repository) DeleteMaterial(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&Material{}, id).Error
}
