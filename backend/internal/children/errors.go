package children

import "errors"

var (
	ErrChildNotFound    = errors.New("children: child not found")
	ErrInviteNotFound   = errors.New("children: invite code not found")
	ErrInviteExpired    = errors.New("children: invite code expired")
	ErrAlreadyConnected = errors.New("children: child already connected")
	// ErrForbidden is returned when a parent acts on a child row that isn't theirs.
	ErrForbidden = errors.New("children: not the parent of this child")
)
