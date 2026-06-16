package material

import "errors"

var (
	ErrMaterialNotFound = errors.New("material: not found")
	ErrBookingNotFound  = errors.New("material: booking not found")
	ErrProfileNotFound  = errors.New("material: tutor profile not found")
	ErrStudentNotFound  = errors.New("material: student record not found")

	// ErrForbidden covers both "not your booking" (tutor posting to a booking
	// they don't own) and "not your course" (a child/parent reading a booking
	// they aren't party to).
	ErrForbidden = errors.New("material: not allowed for this booking")

	ErrInvalidType        = errors.New("material: invalid material type")
	ErrDeadlineNotAllowed = errors.New("material: only assignments may carry a deadline")
)
