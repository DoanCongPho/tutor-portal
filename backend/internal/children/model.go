package children

import "time"

const (
	// StatusPending: a child profile exists with an outstanding invite_code that
	// has not been accepted yet. StatusConnected: the invite was accepted and the
	// child is linked to the parent (UserID points at the child's own account).
	StatusPending   = "pending"
	StatusConnected = "connected"
)

// Student maps the `students` table. In the connect model (see the "Add Child"
// mockup) a child starts as `pending` carrying an invite code the parent shares;
// once accepted it becomes `connected` and UserID links the child's account.
type Student struct {
	ID              uint64     `gorm:"primaryKey"`
	ParentID        uint64     `gorm:"column:parent_id;not null"`
	Name            string     `gorm:"column:name;not null"`
	Grade           *string    `gorm:"column:grade"`
	School          *string    `gorm:"column:school"`
	Status          string     `gorm:"column:status;not null;default:'pending'"`
	UserID          *uint64    `gorm:"column:user_id"`
	InviteCode      *string    `gorm:"column:invite_code"`
	InviteExpiresAt *time.Time `gorm:"column:invite_expires_at"`
	CreatedAt       time.Time  `gorm:"column:created_at"`
	UpdatedAt       time.Time  `gorm:"column:updated_at"`
}

func (Student) TableName() string { return "students" }
