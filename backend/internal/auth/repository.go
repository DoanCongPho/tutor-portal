package auth

import (
	"context"
	"errors"
	"strings"

	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

func (r *Repository) FindByPhone(ctx context.Context, phone string) (*User, error) {
	var u User
	err := r.db.WithContext(ctx).Where("phone = ?", phone).First(&u).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *Repository) FindByEmail(ctx context.Context, email string) (*User, error) {
	var u User
	err := r.db.WithContext(ctx).Where("email = ?", email).First(&u).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// FindByGoogleSub looks a user up by their linked Google subject id — the most
// reliable match for a returning Google account (email can change; sub doesn't).
func (r *Repository) FindByGoogleSub(ctx context.Context, sub string) (*User, error) {
	var u User
	err := r.db.WithContext(ctx).Where("google_sub = ?", sub).First(&u).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// LinkGoogleSub attaches a Google subject id to an existing account (first time
// an email/password user signs in with Google on the same verified email).
func (r *Repository) LinkGoogleSub(ctx context.Context, id uint64, sub string) error {
	return r.db.WithContext(ctx).Model(&User{}).Where("id = ?", id).
		Update("google_sub", sub).Error
}

func (r *Repository) FindByID(ctx context.Context, id uint64) (*User, error) {
	var u User
	err := r.db.WithContext(ctx).First(&u, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *Repository) Create(ctx context.Context, u *User) error {
	err := r.db.WithContext(ctx).Create(u).Error
	// Email is the signup identity and is pre-checked in the service, so a
	// duplicate here is almost always a race on the same email. (Phone is also
	// UNIQUE but optional; a phone collision surfaces under the same error — rare
	// enough not to warrant parsing which key tripped.)
	if err != nil && isDuplicateKeyErr(err) {
		return ErrEmailAlreadyExists
	}
	return err
}

func (r *Repository) UpdateStatus(ctx context.Context, id uint64, status string) error {
	res := r.db.WithContext(ctx).Model(&User{}).Where("id = ?", id).Update("status", status)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return ErrUserNotFound
	}
	return nil
}

// MySQL error 1062 = duplicate entry. String-match is the cheapest portable check;
// switch to driver-specific error inspection if we ever care about the exact key.
func isDuplicateKeyErr(err error) bool {
	s := err.Error()
	return strings.Contains(s, "1062") || strings.Contains(s, "Duplicate entry")
}
