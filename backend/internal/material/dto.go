package material

import "time"

// CreateMaterialRequest is the tutor's payload to attach a learning-portal
// document to one of their bookings (PRD §5.8 "Tutor uploads"). The booking is
// the "course": the material's student is taken from the booking, so the client
// never sends a student id. FileURL is a plain URL in v1 (direct upload is not
// wired yet); Deadline is permitted only when Type is "assignment".
type CreateMaterialRequest struct {
	BookingID uint64     `json:"booking_id" binding:"required"`
	Type      string     `json:"type"       binding:"required,oneof=slide note assignment"`
	Title     string     `json:"title"      binding:"required,max=255"`
	FileURL   string     `json:"file_url"   binding:"omitempty,max=500"`
	Deadline  *time.Time `json:"deadline"   binding:"omitempty"`
}

// MaterialResponse is the API view of a materials row.
type MaterialResponse struct {
	ID        uint64     `json:"id"`
	BookingID *uint64    `json:"booking_id,omitempty"`
	TutorID   uint64     `json:"tutor_id"`
	StudentID uint64     `json:"student_id"`
	Type      string     `json:"type"`
	Title     string     `json:"title"`
	FileURL   string     `json:"file_url,omitempty"`
	Deadline  *time.Time `json:"deadline,omitempty"`
	CreatedAt time.Time  `json:"created_at"`
}

func toMaterialResponse(m *Material) MaterialResponse {
	resp := MaterialResponse{
		ID:        m.ID,
		BookingID: m.BookingID,
		TutorID:   m.TutorID,
		StudentID: m.StudentID,
		Type:      m.Type,
		Title:     m.Title,
		Deadline:  m.Deadline,
		CreatedAt: m.CreatedAt,
	}
	if m.FileURL != nil {
		resp.FileURL = *m.FileURL
	}
	return resp
}
