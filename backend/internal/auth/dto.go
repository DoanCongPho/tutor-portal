package auth

type RegisterStartRequest struct {
	Phone string `json:"phone" binding:"required,min=8,max=20"`
	Role  string `json:"role"  binding:"required,oneof=tutor parent"`
	Name  string `json:"name"  binding:"required,max=255"`
}

type RegisterVerifyRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code"  binding:"required,len=6,numeric"`
}

type LoginStartRequest struct {
	Phone string `json:"phone" binding:"required"`
}

type LoginVerifyRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code"  binding:"required,len=6,numeric"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type OTPSentResponse struct {
	ExpiresInSeconds int `json:"expires_in_seconds"`
}

type UserDTO struct {
	ID    uint64 `json:"id"`
	Phone string `json:"phone,omitempty"`
	Email string `json:"email,omitempty"`
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
	if u.Phone != nil {
		dto.Phone = *u.Phone
	}
	if u.Email != nil {
		dto.Email = *u.Email
	}
	return dto
}
