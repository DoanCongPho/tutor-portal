package children

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

// ListByParent returns all of a parent's children (pending + connected), newest
// first so freshly added ones surface at the top of the list.
func (r *Repository) ListByParent(ctx context.Context, parentID uint64) ([]Student, error) {
	var list []Student
	err := r.db.WithContext(ctx).
		Where("parent_id = ?", parentID).
		Order("created_at DESC").
		Find(&list).Error
	return list, err
}

func (r *Repository) FindByID(ctx context.Context, id uint64) (*Student, error) {
	var s Student
	err := r.db.WithContext(ctx).First(&s, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrChildNotFound
	}
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// FindByCodeForParent looks up a pending invite by code, scoped to the parent so
// one parent can never accept another parent's code.
func (r *Repository) FindByCodeForParent(ctx context.Context, parentID uint64, code string) (*Student, error) {
	var s Student
	err := r.db.WithContext(ctx).
		Where("parent_id = ? AND invite_code = ?", parentID, code).
		First(&s).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrInviteNotFound
	}
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *Repository) Create(ctx context.Context, s *Student) error {
	return r.db.WithContext(ctx).Create(s).Error
}

// Save persists a full row. Used to flip status and to NULL out the invite
// columns on connect — GORM writes nil pointers as NULL.
func (r *Repository) Save(ctx context.Context, s *Student) error {
	return r.db.WithContext(ctx).Save(s).Error
}

func (r *Repository) Delete(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&Student{}, id).Error
}
