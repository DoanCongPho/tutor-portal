package tutor

import "errors"

var (
	ErrProfileNotFound = errors.New("tutor: profile not found")
	ErrUserNotFound    = errors.New("tutor: user not found")
	ErrProfileExists   = errors.New("tutor: profile already exists")

	ErrInvalidSubject  = errors.New("tutor: subject not in allowed list")
	ErrInvalidLevel    = errors.New("tutor: invalid level")
	ErrInvalidDocType  = errors.New("tutor: invalid document type")
	ErrInvalidRate     = errors.New("tutor: hourly rate out of range")
	ErrInvalidSchedule = errors.New("tutor: invalid schedule slot")
)
