package auth

import (
	"context"
	"crypto/rand"
	"encoding/hex"
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
	repo      *Repository
	kv        kvStore
	signer    *pkgjwt.Signer
	mailer    email.Sender
	gverifier googleVerifier
}

func NewService(repo *Repository, kv kvStore, signer *pkgjwt.Signer, mailer email.Sender, gverifier googleVerifier) *Service {
	return &Service{repo: repo, kv: kv, signer: signer, mailer: mailer, gverifier: gverifier}
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

// pendingGoogleRegistration is the verified-Google identity stashed between
// LoginWithGoogle (new email) and CompleteGoogleRegistration (role chosen). No
// password is stored — Google users get a random unusable hash at creation.
type pendingGoogleRegistration struct {
	Email string `json:"email"`
	Name  string `json:"name"`
	Sub   string `json:"sub"`
}

// GoogleAuthOutcome is the service-level result of a Google sign-in: either the
// user is known (Result holds issued tokens) or they are new (NeedsRole is true
// and RegistrationToken must be echoed back to /auth/google/complete with a role).
type GoogleAuthOutcome struct {
	NeedsRole         bool
	RegistrationToken string
	Result            *AuthResult
}

const googleRegTTL = 15 * time.Minute

// LoginWithGoogle verifies a Google ID token and, by verified email, either logs
// in an existing account (linking email/password and Google sign-in to the same
// user) or — for an unseen email — stashes a pending registration and asks the
// client to choose a role. No account is created here: a user without a role is
// never written, so the role column stays NOT NULL with no "pending" sentinel.
func (s *Service) LoginWithGoogle(ctx context.Context, idToken string) (*GoogleAuthOutcome, error) {
	identity, err := s.gverifier.Verify(ctx, idToken)
	if err != nil {
		return nil, err
	}
	if !identity.EmailVerified {
		return nil, ErrGoogleEmailUnverified
	}

	// 1. Most reliable: an account already linked to this Google subject id.
	if identity.Sub != "" {
		user, err := s.repo.FindByGoogleSub(ctx, identity.Sub)
		switch {
		case err == nil:
			return s.googleLoginExisting(ctx, user)
		case !errors.Is(err, ErrUserNotFound):
			return nil, err
		}
	}

	// 2. Same verified email → link Google to the existing account and log in.
	user, err := s.repo.FindByEmail(ctx, identity.Email)
	switch {
	case err == nil:
		if user.Status == StatusSuspended {
			return nil, ErrAccountSuspended
		}
		if user.GoogleSub == nil && identity.Sub != "" {
			if err := s.repo.LinkGoogleSub(ctx, user.ID, identity.Sub); err != nil {
				return nil, err
			}
		}
		result, err := s.issueTokens(ctx, user)
		if err != nil {
			return nil, err
		}
		return &GoogleAuthOutcome{Result: result}, nil
	case errors.Is(err, ErrUserNotFound):
		// 3. New user — defer creation until a role is chosen.
		token, err := generateRegistrationToken()
		if err != nil {
			return nil, err
		}
		payload, err := json.Marshal(pendingGoogleRegistration{
			Email: identity.Email,
			Name:  identity.Name,
			Sub:   identity.Sub,
		})
		if err != nil {
			return nil, err
		}
		if err := s.kv.Set(ctx, googleRegKey(token), payload, googleRegTTL); err != nil {
			return nil, err
		}
		return &GoogleAuthOutcome{NeedsRole: true, RegistrationToken: token}, nil
	default:
		return nil, err
	}
}

// googleLoginExisting issues tokens for an already-known account (suspended check
// included), wrapped in the no-role-needed outcome.
func (s *Service) googleLoginExisting(ctx context.Context, user *User) (*GoogleAuthOutcome, error) {
	if user.Status == StatusSuspended {
		return nil, ErrAccountSuspended
	}
	result, err := s.issueTokens(ctx, user)
	if err != nil {
		return nil, err
	}
	return &GoogleAuthOutcome{Result: result}, nil
}

// CompleteGoogleRegistration creates the account for a first-time Google user
// once they've picked a role, then issues tokens. The pending entry is consumed
// (single use). If the email was created meanwhile (race / double submit) the
// existing user is logged in instead of erroring.
func (s *Service) CompleteGoogleRegistration(ctx context.Context, regToken, role string) (*AuthResult, error) {
	key := googleRegKey(regToken)
	raw, err := s.kv.Get(ctx, key)
	if errors.Is(err, errKVNotFound) {
		return nil, ErrInvalidRegistrationToken
	}
	if err != nil {
		return nil, err
	}
	var pending pendingGoogleRegistration
	if err := json.Unmarshal(raw, &pending); err != nil {
		return nil, err
	}

	if existing, err := s.repo.FindByEmail(ctx, pending.Email); err == nil {
		_ = s.kv.Del(ctx, key)
		if existing.Status == StatusSuspended {
			return nil, ErrAccountSuspended
		}
		if existing.GoogleSub == nil && pending.Sub != "" {
			if err := s.repo.LinkGoogleSub(ctx, existing.ID, pending.Sub); err != nil {
				return nil, err
			}
		}
		return s.issueTokens(ctx, existing)
	} else if !errors.Is(err, ErrUserNotFound) {
		return nil, err
	}

	hash, err := randomPasswordHash()
	if err != nil {
		return nil, err
	}
	emailVal := pending.Email
	user := &User{
		Role:         role,
		Name:         pending.Name,
		Email:        &emailVal,
		PasswordHash: hash,
		AuthProvider: ProviderGoogle,
		Status:       StatusActive,
	}
	if pending.Sub != "" {
		subVal := pending.Sub
		user.GoogleSub = &subVal
	}
	if err := s.repo.Create(ctx, user); err != nil {
		return nil, err
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

func registerKey(email string) string  { return "auth:register:" + email }
func googleRegKey(token string) string { return "auth:google:" + token }
func sessionKey(userID uint64) string  { return "auth:session:" + strconv.FormatUint(userID, 10) }

// generateRegistrationToken returns a 256-bit URL-safe random token used to
// reference a pending Google registration in the KV store.
func generateRegistrationToken() (string, error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return hex.EncodeToString(buf), nil
}

// randomPasswordHash bcrypts 32 random bytes, producing a hash no password will
// ever match. Google-only accounts need a non-empty password_hash (NOT NULL) but
// must not be reachable via the email/password Login path.
func randomPasswordHash() (string, error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	h, err := bcrypt.GenerateFromPassword(buf, bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(h), nil
}

func generateOTP() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}
