package children

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"time"
)

// inviteTTL is how long a freshly minted invite code stays valid. Roughly the
// two-week window the mockup shows ("Hết hạn 10/06/2026").
const inviteTTL = 14 * 24 * time.Hour

// inviteAlphabet excludes I/O/0/1 so codes are unambiguous when read aloud or
// typed by hand.
const inviteAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

func (s *Service) List(ctx context.Context, parentID uint64) ([]Student, error) {
	return s.repo.ListByParent(ctx, parentID)
}

// CreateInvite registers a child profile in `pending` status with a fresh,
// shareable invite code. The code surfaces under "Lời mời đang chờ" in My
// Children; the child accepts it to move to `connected`.
func (s *Service) CreateInvite(ctx context.Context, parentID uint64, name, grade, school string) (*Student, error) {
	code, err := generateInviteCode()
	if err != nil {
		return nil, err
	}
	exp := time.Now().UTC().Add(inviteTTL)
	st := &Student{
		ParentID:        parentID,
		Name:            name,
		Status:          StatusPending,
		InviteCode:      &code,
		InviteExpiresAt: &exp,
	}
	if grade != "" {
		st.Grade = &grade
	}
	if school != "" {
		st.School = &school
	}
	if err := s.repo.Create(ctx, st); err != nil {
		return nil, err
	}
	return st, nil
}

// Connect accepts an invite code for one of the parent's own pending children
// and marks it connected. In the single-app build this stands in for the child
// confirming the link on their device.
func (s *Service) Connect(ctx context.Context, parentID uint64, code string) (*Student, error) {
	st, err := s.repo.FindByCodeForParent(ctx, parentID, code)
	if err != nil {
		return nil, err
	}
	if st.Status == StatusConnected {
		return nil, ErrAlreadyConnected
	}
	if st.InviteExpiresAt != nil && time.Now().UTC().After(*st.InviteExpiresAt) {
		return nil, ErrInviteExpired
	}
	st.Status = StatusConnected
	st.InviteCode = nil
	st.InviteExpiresAt = nil
	if err := s.repo.Save(ctx, st); err != nil {
		return nil, err
	}
	return st, nil
}

// RegenerateInvite mints a fresh code+expiry for a pending child, e.g. after the
// previous code lapsed. Connected children have no code to regenerate.
func (s *Service) RegenerateInvite(ctx context.Context, parentID, childID uint64) (*Student, error) {
	st, err := s.repo.FindByID(ctx, childID)
	if err != nil {
		return nil, err
	}
	if st.ParentID != parentID {
		return nil, ErrForbidden
	}
	if st.Status == StatusConnected {
		return nil, ErrAlreadyConnected
	}
	code, err := generateInviteCode()
	if err != nil {
		return nil, err
	}
	exp := time.Now().UTC().Add(inviteTTL)
	st.InviteCode = &code
	st.InviteExpiresAt = &exp
	if err := s.repo.Save(ctx, st); err != nil {
		return nil, err
	}
	return st, nil
}

// Remove deletes a child profile (pending invite or connected child) the parent owns.
func (s *Service) Remove(ctx context.Context, parentID, childID uint64) error {
	st, err := s.repo.FindByID(ctx, childID)
	if err != nil {
		return err
	}
	if st.ParentID != parentID {
		return ErrForbidden
	}
	return s.repo.Delete(ctx, childID)
}

// generateInviteCode returns a code like "VN-2026-8K3M": a VN prefix, the
// current UTC year, and four random alphabet chars.
func generateInviteCode() (string, error) {
	b := make([]byte, 4)
	for i := range b {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(inviteAlphabet))))
		if err != nil {
			return "", err
		}
		b[i] = inviteAlphabet[n.Int64()]
	}
	return fmt.Sprintf("VN-%d-%s", time.Now().UTC().Year(), string(b)), nil
}
