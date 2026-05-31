// Package email provides a minimal email-sending abstraction. The only v1
// concern is delivering short-lived OTP codes to a user's email address during
// registration. A real provider (Gmail SMTP, SES, ...) implements Sender;
// LogSender is the dev stub that writes the message to the application log
// instead of dialing out, so the flow works end to end without credentials.
package email

import (
	"context"
	"fmt"
	"log"
	"net/smtp"
	"strings"
)

// Sender delivers a single email. Implementations must be safe for concurrent
// use. Body is plain text (no HTML in v1 — an OTP code is all we send).
type Sender interface {
	Send(ctx context.Context, to, subject, body string) error
}

// SMTPSender sends mail over SMTP with STARTTLS + PLAIN auth — the shape Gmail
// expects on smtp.gmail.com:587. For Gmail, Username is the full address and
// Password is a 16-character App Password (not the account password; requires
// 2FA enabled on the Google account). From defaults to Username when empty.
type SMTPSender struct {
	Host     string // e.g. "smtp.gmail.com"
	Port     string // e.g. "587"
	Username string // e.g. "tutorportal@gmail.com"
	Password string // Gmail App Password
	From     string // sender address; defaults to Username
}

// Send dials the SMTP server and delivers the message. net/smtp's SendMail
// performs the STARTTLS upgrade and PLAIN auth handshake that Gmail requires on
// port 587. The context is accepted for interface symmetry; net/smtp predates
// context support and does not honor cancellation mid-send.
func (s SMTPSender) Send(_ context.Context, to, subject, body string) error {
	from := s.From
	if from == "" {
		from = s.Username
	}
	addr := s.Host + ":" + s.Port
	auth := smtp.PlainAuth("", s.Username, s.Password, s.Host)

	// RFC 5322 message: headers, blank line, body. CRLF line endings.
	msg := strings.Join([]string{
		"From: " + from,
		"To: " + to,
		"Subject: " + subject,
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=\"utf-8\"",
		"",
		body,
	}, "\r\n")

	if err := smtp.SendMail(addr, auth, from, []string{to}, []byte(msg)); err != nil {
		return fmt.Errorf("email: send to %s: %w", to, err)
	}
	return nil
}

// LogSender is a no-network Sender that logs the message. Use in dev/test when
// no SMTP provider is configured. Never use in production — codes land in plain
// logs.
type LogSender struct{}

func (LogSender) Send(_ context.Context, to, subject, body string) error {
	log.Printf("[email] to=%s subject=%q body=%q", to, subject, body)
	return nil
}
