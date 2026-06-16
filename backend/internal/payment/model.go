package payment

import "time"

// Transaction types (transactions.type enum). EscrowLock/EscrowRelease move
// funds in and out of escrow over a booking's lifecycle; Refund returns locked
// funds on any cancel path.
const (
	TxTopup         = "topup"
	TxEscrowLock    = "escrow_lock"
	TxEscrowRelease = "escrow_release"
	TxRefund        = "refund"
	TxWithdrawal    = "withdrawal"
)

// Wallet maps the `wallets` table — one per user (UNIQUE(user_id)). Balance is
// whole VND (DECIMAL(14,0)); signed so escrow arithmetic can be reasoned about
// without unsigned underflow.
type Wallet struct {
	ID        uint64    `gorm:"primaryKey"`
	UserID    uint64    `gorm:"column:user_id;uniqueIndex"`
	Balance   int64     `gorm:"column:balance;not null;default:0"`
	UpdatedAt time.Time `gorm:"column:updated_at"`
}

func (Wallet) TableName() string { return "wallets" }

// Transaction maps the `transactions` table — an immutable ledger entry.
// RefBookingID links escrow/refund movements to their booking; Gateway/
// GatewayRef carry the external provider reference for topups and withdrawals.
type Transaction struct {
	ID           uint64    `gorm:"primaryKey"`
	UserID       uint64    `gorm:"column:user_id;not null"`
	Type         string    `gorm:"column:type;not null"`
	Amount       int64     `gorm:"column:amount;not null"`
	RefBookingID *uint64   `gorm:"column:ref_booking_id"`
	Gateway      *string   `gorm:"column:gateway"`
	GatewayRef   *string   `gorm:"column:gateway_ref"`
	CreatedAt    time.Time `gorm:"column:created_at"`
}

func (Transaction) TableName() string { return "transactions" }
