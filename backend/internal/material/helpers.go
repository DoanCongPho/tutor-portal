package material

// IsValidType reports whether t is one of the materials.type enum values. The
// HTTP binding already constrains this with `oneof`; the service re-checks so
// the rule holds for any non-HTTP caller (tests, future internal callers).
func IsValidType(t string) bool {
	switch t {
	case TypeSlide, TypeNote, TypeAssignment:
		return true
	default:
		return false
	}
}
