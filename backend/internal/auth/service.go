package auth

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math/big"
	"strconv"
	"time"

	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

const otpTTL = 5 * time.Minute

type Service struct {
	repo   *Repository
	kv     kvStore
	signer *pkgjwt.Signer
}

func NewService(repo *Repository, kv kvStore, signer *pkgjwt.Signer) *Service {
	return &Service{repo: repo, kv: kv, signer: signer}
}

type AuthResult struct {
	Access           string
	Refresh          string
	AccessExpiresIn  time.Duration
	RefreshExpiresIn time.Duration
	User             *User
}

type pendingRegistration struct {
	Phone string `json:"phone"`
	Role  string `json:"role"`
	Name  string `json:"name"`
	Code  string `json:"code"`
}

func (s *Service) StartRegistration(ctx context.Context, phone, role, name string) error {
	if _, err := s.repo.FindByPhone(ctx, phone); err == nil {
		return ErrPhoneAlreadyExists
	} else if !errors.Is(err, ErrUserNotFound) {
		return err
	}
	code, err := generateOTP()
	if err != nil {
		return err
	}
	payload, err := json.Marshal(pendingRegistration{Phone: phone, Role: role, Name: name, Code: code})
	if err != nil {
		return err
	}
	if err := s.kv.Set(ctx, registerKey(phone), payload, otpTTL); err != nil {
		return err
	}
	log.Printf("[auth] OTP register phone=%s code=%s ttl=%s", phone, code, otpTTL)
	return nil
}

func (s *Service) VerifyRegistration(ctx context.Context, phone, code string) (*AuthResult, error) {
	key := registerKey(phone)
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

	phoneVal := pending.Phone
	user := &User{
		Role:   pending.Role,
		Name:   pending.Name,
		Phone:  &phoneVal,
		Status: StatusActive,
	}
	if err := s.repo.Create(ctx, user); err != nil {
		return nil, err
	}
	_ = s.kv.Del(ctx, key)
	return s.issueTokens(ctx, user)
}

func (s *Service) StartLogin(ctx context.Context, phone string) error {
	user, err := s.repo.FindByPhone(ctx, phone)
	if err != nil {
		return err
	}
	if user.Status == StatusSuspended {
		return ErrAccountSuspended
	}
	code, err := generateOTP()
	if err != nil {
		return err
	}
	if err := s.kv.Set(ctx, loginKey(phone), []byte(code), otpTTL); err != nil {
		return err
	}
	log.Printf("[auth] OTP login phone=%s code=%s ttl=%s", phone, code, otpTTL)
	return nil
}

func (s *Service) VerifyLogin(ctx context.Context, phone, code string) (*AuthResult, error) {
	key := loginKey(phone)
	stored, err := s.kv.Get(ctx, key)
	if errors.Is(err, errKVNotFound) {
		return nil, ErrInvalidOTP
	}
	if err != nil {
		return nil, err
	}
	if string(stored) != code {
		return nil, ErrInvalidOTP
	}
	user, err := s.repo.FindByPhone(ctx, phone)
	if err != nil {
		return nil, err
	}
	if user.Status == StatusSuspended {
		return nil, ErrAccountSuspended
	}
	_ = s.kv.Del(ctx, key)
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

func registerKey(phone string) string { return "auth:register:" + phone }
func loginKey(phone string) string    { return "auth:login:" + phone }
func sessionKey(userID uint64) string { return "auth:session:" + strconv.FormatUint(userID, 10) }

func generateOTP() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}
