package booking

import "time"

// Booking statuses (bookings.status enum). This list is exhaustive — the cancel
// subtypes are deliberately distinct because reporting and tutor-reliability
// scoring depend on the distinction (CancelledByMatch must not count against a
// tutor). Do not collapse them.
const (
	StatusPending     = "pending"
	StatusConfirmed   = "confirmed"
	StatusInProgress  = "in_progress"
	LevelMiddleSchool = "middle_school"
	LevelHighSchool   = "high_school"
	LevelUniversity   = "university"
)

// Booking maps the `bookings` table. Amounts are stored as whole VND
// (DECIMAL(_,0)); PlatformFee is nullable until the fee is assessed. Escrow is
// locked at creation (PENDING), not confirmation — see docs/prd.md §5.7.
type Booking struct {
	ID           uint64    `gorm:"primaryKey"`
	TutorID      uint64    `gorm:"column:tutor_id;not null"`
	StudentID    uint64    `gorm:"column:student_id;not null"`
	ParentID     uint64    `gorm:"column:parent_id;not null"`
	Subject      string    `gorm:"column:subject;not null"`
	Level        string    `gorm:"column:level;not null"`
	SlotDatetime time.Time `gorm:"column:slot_datetime;not null"`
	DurationMins uint16    `gorm:"column:duration_mins;not null;default:60"`
	Status       string    `gorm:"column:status;not null;default:'pending'"`
	Amount       int64     `gorm:"column:amount;not null"`
	PlatformFee  *int64    `gorm:"column:platform_fee"`
	CreatedAt    time.Time `gorm:"column:created_at"`
	UpdatedAt    time.Time `gorm:"column:updated_at"`
}

func (Booking) TableName() string { return "bookings" }

// Review maps the `reviews` table. A review unlocks only when its booking
// reaches PAID, exactly one per booking (UNIQUE(booking_id)). Writing a review
// also updates rating_avg/rating_count on tutor_profiles — that is the review
// flow's responsibility, not this model's.
type Review struct {
	ID        uint64    `gorm:"primaryKey"`
	BookingID uint64    `gorm:"column:booking_id;uniqueIndex"`
	ParentID  uint64    `gorm:"column:parent_id;not null"`
	TutorID   uint64    `gorm:"column:tutor_id;not null"`
	Rating    uint8     `gorm:"column:rating;not null"`
	Comment   *string   `gorm:"column:comment"`
	CreatedAt time.Time `gorm:"column:created_at"`
}

func (Review) TableName() string { return "reviews" }
