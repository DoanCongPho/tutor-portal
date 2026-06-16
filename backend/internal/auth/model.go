package auth

import "time"

const (
	RoleTutor   = "tutor"
	RoleParent  = "parent"
	RoleStudent = "student"
	RoleAdmin   = "admin"

	StatusActive    = "active"
	StatusSuspended = "suspended"

	// Auth providers (users.auth_provider enum). Password accounts sign in with
	// email+password; Google accounts via a verified Google ID token. A password
	// account that later links Google keeps provider 'password' but gains a
	// non-null google_sub.
	ProviderPassword = "password"
	ProviderGoogle   = "google"
)

type User struct {
	ID           uint64    `gorm:"primaryKey"`
	Role         string    `gorm:"column:role;not null"`
	Name         string    `gorm:"column:name;not null"`
	Phone        *string   `gorm:"column:phone"`
	Email        *string   `gorm:"column:email;uniqueIndex"`
	PasswordHash string    `gorm:"column:password_hash;not null"`
	AuthProvider string    `gorm:"column:auth_provider;not null;default:'password'"`
	GoogleSub    *string   `gorm:"column:google_sub"`
	AvatarURL    *string   `gorm:"column:avatar_url"`
	Status       string    `gorm:"column:status;not null;default:'active'"`
	CreatedAt    time.Time `gorm:"column:created_at"`
	UpdatedAt    time.Time `gorm:"column:updated_at"`
}

func (User) TableName() string { return "users" }
