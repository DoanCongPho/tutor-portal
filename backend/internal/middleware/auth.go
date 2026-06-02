package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	pkgjwt "github.com/DoanCongPho/tutor-portal/backend/pkg/jwt"
)

// Context keys set by RequireAuth and read by feature handlers via the
// exported accessors below. Kept unexported so the string literals live in one
// place — handlers must go through UserID/Role.
const (
	ctxUserID = "user_id" // uint64
	ctxRole   = "role"    // string
)

// RequireAuth authenticates the request from a Bearer access token. On success
// it stashes the user id and role in the gin context and calls the next
// handler; on any failure it aborts with 401. Refresh tokens are rejected — only
// access tokens grant API access.
func RequireAuth(signer *pkgjwt.Signer) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		const prefix = "Bearer "
		if !strings.HasPrefix(header, prefix) {
			abortUnauthorized(c, "missing or invalid authorization header")
			return
		}
		token := strings.TrimSpace(strings.TrimPrefix(header, prefix))
		if token == "" {
			abortUnauthorized(c, "missing or invalid authorization header")
			return
		}
		claims, err := signer.Verify(token)
		if err != nil {
			abortUnauthorized(c, "invalid token")
			return
		}
		if claims.Type != pkgjwt.TypeAccess {
			abortUnauthorized(c, "invalid token")
			return
		}
		uid, err := claims.UserID()
		if err != nil {
			abortUnauthorized(c, "invalid token")
			return
		}
		c.Set(ctxUserID, uid)
		c.Set(ctxRole, claims.Role)
		c.Next()
	}
}

// RequireRole asserts the authenticated user has the given role. Must run after
// RequireAuth in the handler chain. Aborts with 403 on mismatch.
func RequireRole(role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		r, ok := Role(c)
		if !ok || r != role {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "forbidden"})
			return
		}
		c.Next()
	}
}

// UserID returns the authenticated user id set by RequireAuth, or (0,false) if
// the request was not authenticated.
func UserID(c *gin.Context) (uint64, bool) {
	v, ok := c.Get(ctxUserID)
	if !ok {
		return 0, false
	}
	id, ok := v.(uint64)
	return id, ok
}

// Role returns the authenticated user's role set by RequireAuth.
func Role(c *gin.Context) (string, bool) {
	v, ok := c.Get(ctxRole)
	if !ok {
		return "", false
	}
	r, ok := v.(string)
	return r, ok
}

func abortUnauthorized(c *gin.Context, msg string) {
	c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": msg})
}
