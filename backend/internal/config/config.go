package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds every environment-driven setting for the API.
// See .env.example for the full list and docs/sad.md §10.
type Config struct {
	AppEnv  string
	AppPort string

	DBHost     string
	DBPort     string
	DBName     string
	DBUser     string
	DBPassword string

	RedisHost string
	RedisPort string

	JWTSecret     string
	JWTAccessTTL  time.Duration
	JWTRefreshTTL time.Duration

	// GoogleOAuthClientID is the audience Google ID tokens are verified against
	// (the Firebase project's Web/server OAuth client — client_type 3 in
	// google-services.json). The Flutter client must request its ID token with
	// this same id as serverClientId, or verification fails on audience.
	GoogleOAuthClientID string

	SMTPHost     string
	SMTPPort     string
	SMTPUsername string
	SMTPPassword string
	SMTPFrom     string

	AWSAccessKeyID     string
	AWSSecretAccessKey string
	AWSRegion          string
	AWSBucket          string

	FCMServerKey string

	VNPayTMNCode    string
	VNPayHashSecret string
	VNPayURL        string

	MoMoPartnerCode string
	MoMoAccessKey   string
	MoMoSecretKey   string
	MoMoURL         string

	ZaloPayAppID string
	ZaloPayKey1  string
	ZaloPayKey2  string
	ZaloPayURL   string

	PlatformCommissionRate  float64
	EscrowReleaseDelayHours int
	BookingTimeoutHours     int
	MaxConcurrentRequests   int
}

func Load() Config {
	return Config{
		AppEnv:  getenv("APP_ENV", "development"),
		AppPort: getenv("APP_PORT", "8080"),

		DBHost:     getenv("DB_HOST", "localhost"),
		DBPort:     getenv("DB_PORT", "3306"),
		DBName:     getenv("DB_NAME", "tutor_platform"),
		DBUser:     getenv("DB_USER", ""),
		DBPassword: getenv("DB_PASSWORD", ""),

		RedisHost: getenv("REDIS_HOST", "localhost"),
		RedisPort: getenv("REDIS_PORT", "6379"),

		JWTSecret:     getenv("JWT_SECRET", ""),
		JWTAccessTTL:  getduration("JWT_ACCESS_TTL", 15*time.Minute),
		JWTRefreshTTL: getduration("JWT_REFRESH_TTL", 7*24*time.Hour),

		// Default is the Web client id from frontend/android/app/google-services.json
		// (client_type 3). Override via env when the Firebase project changes.
		GoogleOAuthClientID: getenv("GOOGLE_OAUTH_CLIENT_ID",
			"860812429904-72345i6uiej86722vk1gn9apn32glpg3.apps.googleusercontent.com"),

		SMTPHost:     getenv("SMTP_HOST", ""),
		SMTPPort:     getenv("SMTP_PORT", "587"),
		SMTPUsername: getenv("SMTP_USERNAME", ""),
		SMTPPassword: getenv("SMTP_PASSWORD", ""),
		SMTPFrom:     getenv("SMTP_FROM", ""),

		AWSAccessKeyID:     getenv("AWS_ACCESS_KEY_ID", ""),
		AWSSecretAccessKey: getenv("AWS_SECRET_ACCESS_KEY", ""),
		AWSRegion:          getenv("AWS_REGION", "ap-southeast-1"),
		AWSBucket:          getenv("AWS_BUCKET", ""),

		FCMServerKey: getenv("FCM_SERVER_KEY", ""),

		VNPayTMNCode:    getenv("VNPAY_TMN_CODE", ""),
		VNPayHashSecret: getenv("VNPAY_HASH_SECRET", ""),
		VNPayURL:        getenv("VNPAY_URL", ""),

		MoMoPartnerCode: getenv("MOMO_PARTNER_CODE", ""),
		MoMoAccessKey:   getenv("MOMO_ACCESS_KEY", ""),
		MoMoSecretKey:   getenv("MOMO_SECRET_KEY", ""),
		MoMoURL:         getenv("MOMO_URL", ""),

		ZaloPayAppID: getenv("ZALOPAY_APP_ID", ""),
		ZaloPayKey1:  getenv("ZALOPAY_KEY1", ""),
		ZaloPayKey2:  getenv("ZALOPAY_KEY2", ""),
		ZaloPayURL:   getenv("ZALOPAY_URL", ""),

		PlatformCommissionRate:  getfloat("PLATFORM_COMMISSION_RATE", 0.12),
		EscrowReleaseDelayHours: getint("ESCROW_RELEASE_DELAY_HOURS", 24),
		BookingTimeoutHours:     getint("BOOKING_TIMEOUT_HOURS", 24),
		MaxConcurrentRequests:   getint("MAX_CONCURRENT_REQUESTS", 3),
	}
}

func getenv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return fallback
}

func getint(key string, fallback int) int {
	if v, ok := os.LookupEnv(key); ok {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}

func getfloat(key string, fallback float64) float64 {
	if v, ok := os.LookupEnv(key); ok {
		if n, err := strconv.ParseFloat(v, 64); err == nil {
			return n
		}
	}
	return fallback
}

func getduration(key string, fallback time.Duration) time.Duration {
	if v, ok := os.LookupEnv(key); ok {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return fallback
}
