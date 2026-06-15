package tutor

import "time"

// Hourly rate bounds in VND. tutor_profiles.hourly_rate is DECIMAL(10,0) — a
// whole-VND amount — so the rate is modeled as a uint64 and must be positive and
// within a sane ceiling. (The mockup slider runs 100k–1,000k; the service bound
// is wider to allow university/specialist rates without being unbounded.)
const (
	minHourlyRate uint64 = 1
	maxHourlyRate uint64 = 5_000_000
)

// subjectList is the controlled vocabulary of teaching subjects (PRD §11:
// "Subject and level use a controlled vocabulary defined in the codebase — not
// free text"). Ordered for stable presentation; validSubjects is the O(1)
// membership set derived from it. Vietnamese curriculum, utf8mb4.
var subjectList = []string{
	"Toán",              // Math
	"Ngữ văn",           // Literature
	"Tiếng Anh",         // English
	"Vật lý",            // Physics
	"Hóa học",           // Chemistry
	"Sinh học",          // Biology
	"Lịch sử",           // History
	"Địa lý",            // Geography
	"Giáo dục công dân", // Civics
	"Tin học",           // Informatics
	"Tiếng Pháp",        // French
	"Tiếng Nhật",        // Japanese
	"Tiếng Trung",       // Chinese
	"Tiếng Hàn",         // Korean
}

var validSubjects = func() map[string]struct{} {
	m := make(map[string]struct{}, len(subjectList))
	for _, s := range subjectList {
		m[s] = struct{}{}
	}
	return m
}()

var validLevels = map[string]struct{}{
	LevelPrimary:      {},
	LevelMiddleSchool: {},
	LevelHighSchool:   {},
	LevelUniversity:   {},
}

var validDocTypes = map[string]struct{}{
	DocDegree:      {},
	DocCertificate: {},
	DocNationalID:  {},
}

// Subjects returns the controlled subject vocabulary (ordered copy) for clients
// that want to populate a picker.
func Subjects() []string {
	out := make([]string, len(subjectList))
	copy(out, subjectList)
	return out
}

func IsValidSubject(s string) bool { _, ok := validSubjects[s]; return ok }
func IsValidLevel(l string) bool   { _, ok := validLevels[l]; return ok }
func IsValidDocType(t string) bool { _, ok := validDocTypes[t]; return ok }

// validTimeRange reports whether start/end are well-formed clock times with
// start strictly before end. Accepts both "HH:MM" and "HH:MM:SS".
func validTimeRange(start, end string) bool {
	s, ok := parseClock(start)
	if !ok {
		return false
	}
	e, ok := parseClock(end)
	if !ok {
		return false
	}
	return s < e
}

// parseClock parses a clock time as minutes-since-midnight, accepting "HH:MM"
// and "HH:MM:SS".
func parseClock(v string) (int, bool) {
	for _, layout := range []string{"15:04:05", "15:04"} {
		if t, err := time.Parse(layout, v); err == nil {
			return t.Hour()*60 + t.Minute(), true
		}
	}
	return 0, false
}

// normalizeClock canonicalizes a valid clock string to the MySQL TIME form
// "HH:MM:SS" so stored values are consistent regardless of input precision.
func normalizeClock(v string) string {
	for _, layout := range []string{"15:04:05", "15:04"} {
		if t, err := time.Parse(layout, v); err == nil {
			return t.Format("15:04:05")
		}
	}
	return v
}
