package tutor

import "time"

// Verification states (tutor_profiles.verification_status enum).
const (
	VerificationPending  = "pending_review"
	VerificationDocs     = "requires_documents"
	VerificationVerified = "verified"
	VerificationRejected = "rejected"
)

// Teaching levels (tutor_subjects.level / bookings.level enum).
const (
	LevelPrimary      = "primary"
	LevelMiddleSchool = "middle_school"
	LevelHighSchool   = "high_school"
	LevelUniversity   = "university"
)

// Credential document types (tutor_documents.doc_type enum).
const (
	DocDegree      = "degree"
	DocCertificate = "certificate"
	DocNationalID  = "national_id"
)

// TutorProfile maps tutor_profiles. RatingAvg/RatingCount are maintained by the
// review flow and are never written during onboarding. Subjects/Documents/
// Schedules are association fields used for eager-loading the aggregate.
type TutorProfile struct {
	ID                 uint64    `gorm:"primaryKey"`
	UserID             uint64    `gorm:"column:user_id;uniqueIndex"`
	HourlyRate         uint64    `gorm:"column:hourly_rate"`
	Bio                *string   `gorm:"column:bio"`
	IsAccepting        bool      `gorm:"column:is_accepting;default:true"`
	VerificationStatus string    `gorm:"column:verification_status"`
	RatingAvg          float64   `gorm:"column:rating_avg"`
	RatingCount        uint      `gorm:"column:rating_count"`
	CreatedAt          time.Time `gorm:"column:created_at"`
	UpdatedAt          time.Time `gorm:"column:updated_at"`

	Subjects  []TutorSubject  `gorm:"foreignKey:TutorID"`
	Documents []TutorDocument `gorm:"foreignKey:TutorID"`
	Schedules []Schedule      `gorm:"foreignKey:TutorID"`
}

func (TutorProfile) TableName() string { return "tutor_profiles" }

// TutorSubject maps tutor_subjects — one row per (subject, level) the tutor
// teaches. UNIQUE(tutor_id, subject, level) is enforced by the schema.
type TutorSubject struct {
	ID      uint64 `gorm:"primaryKey"`
	TutorID uint64 `gorm:"column:tutor_id"`
	Subject string `gorm:"column:subject"`
	Level   string `gorm:"column:level"`
}

func (TutorSubject) TableName() string { return "tutor_subjects" }

// TutorDocument maps tutor_documents. VerifiedAt/AdminNote are written by the
// admin review flow, not by onboarding.
type TutorDocument struct {
	ID         uint64     `gorm:"primaryKey"`
	TutorID    uint64     `gorm:"column:tutor_id"`
	DocType    string     `gorm:"column:doc_type"`
	FileURL    string     `gorm:"column:file_url"`
	UploadedAt time.Time  `gorm:"column:uploaded_at"`
	VerifiedAt *time.Time `gorm:"column:verified_at"`
	AdminNote  *string    `gorm:"column:admin_note"`
}

func (TutorDocument) TableName() string { return "tutor_documents" }

// Schedule maps schedules — a weekly availability slot. StartTime/EndTime are
// "HH:MM:SS" strings (the MySQL TIME columns) to avoid carrying a phantom date.
type Schedule struct {
	ID          uint64 `gorm:"primaryKey"`
	TutorID     uint64 `gorm:"column:tutor_id"`
	DayOfWeek   int8   `gorm:"column:day_of_week"` // 0=Sunday .. 6=Saturday
	StartTime   string `gorm:"column:start_time"`
	EndTime     string `gorm:"column:end_time"`
	IsAvailable bool   `gorm:"column:is_available;default:true"`
}

func (Schedule) TableName() string { return "schedules" }

// User is a minimal projection of the users table used to read/update the
// tutor's personal info (name, phone, avatar) during onboarding step 1. The
// authoritative user model lives in the auth package — this is intentionally
// scoped to the columns this module touches.
type User struct {
	ID        uint64  `gorm:"primaryKey"`
	Name      string  `gorm:"column:name"`
	Phone     *string `gorm:"column:phone"`
	AvatarURL *string `gorm:"column:avatar_url"`
}

func (User) TableName() string { return "users" }
