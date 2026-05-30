package auth

import "errors"

var (
	ErrPhoneAlreadyExists = errors.New("auth: phone already exists")
	ErrUserNotFound       = errors.New("auth: user not found")
	ErrInvalidOTP         = errors.New("auth: invalid or expired otp")
	ErrAccountSuspended   = errors.New("auth: account suspended")
	ErrInvalidToken       = errors.New("auth: invalid token")
	ErrSessionExpired     = errors.New("auth: session replaced by a newer login")
)
