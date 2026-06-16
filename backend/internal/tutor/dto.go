package tutor

import "time"

// SubmitOnboardingRequest is the single payload that completes tutor onboarding
// (PRD §5.2). It carries every step at once: personal info (name/phone/avatar →
// users row), hourly rate + bio + subjects + documents + schedule. The handler
// binds it; the service validates the controlled vocabulary and rate/time
// ranges before persisting the whole thing in one transaction.
//
// File uploads are out of scope for v1: documents carry plain file_url strings
// (a future S3 upload step returns the URL the client puts here).
type SubmitOnboardingRequest struct {
	Name      string `json:"name"       binding:"required,max=255"`
	Phone     string `json:"phone"      binding:"omitempty,min=8,max=20"`
	AvatarURL string `json:"avatar_url" binding:"omitempty,max=500"`

	HourlyRate uint64 `json:"hourly_rate" binding:"required,gt=0"`
	Bio        string `json:"bio"         binding:"omitempty,max=5000"`

	Subjects []SubjectInput  `json:"subjects"  binding:"required,min=1,dive"`
	Schedule []ScheduleInput `json:"schedule"  binding:"required,min=1,dive"`
}

type SubjectInput struct {
	Subject string `json:"subject" binding:"required,max=100"`
	Level   string `json:"level"   binding:"required,oneof=primary middle_school high_school university"`
}

type DocumentInput struct {
	DocType string `json:"doc_type" binding:"required,oneof=degree certificate national_id"`
	FileURL string `json:"file_url" binding:"required,max=500"`
}

type ScheduleInput struct {
	// DayOfWeek is intentionally validated min/max without `required`: 0 (Sunday)
	// is a valid value that `required` would reject as the zero value.
	DayOfWeek int8   `json:"day_of_week" binding:"min=0,max=6"`
	StartTime string `json:"start_time"  binding:"required"`
	EndTime   string `json:"end_time"    binding:"required"`
}

// TutorProfileResponse is the full onboarding aggregate returned by the submit
// and GET /tutors/me endpoints. Name/phone/avatar are pulled from the users row.
type TutorProfileResponse struct {
	ID                 uint64        `json:"id"`
	UserID             uint64        `json:"user_id"`
	Name               string        `json:"name"`
	Phone              string        `json:"phone,omitempty"`
	AvatarURL          string        `json:"avatar_url,omitempty"`
	HourlyRate         uint64        `json:"hourly_rate"`
	Bio                string        `json:"bio,omitempty"`
	IsAccepting        bool          `json:"is_accepting"`
	VerificationStatus string        `json:"verification_status"`
	RatingAvg          float64       `json:"rating_avg"`
	RatingCount        uint          `json:"rating_count"`
	Subjects           []SubjectDTO  `json:"subjects"`
	Documents          []DocumentDTO `json:"documents"`
	Schedule           []ScheduleDTO `json:"schedule"`
	CreatedAt          time.Time     `json:"created_at"`
	UpdatedAt          time.Time     `json:"updated_at"`
}

type SubjectDTO struct {
	Subject string `json:"subject"`
	Level   string `json:"level"`
}

type DocumentDTO struct {
	ID         uint64     `json:"id"`
	DocType    string     `json:"doc_type"`
	FileURL    string     `json:"file_url"`
	UploadedAt time.Time  `json:"uploaded_at"`
	VerifiedAt *time.Time `json:"verified_at,omitempty"`
}

type ScheduleDTO struct {
	DayOfWeek   int8   `json:"day_of_week"`
	StartTime   string `json:"start_time"`
	EndTime     string `json:"end_time"`
	IsAvailable bool   `json:"is_available"`
}

// toTutorProfileResponse maps the loaded aggregate plus the users row into the
// API contract. u supplies name/phone/avatar (deref the optional columns).
func toTutorProfileResponse(p *TutorProfile, u *User) TutorProfileResponse {
	resp := TutorProfileResponse{
		ID:                 p.ID,
		UserID:             p.UserID,
		HourlyRate:         p.HourlyRate,
		IsAccepting:        p.IsAccepting,
		VerificationStatus: p.VerificationStatus,
		RatingAvg:          p.RatingAvg,
		RatingCount:        p.RatingCount,
		Subjects:           make([]SubjectDTO, 0, len(p.Subjects)),
		Documents:          make([]DocumentDTO, 0, len(p.Documents)),
		Schedule:           make([]ScheduleDTO, 0, len(p.Schedules)),
		CreatedAt:          p.CreatedAt,
		UpdatedAt:          p.UpdatedAt,
	}
	if p.Bio != nil {
		resp.Bio = *p.Bio
	}
	if u != nil {
		resp.Name = u.Name
		if u.Phone != nil {
			resp.Phone = *u.Phone
		}
		if u.AvatarURL != nil {
			resp.AvatarURL = *u.AvatarURL
		}
	}
	for _, s := range p.Subjects {
		resp.Subjects = append(resp.Subjects, SubjectDTO{Subject: s.Subject, Level: s.Level})
	}
	for _, d := range p.Documents {
		resp.Documents = append(resp.Documents, DocumentDTO{
			ID:         d.ID,
			DocType:    d.DocType,
			FileURL:    d.FileURL,
			UploadedAt: d.UploadedAt,
			VerifiedAt: d.VerifiedAt,
		})
	}
	for _, sc := range p.Schedules {
		resp.Schedule = append(resp.Schedule, ScheduleDTO{
			DayOfWeek:   sc.DayOfWeek,
			StartTime:   sc.StartTime,
			EndTime:     sc.EndTime,
			IsAvailable: sc.IsAvailable,
		})
	}
	return resp
}
