package tutor

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

// WithinTx runs fn inside a database transaction bound to ctx. GORM commits when
// fn returns nil and rolls back on any error or panic. The tx-scoped write
// methods below all take the *gorm.DB it hands fn.
func (r *Repository) WithinTx(ctx context.Context, fn func(tx *gorm.DB) error) error {
	return r.db.WithContext(ctx).Transaction(fn)
}

func (r *Repository) FindProfileByUserID(ctx context.Context, userID uint64) (*TutorProfile, error) {
	var p TutorProfile
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&p).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrProfileNotFound
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *Repository) FindUserByID(ctx context.Context, userID uint64) (*User, error) {
	var u User
	err := r.db.WithContext(ctx).First(&u, userID).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// LoadAggregate loads a profile with its subjects, documents, and schedule rows.
func (r *Repository) LoadAggregate(ctx context.Context, profileID uint64) (*TutorProfile, error) {
	var p TutorProfile
	err := r.db.WithContext(ctx).
		Preload("Subjects").
		Preload("Documents").
		Preload("Schedules").
		First(&p, profileID).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrProfileNotFound
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// UpdateUserPersonal updates the tutor's name and, when supplied, phone/avatar
// on the users row. A map is used (not a struct) so an explicit empty value is
// still written, while nil pointers are simply omitted — we never null phone or
// avatar just because the client didn't resend them.
//
// We do NOT treat RowsAffected == 0 as "user not found": onboarding prefills
// name/phone from the account, so re-submitting unchanged values is a no-op
// update that MySQL reports as 0 changed rows (the driver returns changed, not
// matched, rows). The caller is already authenticated, so the user is known to
// exist; failing here would wrongly roll back the whole onboarding transaction.
func (r *Repository) UpdateUserPersonal(tx *gorm.DB, userID uint64, name string, phone, avatarURL *string) error {
	fields := map[string]any{"name": name}
	if phone != nil {
		fields["phone"] = *phone
	}
	if avatarURL != nil {
		fields["avatar_url"] = *avatarURL
	}
	return tx.Model(&User{}).Where("id = ?", userID).Updates(fields).Error
}

// UpsertProfileByUserID creates the tutor profile or updates the existing one
// (keyed by the UNIQUE user_id). On update it touches only the onboarding-owned
// columns — hourly_rate, bio, verification_status — leaving rating_avg/
// rating_count/is_accepting alone. p.ID is set to the row's id on return.
func (r *Repository) UpsertProfileByUserID(tx *gorm.DB, p *TutorProfile) error {
	var existing TutorProfile
	err := tx.Where("user_id = ?", p.UserID).First(&existing).Error
	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		if err := tx.Create(p).Error; err != nil {
			if isDuplicateKeyErr(err) {
				return ErrProfileExists
			}
			return err
		}
		return nil
	case err != nil:
		return err
	}
	p.ID = existing.ID
	return tx.Model(&TutorProfile{}).Where("id = ?", existing.ID).Updates(map[string]any{
		"hourly_rate":         p.HourlyRate,
		"bio":                 p.Bio,
		"verification_status": p.VerificationStatus,
	}).Error
}

func (r *Repository) DeleteSubjectsByTutor(tx *gorm.DB, tutorID uint64) error {
	return tx.Where("tutor_id = ?", tutorID).Delete(&TutorSubject{}).Error
}

func (r *Repository) InsertSubjects(tx *gorm.DB, subjects []TutorSubject) error {
	if len(subjects) == 0 {
		return nil
	}
	return tx.Create(&subjects).Error
}

func (r *Repository) DeleteSchedulesByTutor(tx *gorm.DB, tutorID uint64) error {
	return tx.Where("tutor_id = ?", tutorID).Delete(&Schedule{}).Error
}

func (r *Repository) InsertSchedules(tx *gorm.DB, slots []Schedule) error {
	if len(slots) == 0 {
		return nil
	}
	return tx.Create(&slots).Error
}

// InsertDocuments appends credential documents. Onboarding does not delete prior
// documents — re-submission after a rejection adds the re-uploaded files while
// preserving the admin_note/verified_at history on existing rows.
func (r *Repository) InsertDocuments(tx *gorm.DB, docs []TutorDocument) error {
	if len(docs) == 0 {
		return nil
	}
	return tx.Create(&docs).Error
}

// isDuplicateKeyErr matches MySQL error 1062 (duplicate entry). Mirrors the
// auth repository's check.
func isDuplicateKeyErr(err error) bool {
	s := err.Error()
	return strings.Contains(s, "1062") || strings.Contains(s, "Duplicate entry")
}
