package auth

import (
	"context"

	"google.golang.org/api/idtoken"
)

// googleIdentity is the slice of a verified Google ID token the service needs to
// find-or-create a user. Sub is Google's stable account id (kept for future
// linking columns); EmailVerified gates account creation — we only trust a
// Google email Google itself says it verified.
type googleIdentity struct {
	Email         string
	Name          string
	Sub           string
	EmailVerified bool
}

// googleVerifier validates a client-supplied Google ID token and extracts the
// identity. Defined as an interface so the service can be tested with a fake.
type googleVerifier interface {
	Verify(ctx context.Context, idToken string) (*googleIdentity, error)
}

// googleTokenVerifier verifies against Google's public certs via the idtoken
// package, which checks signature, expiry, issuer, and — critically — that the
// token's audience equals clientID (our Web/server OAuth client).
type googleTokenVerifier struct {
	clientID string
}

func newGoogleVerifier(clientID string) *googleTokenVerifier {
	return &googleTokenVerifier{clientID: clientID}
}

func (v *googleTokenVerifier) Verify(ctx context.Context, idToken string) (*googleIdentity, error) {
	payload, err := idtoken.Validate(ctx, idToken, v.clientID)
	if err != nil {
		return nil, ErrGoogleTokenInvalid
	}
	id := &googleIdentity{Sub: payload.Subject}
	if s, ok := payload.Claims["email"].(string); ok {
		id.Email = s
	}
	if s, ok := payload.Claims["name"].(string); ok {
		id.Name = s
	}
	if b, ok := payload.Claims["email_verified"].(bool); ok {
		id.EmailVerified = b
	}
	if id.Email == "" {
		return nil, ErrGoogleTokenInvalid
	}
	return id, nil
}
