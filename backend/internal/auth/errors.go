package auth

import "errors"

var (
	ErrEmailAlreadyExists = errors.New("auth: email already exists")
	ErrPhoneAlreadyExists = errors.New("auth: phone already exists")
	ErrUserNotFound       = errors.New("auth: user not found")
	// ErrInvalidCredentials is deliberately vague (no "user not found" vs "wrong
	// password" distinction) so login can't be used to enumerate email addresses.
	ErrInvalidCredentials = errors.New("auth: invalid email or password")
	ErrAccountSuspended   = errors.New("auth: account suspended")
	// ErrInvalidOTP covers both a wrong code and a missing/expired pending
	// registration — deliberately undistinguished so the verify endpoint can't be
	// used to probe which email addresses have a registration in flight.
	ErrInvalidOTP     = errors.New("auth: invalid or expired code")
	ErrInvalidToken   = errors.New("auth: invalid token")
	ErrSessionExpired = errors.New("auth: session replaced by a newer login")

	// ErrGoogleTokenInvalid covers any failure verifying the client's Google ID
	// token (bad signature, wrong audience, expired). Deliberately undistinguished.
	ErrGoogleTokenInvalid = errors.New("auth: invalid google token")
	// ErrGoogleEmailUnverified is returned when Google reports the account's email
	// as unverified — we never create an account on an unverified email.
	ErrGoogleEmailUnverified = errors.New("auth: google email not verified")
	// ErrInvalidRegistrationToken covers a missing/expired pending Google
	// registration when completing role selection.
	ErrInvalidRegistrationToken = errors.New("auth: invalid or expired registration token")
)
