package children

import "time"

// CreateChildRequest registers a child profile and mints an invite code. Grade
// and school are optional metadata shown in the My Children list.
type CreateChildRequest struct {
	Name   string `json:"name"   binding:"required,max=255"`
	Grade  string `json:"grade"  binding:"omitempty,max=50"`
	School string `json:"school" binding:"omitempty,max=255"`
}

// ConnectRequest accepts an invite code (the "Enter Invite Code" flow).
type ConnectRequest struct {
	Code string `json:"code" binding:"required,max=20"`
}

// ChildDTO is the API view of a Student. InviteCode / InviteExpiresAt are only
// populated while the child is `pending` (they back the "Lời mời đang chờ"
// pending-invite card in the My Children mockup).
type ChildDTO struct {
	ID              uint64  `json:"id"`
	Name            string  `json:"name"`
	Grade           string  `json:"grade,omitempty"`
	School          string  `json:"school,omitempty"`
	Status          string  `json:"status"`
	InviteCode      string  `json:"invite_code,omitempty"`
	InviteExpiresAt *string `json:"invite_expires_at,omitempty"` // RFC3339 UTC
}

type ChildListResponse struct {
	Children []ChildDTO `json:"children"`
}

func toChildDTO(s *Student) ChildDTO {
	dto := ChildDTO{ID: s.ID, Name: s.Name, Status: s.Status}
	if s.Grade != nil {
		dto.Grade = *s.Grade
	}
	if s.School != nil {
		dto.School = *s.School
	}
	if s.InviteCode != nil {
		dto.InviteCode = *s.InviteCode
	}
	if s.InviteExpiresAt != nil {
		t := s.InviteExpiresAt.UTC().Format(time.RFC3339)
		dto.InviteExpiresAt = &t
	}
	return dto
}

func toChildDTOs(list []Student) []ChildDTO {
	out := make([]ChildDTO, 0, len(list))
	for i := range list {
		out = append(out, toChildDTO(&list[i]))
	}
	return out
}
