package material

import "time"

// Material types (materials.type enum). Only `assignment` materials can carry a
// deadline and receive submissions.
const (
	TypeSlide      = "slide"
	TypeNote       = "note"
	TypeAssignment = "assignment"
)

// Submission statuses (submissions.status enum).
const (
	SubmissionSubmitted = "submitted"
	SubmissionOverdue   = "overdue"
)

// Material maps the `materials` table — a slide/note/assignment a tutor shares
// with a student. BookingID is nullable (material can exist outside a single
// booking); FileURL is nullable for text-only notes; Deadline applies to
// assignments only.
type Material struct {
	ID        uint64     `gorm:"primaryKey"`
	TutorID   uint64     `gorm:"column:tutor_id;not null"`
	StudentID uint64     `gorm:"column:student_id;not null"`
	BookingID *uint64    `gorm:"column:booking_id"`
	Type      string     `gorm:"column:type;not null"`
	FileURL   *string    `gorm:"column:file_url"`
	Title     string     `gorm:"column:title;not null"`
	Deadline  *time.Time `gorm:"column:deadline"`
	CreatedAt time.Time  `gorm:"column:created_at"`
}

func (Material) TableName() string { return "materials" }

// Submission maps the `submissions` table — a student's response to an
// assignment material. AssignmentID references materials(id) (a row whose
// type is `assignment`).
type Submission struct {
	ID           uint64    `gorm:"primaryKey"`
	AssignmentID uint64    `gorm:"column:assignment_id;not null"`
	StudentID    uint64    `gorm:"column:student_id;not null"`
	FileURL      string    `gorm:"column:file_url;not null"`
	SubmittedAt  time.Time `gorm:"column:submitted_at"`
	Status       string    `gorm:"column:status;not null;default:'submitted'"`
}

func (Submission) TableName() string { return "submissions" }

// --- Cross-module read models -------------------------------------------------
//
// Authorizing a material means matching the caller against rows owned by other
// modules: a material's tutor_id references tutor_profiles.id, its student_id
// references students.id, and a booking ties tutor↔student↔parent together.
// Rather than depend on those packages, the repository reads only the few
// columns it needs through these minimal, read-only structs. They are never
// written here.

// tutorProfileRef resolves the authenticated tutor's user id to the
// tutor_profiles.id that materials.tutor_id (and bookings.tutor_id) reference.
type tutorProfileRef struct {
	ID     uint64 `gorm:"column:id"`
	UserID uint64 `gorm:"column:user_id"`
}

func (tutorProfileRef) TableName() string { return "tutor_profiles" }

// studentRef resolves a connected child's own user account to the students.id
// that materials.student_id (and bookings.student_id) reference. UserID is
// nullable: a child stays unlinked until it accepts its parent's invite.
type studentRef struct {
	ID     uint64  `gorm:"column:id"`
	UserID *uint64 `gorm:"column:user_id"`
}

func (studentRef) TableName() string { return "students" }

// bookingRef is the slice of a booking needed to decide who may read or write
// its materials: the booking is the "course", so its tutor, child, and parent
// are exactly the parties with access.
type bookingRef struct {
	ID        uint64 `gorm:"column:id"`
	TutorID   uint64 `gorm:"column:tutor_id"`
	StudentID uint64 `gorm:"column:student_id"`
	ParentID  uint64 `gorm:"column:parent_id"`
}

func (bookingRef) TableName() string { return "bookings" }
