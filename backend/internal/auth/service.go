package auth

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"strconv"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/DoanCongPho/tutor-portal/backend/pkg/email"
	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

const otpTTL = 5 * time.Minute

type Service struct {
	repo   *Repository
	kv     kvStore
	signer *pkgjwt.Signer
	mailer email.Sender
}

func NewService(repo *Repository, kv kvStore, signer *pkgjwt.Signer, mailer email.Sender) *Service {
	return &Service{repo: repo, kv: kv, signer: signer, mailer: mailer}
}

type AuthResult struct {
	Access           string
	Refresh          string
	AccessExpiresIn  time.Duration
	RefreshExpiresIn time.Duration
	User             *User
}

// pendingRegistration is the signup state stashed in the KV store between
// StartRegistration and VerifyRegistration. The password is already bcrypt-hashed
// here — plaintext never persists, not even for the short pending window. Phone
// is optional (it's collected for contact but never OTP-verified).
type pendingRegistration struct {
	Email        string `json:"email"`
	Phone        string `json:"phone"`
	Role         string `json:"role"`
	Name         string `json:"name"`
	PasswordHash string `json:"password_hash"`
	Code         string `json:"code"`
}

// StartRegistration begins email-based signup. It hashes the password, stashes a
// pending registration keyed by email in the KV store with a short TTL, and emails
// a one-time code. No user row is created until the code is confirmed via
// VerifyRegistration; the email must not already belong to an account. Phone, if
// supplied, is carried through but not verified.
func (s *Service) StartRegistration(ctx context.Context, email, phone, role, name, password string) error {
	if _, err := s.repo.FindByEmail(ctx, email); err == nil {
		return ErrEmailAlreadyExists
	} else if !errors.Is(err, ErrUserNotFound) {
		return err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	code, err := generateOTP()
	if err != nil {
		return err
	}
	payload, err := json.Marshal(pendingRegistration{
		Email:        email,
		Phone:        phone,
		Role:         role,
		Name:         name,
		PasswordHash: string(hash),
		Code:         code,
	})
	if err != nil {
		return err
	}
	if err := s.kv.Set(ctx, registerKey(email), payload, otpTTL); err != nil {
		return err
	}
	subject := "Your TutorMatch verification code"
	body := fmt.Sprintf("Your TutorMatch verification code is %s. It expires in %d minutes.", code, int(otpTTL.Minutes()))
	return s.mailer.Send(ctx, email, subject, body)
}

// VerifyRegistration completes signup: it matches the code against the pending
// registration, creates the user from the stashed details, drops the pending
// entry, and issues a token pair. A missing/expired pending entry or a wrong
// code both return ErrInvalidOTP (no distinction, to avoid leaking which it was).
func (s *Service) VerifyRegistration(ctx context.Context, email, code string) (*AuthResult, error) {
	key := registerKey(email)
	raw, err := s.kv.Get(ctx, key)
	if errors.Is(err, errKVNotFound) {
		return nil, ErrInvalidOTP
	}
	if err != nil {
		return nil, err
	}
	var pending pendingRegistration
	if err := json.Unmarshal(raw, &pending); err != nil {
		return nil, err
	}
	if pending.Code != code {
		return nil, ErrInvalidOTP
	}

	emailVal := pending.Email
	user := &User{
		Role:         pending.Role,
		Name:         pending.Name,
		Email:        &emailVal,
		PasswordHash: pending.PasswordHash,
		Status:       StatusActive,
	}
	// Phone is optional — only attach it when one was supplied so we don't write
	// an empty string into a UNIQUE column (which would collide across accounts).
	if pending.Phone != "" {
		phoneVal := pending.Phone
		user.Phone = &phoneVal
	}
	if err := s.repo.Create(ctx, user); err != nil {
		return nil, err
	}
	_ = s.kv.Del(ctx, key)
	return s.issueTokens(ctx, user)
}

// Login verifies the email+password pair and issues a token pair. Both the
// "email not found" and "wrong password" paths return ErrInvalidCredentials so
// the endpoint can't be used to probe which email addresses are registered.
func (s *Service) Login(ctx context.Context, email, password string) (*AuthResult, error) {
	user, err := s.repo.FindByEmail(ctx, email)
	if errors.Is(err, ErrUserNotFound) {
		return nil, ErrInvalidCredentials
	}
	if err != nil {
		return nil, err
	}
	if user.Status == StatusSuspended {
		return nil, ErrAccountSuspended
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}
	return s.issueTokens(ctx, user)
}

func (s *Service) Refresh(ctx context.Context, refreshToken string) (*AuthResult, error) {
	claims, err := s.signer.Verify(refreshToken)
	if err != nil {
		return nil, ErrInvalidToken
	}
	if claims.Type != pkgjwt.TypeRefresh {
		return nil, ErrInvalidToken
	}
	userID, err := claims.UserID()
	if err != nil {
		return nil, ErrInvalidToken
	}
	stored, err := s.kv.Get(ctx, sessionKey(userID))
	if err != nil || string(stored) != claims.ID {
		return nil, ErrSessionExpired
	}
	user, err := s.repo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user.Status == StatusSuspended {
		return nil, ErrAccountSuspended
	}
	return s.issueTokens(ctx, user)
}

func (s *Service) issueTokens(ctx context.Context, user *User) (*AuthResult, error) {
	pair, err := s.signer.Sign(user.ID, user.Role)
	if err != nil {
		return nil, err
	}
	// Single-device per PRD §5.1: store latest refresh jti so prior sessions are
	// implicitly invalidated when a new login or refresh happens.
	if err := s.kv.Set(ctx, sessionKey(user.ID), []byte(pair.RefreshJTI), s.signer.RefreshTTL); err != nil {
		return nil, err
	}
	return &AuthResult{
		Access:           pair.Access,
		Refresh:          pair.Refresh,
		AccessExpiresIn:  s.signer.AccessTTL,
		RefreshExpiresIn: s.signer.RefreshTTL,
		User:             user,
	}, nil
}

func registerKey(email string) string { return "auth:register:" + email }
func sessionKey(userID uint64) string { return "auth:session:" + strconv.FormatUint(userID, 10) }

func generateOTP() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}
