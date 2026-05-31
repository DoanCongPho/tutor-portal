package auth

// RegisterRequest is step one of email signup. Email is the verified login
// identity (an OTP is mailed to it); phone is collected for contact but is
// optional and never verified in v1.
type RegisterRequest struct {
	Email    string `json:"email"    binding:"required,email,max=255"`
	Phone    string `json:"phone"    binding:"omitempty,min=8,max=20"`
	Role     string `json:"role"     binding:"required,oneof=tutor parent student"`
	Name     string `json:"name"     binding:"required,max=255"`
	Password string `json:"password" binding:"required,min=8,max=72"`
}

// VerifyRegistrationRequest completes the second step of email signup. The code
// is the 6-digit OTP delivered by email in response to RegisterRequest.
type VerifyRegistrationRequest struct {
	Email string `json:"email" binding:"required,email"`
	Code  string `json:"code"  binding:"required,len=6"`
}

// PendingRegistrationResponse is the body for a successful StartRegistration. No
// tokens are issued yet — the client must submit the OTP via VerifyRegistration.
type PendingRegistrationResponse struct {
	Email   string `json:"email"`
	Message string `json:"message"`
}

type LoginRequest struct {
	Email    string `json:"email"    binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type UserDTO struct {
	ID    uint64 `json:"id"`
	Email string `json:"email,omitempty"`
	Phone string `json:"phone,omitempty"`
	Role  string `json:"role"`
	Name  string `json:"name"`
}

type TokenResponse struct {
	AccessToken             string  `json:"access_token"`
	RefreshToken            string  `json:"refresh_token"`
	AccessExpiresInSeconds  int     `json:"access_expires_in_seconds"`
	RefreshExpiresInSeconds int     `json:"refresh_expires_in_seconds"`
	User                    UserDTO `json:"user"`
}

func toUserDTO(u *User) UserDTO {
	dto := UserDTO{ID: u.ID, Role: u.Role, Name: u.Name}
	if u.Email != nil {
		dto.Email = *u.Email
	}
	if u.Phone != nil {
		dto.Phone = *u.Phone
	}
	return dto
}
