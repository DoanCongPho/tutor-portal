package jwt

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strconv"
	"time"

	jwtv5 "github.com/golang-jwt/jwt/v5"
)

const (
	TypeAccess  = "access"
	TypeRefresh = "refresh"
)

var ErrInvalidToken = errors.New("jwt: invalid token")

type Claims struct {
	Role string `json:"role"`
	Type string `json:"typ"`
	jwtv5.RegisteredClaims
}

func (c *Claims) UserID() (uint64, error) {
	return strconv.ParseUint(c.Subject, 10, 64)
}

type Signer struct {
	secret     []byte
	AccessTTL  time.Duration
	RefreshTTL time.Duration
}

func NewSigner(secret string, accessTTL, refreshTTL time.Duration) *Signer {
	return &Signer{secret: []byte(secret), AccessTTL: accessTTL, RefreshTTL: refreshTTL}
}

type TokenPair struct {
	Access     string
	Refresh    string
	RefreshJTI string
}

func (s *Signer) Sign(userID uint64, role string) (TokenPair, error) {
	now := time.Now()
	accessJTI, err := randomJTI()
	if err != nil {
		return TokenPair{}, err
	}
	refreshJTI, err := randomJTI()
	if err != nil {
		return TokenPair{}, err
	}
	access, err := s.signOne(userID, role, TypeAccess, accessJTI, now, now.Add(s.AccessTTL))
	if err != nil {
		return TokenPair{}, err
	}
	refresh, err := s.signOne(userID, role, TypeRefresh, refreshJTI, now, now.Add(s.RefreshTTL))
	if err != nil {
		return TokenPair{}, err
	}
	return TokenPair{Access: access, Refresh: refresh, RefreshJTI: refreshJTI}, nil
}

func (s *Signer) signOne(userID uint64, role, typ, jti string, iat, exp time.Time) (string, error) {
	claims := Claims{
		Role: role,
		Type: typ,
		RegisteredClaims: jwtv5.RegisteredClaims{
			Subject:   strconv.FormatUint(userID, 10),
			ID:        jti,
			IssuedAt:  jwtv5.NewNumericDate(iat),
			ExpiresAt: jwtv5.NewNumericDate(exp),
		},
	}
	return jwtv5.NewWithClaims(jwtv5.SigningMethodHS256, claims).SignedString(s.secret)
}

func (s *Signer) Verify(token string) (*Claims, error) {
	parsed, err := jwtv5.ParseWithClaims(token, &Claims{}, func(t *jwtv5.Token) (any, error) {
		if _, ok := t.Method.(*jwtv5.SigningMethodHMAC); !ok {
			return nil, ErrInvalidToken
		}
		return s.secret, nil
	})
	if err != nil || !parsed.Valid {
		return nil, ErrInvalidToken
	}
	claims, ok := parsed.Claims.(*Claims)
	if !ok {
		return nil, ErrInvalidToken
	}
	return claims, nil
}

func randomJTI() (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
